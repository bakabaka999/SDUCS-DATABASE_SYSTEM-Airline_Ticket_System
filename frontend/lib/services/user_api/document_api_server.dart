import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/document.dart';

class DocumentApi {
  // final String apiUrl = "http://localhost:8000/user/";
  final String apiUrl = "http://159.75.132.182:8000/user/";

  /// 获取 Token
  Future<String?> _getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // 证件接口

  /// 获取某一乘机人的证件信息
  Future<List<Document>> getDocumentsByPassenger(int passengerId) async {
    String? token = await _getToken();
    if (token == null) {
      throw Exception("Unauthorized: Token not found");
    }

    try {
      final response = await http.get(
        Uri.parse(apiUrl + 'document/search/$passengerId/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
      );
      if (response.statusCode == 200) {
        List<dynamic> documentsJson = json.decode(response.body);
        return documentsJson.map((json) => Document.fromJson(json)).toList();
      } else {
        throw Exception('Failed to fetch passenger documents');
      }
    } catch (e) {
      print(e);
      throw Exception('Error fetching passenger documents: $e');
    }
  }

  /// 添加证件信息
  Future<Document> addDocument(Map<String, dynamic> data) async {
    String? token = await _getToken();
    if (token == null) {
      throw Exception("Unauthorized: Token not found");
    }

    try {
      final response = await http.post(
        Uri.parse(apiUrl + 'document/'),
        body: json.encode(data),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
      );

      if (response.statusCode == 201) {
        print("test_point");
        return Document.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to add document');
      }
    } catch (e) {
      throw Exception('Error adding document: $e');
    }
  }

  /// 更新证件信息
  Future<Document> updateDocument(
      int documentId, Map<String, dynamic> data) async {
    String? token = await _getToken();
    if (token == null) {
      throw Exception("Unauthorized: Token not found");
    }

    try {
      final response = await http.put(
        Uri.parse(apiUrl + 'document/$documentId/'),
        body: json.encode(data),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
      );

      if (response.statusCode == 200) {
        return Document.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to update document');
      }
    } catch (e) {
      throw Exception('Error updating document: $e');
    }
  }

  /// 删除证件信息
  Future<void> deleteDocument(int documentId) async {
    String? token = await _getToken();
    if (token == null) {
      throw Exception("Unauthorized: Token not found");
    }

    try {
      final response = await http.delete(
        Uri.parse(apiUrl + 'document/$documentId/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
      );

      if (response.statusCode != 204) {
        throw Exception('Failed to delete document');
      }
    } catch (e) {
      throw Exception('Error deleting document: $e');
    }
  }
}
