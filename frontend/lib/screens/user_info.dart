import 'package:flutter/material.dart';
import 'package:frontend/screens/change_password.dart';
import 'package:frontend/services/user_api/account_api.dart';
import 'login.dart'; // 登录页面
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/user.dart'; // 引入 User 模型

class UserInfoPage extends StatefulWidget {
  @override
  _UserInfoPageState createState() => _UserInfoPageState();
}

class _UserInfoPageState extends State<UserInfoPage> {
  late Future<User> _userProfile;
  late User _user;
  bool _isEditing = false; // 控制是否进入编辑模式
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  // 获取用户Token并请求用户信息
  Future<User> _getUserProfile() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token'); // 获取保存的Token
    if (token == null) {
      throw Exception('No token found');
    }
    return UserAPI().getUserProfile(token); // 使用token获取用户信息
  }

  // 初始化用户信息
  void _initializeUser(User user) {
    _user = user;
    _nameController.text = user.name ?? '';
    _emailController.text = user.email ?? '';
    _phoneController.text = user.phoneNumber ?? '';
  }

  @override
  void initState() {
    super.initState();
    _userProfile = _getUserProfile(); // 初始化时获取用户信息
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User Information'),
        backgroundColor: Colors.teal,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder<User>(
          future: _userProfile,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData) {
              return Center(child: Text('No data available'));
            } else {
              if (!_isEditing) {
                _initializeUser(snapshot.data!);
              }

              User user = snapshot.data!;
              return ListView(
                children: [
                  // 用户头像
                  Center(
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.teal,
                      child: Icon(
                        Icons.person,
                        size: 80,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(height: 20),

                  // 用户名
                  _buildUserInfoField("Username", _nameController,
                      isUsername: true),
                  SizedBox(height: 15),

                  // 用户邮箱
                  _buildUserInfoField("Email", _emailController),
                  SizedBox(height: 15),

                  // 用户电话
                  _buildUserInfoField("Phone", _phoneController),
                  SizedBox(height: 30),

                  // 编辑/保存按钮
                  Center(
                    child: ElevatedButton(
                      onPressed: () async {
                        if (_isEditing) {
                          // 保存用户信息
                          SharedPreferences prefs =
                              await SharedPreferences.getInstance();
                          String? token = prefs.getString('auth_token');
                          if (token != null) {
                            try {
                              // 使用修改后的 API 更新用户信息
                              await UserAPI().updateUserProfile(
                                token,
                                _nameController.text,
                                _emailController.text,
                                _phoneController.text,
                              );
                              // 更新用户信息后重新获取用户资料
                              setState(() {
                                _userProfile = _getUserProfile(); // 重新加载用户数据
                                _isEditing = false; // 退出编辑状态
                              });
                            } catch (e) {
                              // 处理错误
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error: $e')));
                            }
                          }
                        } else {
                          // 进入编辑模式
                          setState(() {
                            _isEditing = true;
                          });
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _isEditing ? Colors.green : Colors.blueAccent,
                        padding:
                            EdgeInsets.symmetric(vertical: 15, horizontal: 40),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Text(
                        _isEditing ? 'Save' : 'Edit',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  // 修改密码按钮
                  SizedBox(height: 20),
                  Center(
                    child: ElevatedButton(
                      onPressed: () {
                        // 跳转到修改密码页面
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChangePasswordPage(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orangeAccent,
                        padding:
                            EdgeInsets.symmetric(vertical: 15, horizontal: 40),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Text(
                        'Change Password',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  // 退出登录按钮
                  SizedBox(height: 20),
                  Center(
                    child: ElevatedButton(
                      onPressed: () async {
                        SharedPreferences prefs =
                            await SharedPreferences.getInstance();
                        String? token = prefs.getString('auth_token');
                        if (token != null) {
                          await UserAPI().logout(token);
                          prefs.remove('auth_token');
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (context) => LoginPage()),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        padding:
                            EdgeInsets.symmetric(vertical: 15, horizontal: 40),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Text(
                        'Logout',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }
          },
        ),
      ),
    );
  }

  // 构建用户信息的文本框，如果值为 null，显示占位文本
  Widget _buildUserInfoField(String label, TextEditingController controller,
      {bool isUsername = false}) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.teal, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 属性名称
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
            ),
          ),
          SizedBox(height: 8),

          // 用户信息框
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextFormField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'Enter $label',
                border: InputBorder.none, // 去除默认边框
              ),
              enabled: _isEditing, // 根据是否编辑来决定是否可编辑
              style: TextStyle(
                fontSize: 18,
                color: isUsername ? Colors.teal : Colors.black,
                fontWeight: isUsername ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
