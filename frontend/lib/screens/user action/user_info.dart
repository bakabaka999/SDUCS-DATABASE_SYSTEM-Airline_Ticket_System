import 'package:flutter/material.dart';
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
    String? token = TokenManager.getToken();
    print(token);
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
        _userProfile = Future.value(updatedUser); // 更新数据
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

  @override
  void initState() {
    super.initState();
    _userProfile = _getUserProfile();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal.shade50,
      // appBar: AppBar(
      //   title: Text('个人信息'),
      //   flexibleSpace: _buildGradientHeader(),
      //   centerTitle: true,
      // ),
      body: FutureBuilder<User>(
        future: _userProfile,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('加载失败: ${snapshot.error}'));
          } else {
            _initializeUser(snapshot.data!);
            return _buildUserInfoContent();
          }
        },
      ),
    );
  }

  // 渐变AppBar背景
  Widget _buildGradientHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.teal.shade600, Colors.teal.shade300],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }

  // 主体内容
  Widget _buildUserInfoContent() {
    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(height: 20),
          _buildUserAvatar(),
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

  // 用户头像区域
  Widget _buildUserAvatar() {
    return Stack(
      alignment: Alignment.center,
      children: [
        CircleAvatar(
          radius: 80,
          backgroundColor: Colors.teal.shade100,
          child: Icon(Icons.person, size: 80, color: Colors.white),
        ),
        Positioned(
          bottom: 10,
          right: 10,
          child: GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('暂不支持修改头像')),
              );
            },
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

  // 输入字段
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

  // 按钮区域
  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton.icon(
          onPressed: () {
            // 跳转到修改密码页面
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
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        ElevatedButton.icon(
          onPressed: () {
            if (_isEditing) {
              // 保存用户信息
              _saveUserProfile();
            } else {
              // 进入编辑模式
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
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

}
