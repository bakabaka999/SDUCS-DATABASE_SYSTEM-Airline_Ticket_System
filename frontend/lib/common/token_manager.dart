import 'package:shared_preferences/shared_preferences.dart';

class TokenManager {
  static String? _token; // 缓存 Token

  // 预加载 Token
  static Future<void> loadToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
  }

  // 获取 Token，如果未加载则抛出异常
  static String getToken() {
    if (_token == null || _token!.isEmpty) {
      throw Exception("用户未登录，请重新登录");
    }
    return _token!;
  }

  // 更新 Token
  static Future<void> updateToken(String newToken) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', newToken);
    _token = newToken;
  }

  // 清除 Token
  static Future<void> clearToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    _token = null;
  }
}
