import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/user.dart';
import '../../models/passenger.dart';
import '../../models/involve.dart';

class UserAPI {
  // 后端API的基准url
  // final String apiUrl = "http://localhost:8000/user/account/";
  final String apiUrl = "http://159.75.132.182:8000/user/account/";

  // 用户登录接口
  /// 用户登录。传递用户名和密码，返回登录信息
  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse((apiUrl + 'login/')), // 登录用URL
        body: json.encode({
          'username': username,
          'password': password,
        }),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        // 解析返回的 JSON 数据
        var data = json.decode(response.body);

        // 检查响应中是否包含 token
        if (data.containsKey('token')) {
          // 保存 token 到 SharedPreferences
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('auth_token', data['token']); // 存储 token

          return {'message': 'Login successful', 'token': data['token']};
        } else {
          throw Exception('Token not found in response');
        }
      } else {
        throw Exception('Invalid credentials');
      }
    } catch (e) {
      throw Exception('Error logging in: $e');
    }
  }

  // 用户注册接口
  /// 用户注册，传递用户名、邮箱和密码，返回注册结果
  Future<Map<String, dynamic>> register(
      String username, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse(apiUrl + 'register/'),
        body: json.encode({
          'username': username,
          'email': email,
          'password': password,
        }),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        throw Exception('Username already exists');
      }
    } catch (e) {
      throw Exception('Error registering user: $e');
    }
  }

  // 验证Token是否有效
  Future<bool> validateToken(String token) async {
    try {
      final response = await http.get(
        Uri.parse(apiUrl + 'token/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error validating token: $e');
    }
  }

  // 获取用户信息接口
  /// 获取当前登录用户的信息
  Future<User> getUserProfile(String token) async {
    try {
      final response = await http.get(
        Uri.parse(apiUrl + 'profile/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
      );
      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        print(decodedBody.toString());
        return User.fromJson(json.decode(decodedBody)); // 解析用户数据
      } else {
        throw Exception('Failed to load user profile: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching user profile: $e');
    }
  }

  // 上传用户头像接口
  /// 修改当前登录用户的头像
  Future<String> uploadAvatar(String token, XFile imageFile) async {
    try {
      // 读取文件的字节流
      List<int> imageBytes = await imageFile.readAsBytes();

      var request = http.MultipartRequest(
        'POST',
        Uri.parse(apiUrl + 'profile/avatar/'),
      );
      request.headers['Authorization'] = 'Token $token';
      request.files.add(
        http.MultipartFile.fromBytes(
          'avatar',
          imageBytes,
          filename: imageFile.name, // 指定文件名
          contentType: MediaType('image', 'jpeg'), // 设置文件类型
        ),
      );

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final decodedBody = json.decode(response.body);
        return decodedBody['avatar_url']; // 返回新的头像 URL
      } else {
        throw Exception('Failed to upload avatar: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error uploading avatar: $e');
    }
  }

  // 更新用户信息接口
  /// 更新用户的邮箱和手机号
  Future<User> updateUserProfile(
      String token, String name, String email, String phone) async {
    try {
      // 构造请求体数据
      Map<String, dynamic> data = {
        'name': name,
        'email': email,
        'phone_number': phone,
      };

      // 发送PUT请求更新用户信息
      final response = await http.put(
        Uri.parse(apiUrl + 'profile/'),
        body: json.encode(data),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
      );

      if (response.statusCode == 200) {
        // 成功时返回更新后的用户信息
        final decodedBody = utf8.decode(response.bodyBytes);
        return User.fromJson(json.decode(decodedBody));
      } else {
        throw Exception(
            'Failed to update user profile. Status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating user profile: $e');
    }
  }

  // 乘机人信息管理接口
  /// 获取所有乘机人信息
  Future<List<Passenger>> getPassengers(String token) async {
    try {
      final response = await http.get(
        Uri.parse(apiUrl + 'passenger/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
      );

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        List<dynamic> passengersJson = json.decode(decodedBody);
        return passengersJson.map((json) => Passenger.fromJson(json)).toList();
      } else {
        throw Exception('Failed to fetch passengers');
      }
    } catch (e) {
      throw Exception('Error fetching passengers: $e');
    }
  }

  // 添加乘机人信息接口
  /// 添加新的乘机人信息
  Future<Map<String, dynamic>> addPassenger(
      String token, Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse(apiUrl + 'passenger/'),
        body: json.encode(data),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
      );

      if (response.statusCode == 201) {
        final decodedBody = utf8.decode(response.bodyBytes);
        return json.decode(decodedBody);
      } else {
        throw Exception('Error adding passenger');
      }
    } catch (e) {
      throw Exception('Error adding passenger: $e');
    }
  }

  // 删除乘机人信息接口
  /// 删除指定ID的乘机人信息
  Future<Map<String, dynamic>> deletePassenger(
      String token, int passengerId) async {
    try {
      final response = await http.delete(
        Uri.parse(apiUrl + 'passenger/$passengerId/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        return json.decode(decodedBody);
      } else {
        throw Exception('Passenger not found');
      }
    } catch (e) {
      throw Exception('Error deleting passenger: $e');
    }
  }

  // 更新乘机人信息接口
  /// 更新指定ID的乘机人信息
  Future<Map<String, dynamic>> updatePassenger(
      String token, int passengerId, Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse(apiUrl + 'passenger/$passengerId/'),
        body: json.encode(data),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
      );

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        return json.decode(decodedBody);
      } else {
        throw Exception('Passenger not found or invalid data');
      }
    } catch (e) {
      throw Exception('Error updating passenger: $e');
    }
  }

  // 发票管理接口
  /// 获取用户所有发票信息
  Future<List<Invoice>> getInvoices(String token) async {
    try {
      final response = await http.get(
        Uri.parse(apiUrl + 'invoice/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> invoicesJson = json.decode(response.body);
        return invoicesJson.map((json) => Invoice.fromJson(json)).toList();
      } else {
        throw Exception('Failed to fetch invoices');
      }
    } catch (e) {
      throw Exception('Error fetching invoices: $e');
    }
  }

  // 资质认证管理接口
  /// 提交用户认证信息
  Future<Map<String, dynamic>> submitCertification(
      String token, String certificationType) async {
    try {
      final response = await http.post(
        Uri.parse(apiUrl + 'qualification-certification/'),
        body: json.encode({
          'certification_type': certificationType,
        }),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        return json.decode(response.body);
      } else {
        throw Exception('Invalid certification type');
      }
    } catch (e) {
      throw Exception('Error submitting certification: $e');
    }
  }

  // 修改密码接口
  /// 用户修改密码
  Future<bool> changePassword(
      String token, String oldPassword, String newPassword) async {
    final response = await http.put(
      Uri.parse(apiUrl + 'change-password/'),
      body: json.encode({
        'old_password': oldPassword,
        'new_password': newPassword,
      }),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Token $token',
      },
    );

    if (response.statusCode == 200) {
      return true; // 修改成功
    } else {
      // 失败时输出错误信息
      print('Failed to change password: ${response.body}');
      return false;
    }
  }

  // 用户登出接口
  /// 用户退出登录
  Future<Map<String, dynamic>> logout(String token) async {
    try {
      final response = await http.post(
        Uri.parse(apiUrl + 'logout/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
      );

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        return json.decode(decodedBody);
      } else {
        throw Exception('Logout failed');
      }
    } catch (e) {
      throw Exception('Error logging out: $e');
    }
  }

  Future<void> updateUserAvatar(String token, File avatarFile) async {
    // 构造 URL
    final url = Uri.parse('$apiUrl/api/user/avatar/');

    // 创建 Multipart 请求
    final request = http.MultipartRequest('POST', url)
      ..headers['Authorization'] = 'Bearer $token' // 添加认证头
      ..files.add(
          await http.MultipartFile.fromPath('avatar', avatarFile.path)); // 添加文件

    // 发送请求
    final response = await request.send();

    // 处理响应
    if (response.statusCode != 200) {
      throw Exception('头像上传失败: ${response.statusCode}');
    }
  }
}

