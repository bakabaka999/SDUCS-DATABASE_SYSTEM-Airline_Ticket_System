import 'package:flutter/material.dart';
import 'user_info.dart';

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
          ],
        ),
      ),
    );
  }
}
