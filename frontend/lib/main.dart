import 'package:flutter/material.dart';
import 'package:frontend/common/token_manager.dart';
import 'package:intl/date_symbol_data_local.dart'; // 导入日期本地化初始化
import 'screens/login&register/login.dart'; // 登录页面
import 'screens/main_page.dart'; // 主页面

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // 确保 Flutter 绑定已初始化
  await TokenManager.loadToken(); // 预加载 Token
  await initializeDateFormatting('zh_CN', null); // 初始化中文日期格式化
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '航空售票管理系统',
      theme: ThemeData(
        fontFamily: null, // 使用系统默认字体
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/login', // 默认进入登录页面
      routes: {
        '/login': (context) => LoginPage(), // 登录页面
        '/main': (context) => MainPage(), // 主页面
      },
    );
  }
}
