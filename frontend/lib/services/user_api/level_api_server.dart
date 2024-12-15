import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class LevelAPI {
  final String apiUrl = "http://localhost:8000/user/level/";
  // final String apiUrl = "http://159.75.132.182:8000/level/";

  // 获取用户等级
  Future<Map<String, dynamic>> getUserLevel() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');

      if (token == null) {
        throw Exception("Token not found. Please login again.");
      }

      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
            "Failed to fetch user level. Status code: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Error fetching user level: $e");
    }
  }

  // 获取下一个等级建议
  Future<Map<String, dynamic>> getNextLevel() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');

      if (token == null) {
        throw Exception("Token not found. Please login again.");
      }

      final response = await http.get(
        Uri.parse(apiUrl + "next_level/"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
            "Failed to fetch next level. Status code: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Error fetching next level: $e");
    }
  }

  // 获取用户等级相关的促销活动
  Future<List<dynamic>> getUserPromotions() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');

      if (token == null) {
        throw Exception("Token not found. Please login again.");
      }

      final response = await http.get(
        Uri.parse(apiUrl + "promotions/"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body)['promotions'];
      } else {
        throw Exception(
            "Failed to fetch promotions. Status code: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Error fetching promotions: $e");
    }
  }
}
