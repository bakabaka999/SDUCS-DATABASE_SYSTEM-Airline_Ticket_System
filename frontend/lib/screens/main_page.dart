// main_page.dart
import 'package:flutter/material.dart';
import 'user_info.dart'; // 继续引用用户信息页面
import 'passenger_management.dart'; // 引入乘机人管理页面

class MainPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Main Page'),
        backgroundColor: Colors.teal,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.home, color: Colors.teal, size: 100),
            SizedBox(height: 20),
            Text(
              'Welcome to the Main Page!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // 跳转到用户信息页面
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => UserInfoPage()),
                );
              },
              child: Text('Go to User Info'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // 跳转到乘机人管理页面
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => PassengerInfoPage()),
                );
              },
              child: Text('Manage Passengers'),
            ),
          ],
        ),
      ),
    );
  }
}
