import 'package:flutter/material.dart';
import 'package:frontend/common/token_manager.dart';
import 'package:frontend/screens/order%20operation/order_management_page.dart';
import 'package:frontend/screens/user%20level/level_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'user action/user_info.dart';
import 'passenger action/passenger_management.dart';
import 'ticket purchase/ticket_purchase_page.dart';

class MainPage extends StatefulWidget {
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0; // 当前选中的索引

  final List<Widget> _pages = [
    UserInfoPage(),
    PassengerInfoPage(),
    FlightSearchPage(),
    OrderManagementPage(),
    LevelPage(),
  ];

  final List<String> _pageTitles = ["用户信息", "乘机人管理", "机票订购", "订单管理", "会员等级"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _pageTitles[_selectedIndex],
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold,color: Colors.white),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.teal.shade600, Colors.teal.shade300],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        centerTitle: true,
        elevation: 5,
      ),
      body: Row(
        children: [
          // 侧边栏
          Container(
            width: 90,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.grey.shade100, Colors.grey.shade200],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                SizedBox(height: 30),
                _buildLogo(),
                SizedBox(height: 20),
                _buildSidebarButton(0, Icons.person, "用户"),
                _buildSidebarButton(1, Icons.people, "乘客"),
                _buildSidebarButton(2, Icons.airplane_ticket, "购票"),
                _buildSidebarButton(3, Icons.receipt_long, "订单"),
                _buildSidebarButton(4, Icons.star, "等级"), // 新增等级入口
                Spacer(),
                _buildLogoutButton(),
                SizedBox(height: 20),
              ],
            ),
          ),
          // 使用 IndexedStack 与 AnimatedSwitcher 解决性能问题
          Expanded(
            child: AnimatedSwitcher(
              duration: Duration(milliseconds: 300),
              switchInCurve: Curves.easeInOut,
              child: _pages[_selectedIndex],
            ),
          ),
        ],
      ),
    );
  }

  // Logo Widget
  Widget _buildLogo() {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.teal.withOpacity(0.1),
          ),
          child: Icon(Icons.flight, size: 40, color: Colors.teal.shade700),
        ),
        SizedBox(height: 10),
        Text(
          "航班管理",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.teal.shade700,
          ),
        ),
      ],
    );
  }

  // 侧边栏按钮
  Widget _buildSidebarButton(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      child: AnimatedContainer(
        width:300,
        duration: Duration(milliseconds: 300),
        margin: EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        padding: EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.teal.shade300 : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.teal.shade200,
                    blurRadius: 5,
                    offset: Offset(0, 3),
                  ),
                ]
              : [],
        ),
        child: Column(
          children: [
            Icon(icon,
                size: 30,
                color: isSelected ? Colors.white : Colors.grey.shade600),
            SizedBox(height: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? Colors.white : Colors.grey.shade600,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 退出登录按钮
  Widget _buildLogoutButton() {
    return GestureDetector(
      onTap: () async {
        bool confirmLogout = await _showLogoutConfirmation();
        if (confirmLogout) {
          await TokenManager.clearToken(); // 清除Token，使用TokenManager
          Navigator.pushReplacementNamed(context, '/login'); // 返回登录页面
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [
            Icon(Icons.logout, color: Colors.redAccent, size: 28),
            SizedBox(height: 5),
            Text(
              "退出",
              style: TextStyle(
                fontSize: 12,
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 弹出确认对话框
  Future<bool> _showLogoutConfirmation() async {
    return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text("确认退出"),
            content: Text("您确定要退出登录吗？"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text("取消", style: TextStyle(color: Colors.grey)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text("退出", style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ) ??
        false;
  }
}
