import 'package:flutter/material.dart';
import 'package:frontend/common/token_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/user_api/flight_api_server.dart';

class CitySelectionPage extends StatefulWidget {
  @override
  _CitySelectionPageState createState() => _CitySelectionPageState();
}

class _CitySelectionPageState extends State<CitySelectionPage> {
  List<dynamic> _cities = [];
  TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchCities();

    // 监听搜索框输入变化
    _searchController.addListener(() {
      _fetchCities(query: _searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchCities({String? query}) async {
    setState(() {
      _isLoading = true;
    });
    try {
      String? token = TokenManager.getToken();

      if (token == null) {
        throw Exception('用户未登录，请重新登录');
      }

      // API 查询
      _cities = await FlightAPI().fetchCities(token, query: query);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('加载城市数据失败，请稍后重试')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '城市选择',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.teal.shade700, Colors.teal.shade300],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 5,
      ),
      body: Column(
        children: [
          // 搜索框
          _buildSearchBox(),

          SizedBox(height: 10),

          // 城市列表或加载中
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: Colors.teal))
                : _cities.isEmpty
                    ? _buildNoDataWidget()
                    : _buildCityList(),
          ),
        ],
      ),
    );
  }

  // 搜索框样式
  Widget _buildSearchBox() {
    return Container(
      margin: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: '请输入城市名称或代码',
          prefixIcon: Icon(Icons.search, color: Colors.teal.shade600),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        ),
      ),
    );
  }

  // 城市列表样式
  Widget _buildCityList() {
    return ListView.builder(
      itemCount: _cities.length,
      itemBuilder: (context, index) {
        final city = _cities[index];
        return Card(
          elevation: 3,
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: Icon(Icons.location_city, color: Colors.teal.shade700),
            title: Text(
              city['city_name'],
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.teal.shade800,
              ),
            ),
            subtitle: Text(
              "城市编号: ${city['city_code']}",
              style: TextStyle(color: Colors.grey.shade700),
            ),
            trailing:
                Icon(Icons.arrow_forward_ios, color: Colors.teal.shade400),
            onTap: () {
              // 返回选择的城市数据
              Navigator.pop(context, {
                'city_name': city['city_name'],
                'city_code': city['city_code'],
              });
            },
          ),
        );
      },
    );
  }

  // 无数据展示
  Widget _buildNoDataWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off, size: 80, color: Colors.grey.shade400),
          SizedBox(height: 20),
          Text(
            '没有找到符合条件的城市',
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}
