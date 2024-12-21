import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:frontend/common/token_manager.dart';
import 'package:frontend/screens/user%20action/change_password.dart';
import 'package:frontend/services/user_api/account_api_server.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../models/user.dart';

class UserInfoPage extends StatefulWidget {
  @override
  _UserInfoPageState createState() => _UserInfoPageState();
}

class _UserInfoPageState extends State<UserInfoPage> {
  late Future<User> _userProfile;
  bool _isEditing = false;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  Future<User> _getUserProfile() async {
    String? token = await TokenManager.getToken();
    if (token == null) {
      throw Exception('未找到Token');
    }
    return UserAPI().getUserProfile(token);
  }

  void _initializeUser(User user) {
    _nameController.text = user.name ?? '';
    _emailController.text = user.email ?? '';
    _phoneController.text = user.phoneNumber ?? '';
  }

  Future<void> _saveUserProfile() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token');
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("未登录，请重新登录")),
      );
      return;
    }

    try {
      User updatedUser = await UserAPI().updateUserProfile(
        token,
        _nameController.text,
        _emailController.text,
        _phoneController.text,
      );

      setState(() {
        _userProfile = Future.value(updatedUser);
        _isEditing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("个人信息已更新")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("更新失败: $e")),
      );
    }
  }

  Future<void> _uploadAvatar() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      String? token = await TokenManager.getToken();

      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("未登录，请重新登录")),
        );
        return;
      }

      try {
        String newAvatarUrl = await UserAPI().uploadAvatar(token, pickedFile);
        setState(() {
          _userProfile = _getUserProfile(); // 重新加载用户信息
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("头像上传成功")),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("上传失败: $e")),
        );
      }
    }
  }



  @override
  void initState() {
    super.initState();
    _userProfile = _getUserProfile();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal.shade50,
      body: FutureBuilder<User>(
        future: _userProfile,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('加载失败: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            _initializeUser(snapshot.data!);
            return _buildUserInfoContent(snapshot.data!);
          } else {
            return Center(child: Text('未能加载用户信息'));
          }
        },
      ),
    );
  }

  Widget _buildUserInfoContent(User user) {
    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(height: 20),
          _buildUserAvatar(user), // 动态显示头像
          SizedBox(height: 30),
          _buildUserInfoField("用户名", _nameController),
          _buildUserInfoField("邮箱", _emailController),
          _buildUserInfoField("手机号", _phoneController),
          SizedBox(height: 30),
          _buildActionButtons(),
          SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildUserAvatar(User user) {
    return Stack(
      alignment: Alignment.center,
      children: [
        CircleAvatar(
          radius: 140,
          backgroundImage: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
              ? NetworkImage("http://159.75.132.182:8000${user.avatarUrl}") // 使用网络图片加载头像
              : null, // 如果没有头像 URL，则显示默认样式
          backgroundColor: Colors.teal.shade100,
          child: user.avatarUrl == null || user.avatarUrl!.isEmpty
              ? Icon(Icons.person, size: 80, color: Colors.white) // 默认图标
              : null,
        ),
        Positioned(
          bottom: 10,
          right: 10,
          child: GestureDetector(
            onTap: _uploadAvatar,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.teal,
              ),
              padding: EdgeInsets.all(8),
              child: Icon(Icons.edit, color: Colors.white, size: 20),
            ),
          ),
        ),
      ],
    );
  }


  Widget _buildUserInfoField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          leading: Icon(Icons.info_outline, color: Colors.teal),
          title: Text(label,
              style: TextStyle(fontSize: 16, color: Colors.black54)),
          subtitle: TextField(
            controller: controller,
            enabled: _isEditing,
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: "请输入$label",
            ),
            style: TextStyle(fontSize: 18, color: Colors.black),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ChangePasswordPage()),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orangeAccent,
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          ),
          icon: Icon(Icons.lock, color: Colors.white),
          label: Text(
            "修改密码",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,color: Colors.white),
          ),
        ),
        ElevatedButton.icon(
          onPressed: () {
            if (_isEditing) {
              _saveUserProfile();
            } else {
              setState(() {
                _isEditing = true;
              });
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: _isEditing ? Colors.green : Colors.blueAccent,
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          ),
          icon: Icon(
            _isEditing ? Icons.save : Icons.edit,
            color: Colors.white,
          ),
          label: Text(
            _isEditing ? "保存" : "编辑",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,color: Colors.white),
          ),
        ),
      ],
    );
  }
}