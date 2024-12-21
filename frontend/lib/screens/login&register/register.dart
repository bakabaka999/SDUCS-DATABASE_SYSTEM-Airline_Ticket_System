import 'package:flutter/material.dart';
import 'package:frontend/services/user_api/account_api_server.dart';
import 'ground.dart';

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';

  void _register() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = "两次输入的密码不一致";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // 调用 UserAPI 注册接口
      final response = await UserAPI().register(
        _usernameController.text,
        _emailController.text,
        _passwordController.text,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("注册成功，请返回登录页面"),
          backgroundColor: Colors.teal,
        ),
      );

      Navigator.pop(context); // 返回登录页面
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll("Exception: ", "");
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }


   @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal.shade50,
      body: Stack(
      children: [
        // 背景动画层
        Positioned.fill(
          child: AnimatedBackground(), // 将动画作为底层背景
        ),
       SingleChildScrollView(
         child: Container(
          height: MediaQuery.of(context).size.height,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // 使列中的子组件垂直居中
          children: [
            _buildRegisterForm(),
            SizedBox(height: 10),
            if (_errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  _errorMessage,
                  style: TextStyle(color: Colors.red),
                ),
              ),
          ],
        ),
      ),
      ),
      ]
      ),
    );
  }

  // 顶部 Logo 和标题
  Widget _buildHeader() {
    return Column(
      children: [
        Icon(Icons.person_add, size: 100, color: Colors.teal),
        SizedBox(height: 10),
        Text(
          "创建您的账号",
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.teal.shade700,
          ),
        ),
        
        Text(
          "快速注册，开启您的旅程",
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildRegisterForm() {
  return Center(
    
    child: Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: 400, // 设置卡片宽度
        // 移除高度设置，让高度自适应内容
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            // 垂直方向上居中对齐
            children: [
              _buildHeader(),
              SizedBox(height: 20),
               _buildTextField(
   controller: _usernameController,
  label: "用户名",
  icon: Icons.person,
  maxLength: 35, // 用户名最大长度
  validator: (value) =>
      value == null || value.isEmpty ? "请输入用户名" : null,
),
              SizedBox(height: 15),
              _buildTextField(
                controller: _emailController,
                label: "邮箱",
                icon: Icons.email,
                inputType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || !value.contains('@')) {
                    return "请输入有效的邮箱地址";
                  }
                  return null;
                },
              ),
              SizedBox(height: 15),
              _buildTextField(
                controller: _passwordController,
                label: "密码",
                icon: Icons.lock,
                isPassword: true,
                validator: (value) {
                  if (value == null || value.length < 6) {
                    return "密码长度不能少于6个字符";
                  }
                  return null;
                },
              ),
              SizedBox(height: 15),
              _buildTextField(
                controller: _confirmPasswordController,
                label: "确认密码",
                icon: Icons.lock_outline,
                isPassword: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "请再次输入密码";
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              _isLoading
                     ? Center(
                        child: CircularProgressIndicator(color: Colors.teal))
                    : SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _register,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            padding: EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text("注册",
                              style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
              SizedBox(height: 10),
              _buildLoginLink(),              
            ],
          ),
        ),
      ),
    ),
  );
}
  // 返回登录的链接
  Widget _buildLoginLink() {
    return TextButton(
      onPressed: () {
        Navigator.pop(context);
      },
      child: Text(
        "已有账号？去登录",
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.teal,
        ),
      ),
    );
  }

  // 公共输入框组件
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    int? maxLength, // 保持为 int? 类型
    TextInputType inputType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: inputType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.teal),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.teal, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
       maxLength: maxLength,
      validator: validator,
    );
  }
}
