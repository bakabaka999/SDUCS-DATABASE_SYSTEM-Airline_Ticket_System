import 'package:flutter/material.dart';
import 'package:frontend/common/token_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/user_api/account_api_server.dart';
import 'register.dart';
import '../main_page.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _checkAutoLogin();
  }

  void _checkAutoLogin() async {
    setState(() => _isLoading = true);
    try {
      String? token = await TokenManager.getToken();
      if (token != null) {
        bool isValid = await UserAPI().validateToken(token);
        if (isValid) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => MainPage()),
          );
        }
      }
    } catch (e) {
      print('自动登录失败: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      var response = await UserAPI()
          .login(_usernameController.text, _passwordController.text);
      if (response['message'] == 'Login successful') {
        await TokenManager.updateToken(
            response['token']); // 使用 TokenManager 保存 Token
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MainPage()),
        );
      } else {
        setState(() => _errorMessage = '用户名或密码错误');
      }
    } catch (e) {
      setState(() => _errorMessage = '登录失败，请检查网络连接');
    } finally {
      setState(() => _isLoading = false);
    }
  }


  void _goToRegisterPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => RegisterPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal.shade50,
      body: SingleChildScrollView(
        child: Container(
          height: MediaQuery.of(context).size.height,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildHeader(),
              SizedBox(height: 20),
              _buildLoginForm(),
              SizedBox(height: 10),
              if (_errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Text(
                    _errorMessage,
                    style: TextStyle(
                        color: Colors.red, fontWeight: FontWeight.w500),
                  ),
                ),
              SizedBox(height: 10),
              TextButton(
                onPressed: _goToRegisterPage,
                child: Text(
                  "没有账号？立即注册",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Icon(Icons.airplanemode_active, size: 100, color: Colors.teal),
        Text(
          "航空售票系统",
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.teal.shade700,
          ),
        ),
        Text(
          "请登录您的账号",
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTextField(
                  controller: _usernameController,
                  label: "用户名",
                  icon: Icons.person,
                  validator: (value) =>
                      value == null || value.isEmpty ? "请输入用户名" : null,
                ),
                SizedBox(height: 20),
                _buildTextField(
                  controller: _passwordController,
                  label: "密码",
                  icon: Icons.lock,
                  isPassword: true,
                  validator: (value) =>
                      value == null || value.isEmpty ? "请输入密码" : null,
                ),
                SizedBox(height: 30),
                _isLoading
                    ? Center(
                        child: CircularProgressIndicator(color: Colors.teal))
                    : SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            padding: EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text("登录",
                              style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.teal),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      validator: validator,
    );
  }
}
