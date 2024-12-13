import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class LevelAPI {
  final String apiUrl = "http://localhost:8000/level/";

  // 获取用户等级
  Future<Map<String, dynamic>> getUserLevel() async {
    try {
      // 从本地存储中获取Token
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');

      if (token == null) {
        throw Exception("Token not found. Please login again.");
      }

      // 发起GET请求
      final response = await http.get(
        Uri.parse(apiUrl + "get_user_level/"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
      );

      if (response.statusCode == 200) {
        // 返回成功结果
        return json.decode(response.body);
      } else {
        // 返回错误信息
        throw Exception(
            "Failed to fetch user level. Status code: ${response.statusCode}");
      }
    } catch (e) {
      // 异常处理
      throw Exception("Error fetching user level: $e");
    }
  }
}
