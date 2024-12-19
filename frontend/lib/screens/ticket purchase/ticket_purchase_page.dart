import 'package:flutter/material.dart';
import 'package:frontend/common/token_manager.dart';
import 'package:frontend/screens/ticket%20purchase/city_selection_page.dart';
import 'package:frontend/screens/ticket%20purchase/flight_results_page.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/user_api/flight_api_server.dart';

class FlightSearchPage extends StatefulWidget {
  @override
  _FlightSearchPageState createState() => _FlightSearchPageState();
}

class _FlightSearchPageState extends State<FlightSearchPage> {
  String _departureCityName = "北京";
  String _departureCityCode = "BJS";
  String _arrivalCityName = "上海";
  String _arrivalCityCode = "SHA";
  DateTime? _selectedDate = DateTime.now();
  String? _errorMessage;

  // 跳转到城市选择页面
  void _selectCity(bool isDeparture) async {
    final selectedCity = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CitySelectionPage()),
    );

    if (selectedCity != null) {
      setState(() {
        if (isDeparture) {
          _departureCityName = selectedCity['city_name'];
          _departureCityCode = selectedCity['city_code'];
        } else {
          _arrivalCityName = selectedCity['city_name'];
          _arrivalCityCode = selectedCity['city_code'];
        }
      });
    }
  }

  // 选择日期
  void _selectDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  // 交换城市
  void _swapCities() {
    setState(() {
      final tempCityName = _departureCityName;
      final tempCityCode = _departureCityCode;
      _departureCityName = _arrivalCityName;
      _departureCityCode = _arrivalCityCode;
      _arrivalCityName = tempCityName;
      _arrivalCityCode = tempCityCode;
    });
  }

  // 查询航班
  void _searchFlights() async {
    setState(() {
      _errorMessage = null;
    });

    try {
      String? token = TokenManager.getToken();

      if (token == null) {
        setState(() {
          _errorMessage = "用户未登录，请重新登录。";
        });
        return;
      }

      final flights = await FlightAPI().searchFlights(
        token,
        _departureCityCode,
        _arrivalCityCode,
        departureDate: DateFormat('yyyy-MM-dd').format(_selectedDate!),
      );

      if (flights.isEmpty) {
        setState(() {
          _errorMessage = "未找到符合条件的航班，请更换查询条件。";
        });
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FlightResultsPage(
              departureCode: _departureCityCode,
              arrivalCode: _arrivalCityCode,
              departureDate: DateFormat('yyyy-MM-dd').format(_selectedDate!),
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = "系统错误，请稍后重试。";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: Text(
      //     '航班查询',
      //     style: TextStyle(fontWeight: FontWeight.bold),
      //   ),
      //   centerTitle: true,
      //   flexibleSpace: Container(
      //     decoration: BoxDecoration(
      //       gradient: LinearGradient(
      //         colors: [Colors.teal.shade700, Colors.teal.shade300],
      //         begin: Alignment.topLeft,
      //         end: Alignment.bottomRight,
      //       ),
      //     ),
      //   ),
      //   elevation: 5,
      // ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.teal.shade50, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Card(
            elevation: 8,
            margin: EdgeInsets.all(20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHeader(),
                  SizedBox(height: 20),
                  _buildCitySelection(),
                  SizedBox(height: 20),
                  _buildDateSelection(),
                  SizedBox(height: 20),
                  if (_errorMessage != null) _buildErrorMessage(),
                  SizedBox(height: 20),
                  _buildSearchButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 标题
  Widget _buildHeader() {
    return Column(
      children: [
        Icon(Icons.flight_takeoff, size: 60, color: Colors.teal.shade600),
        SizedBox(height: 10),
        Text(
          "航班查询",
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Colors.teal.shade700,
          ),
        ),
        SizedBox(height: 5),
        Text(
          "请选择出发城市、到达城市和日期",
          style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
        ),
      ],
    );
  }

  // 城市选择
  Widget _buildCitySelection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildCityBox("出发城市", _departureCityName, () => _selectCity(true)),
        IconButton(
          onPressed: _swapCities,
          icon: Icon(Icons.swap_horiz, size: 36, color: Colors.blueAccent),
        ),
        _buildCityBox("到达城市", _arrivalCityName, () => _selectCity(false)),
      ],
    );
  }

  Widget _buildCityBox(String label, String city, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Text(label, style: TextStyle(color: Colors.grey, fontSize: 14)),
          SizedBox(height: 5),
          Text(
            city,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // 日期选择
  Widget _buildDateSelection() {
    return GestureDetector(
      onTap: _selectDate,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_today, color: Colors.teal),
          SizedBox(width: 10),
          Text(
            _selectedDate == null
                ? "请选择日期"
                : DateFormat('MM月dd日 EEEE', 'zh_CN').format(_selectedDate!),
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // 错误信息提示
  Widget _buildErrorMessage() {
    return Text(
      _errorMessage!,
      style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
    );
  }

  // 查询按钮
  Widget _buildSearchButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _searchFlights,
        icon: Icon(Icons.search, color: Colors.white),
        label: Text("查询航班", style: TextStyle(fontSize: 18)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.teal.shade600,
          padding: EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
