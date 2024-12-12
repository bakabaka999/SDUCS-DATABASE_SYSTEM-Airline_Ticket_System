import 'package:flutter/material.dart';
import 'package:frontend/services/user_api/account_api.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddPassengerPage extends StatefulWidget {
  @override
  _AddPassengerPageState createState() => _AddPassengerPageState();
}

class _AddPassengerPageState extends State<AddPassengerPage> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _conditionsController = TextEditingController();
  final _birthDateController = TextEditingController();
  bool _gender = true; // 默认男性

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Passenger'),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 姓名输入框（必填）
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Name *', // 星号表示必填
                  hintText: 'Enter passenger\'s name',
                ),
              ),
              SizedBox(height: 10),

              // 性别选择（必填）
              Row(
                children: [
                  Text('Gender *: '),
                  Radio<bool>(
                    value: true,
                    groupValue: _gender,
                    onChanged: (bool? value) {
                      setState(() {
                        _gender = value!;
                      });
                    },
                  ),
                  Text('Male'),
                  Radio<bool>(
                    value: false,
                    groupValue: _gender,
                    onChanged: (bool? value) {
                      setState(() {
                        _gender = value!;
                      });
                    },
                  ),
                  Text('Female'),
                ],
              ),
              SizedBox(height: 10),

              // 电话输入框（必填）
              TextField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Phone Number *', // 星号表示必填
                  hintText: 'Enter phone number',
                ),
              ),
              SizedBox(height: 10),

              // 邮箱输入框（必填）
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email *', // 星号表示必填
                  hintText: 'Enter email address',
                ),
              ),
              SizedBox(height: 10),

              // 认证条件输入框（选填）
              TextField(
                controller: _conditionsController,
                decoration: InputDecoration(
                  labelText: 'Conditions (Optional)', // 提示为选填
                  hintText: 'Enter conditions (e.g., Student, Teacher)',
                ),
              ),
              SizedBox(height: 10),

              // 出生日期输入框（选填）
              TextField(
                controller: _birthDateController,
                decoration: InputDecoration(
                  labelText: 'Birth Date (Optional)', // 提示为选填
                  hintText: 'YYYY-MM-DD',
                ),
              ),
              SizedBox(height: 20),

              // 提交按钮
              ElevatedButton(
                onPressed: _addPassenger,
                child: Text('Add Passenger'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 添加乘机人的方法
  Future<void> _addPassenger() async {
    String name = _nameController.text;
    String phone = _phoneController.text;
    String email = _emailController.text;
    String conditions = _conditionsController.text.isNotEmpty
        ? _conditionsController.text
        : "None";
    String birthDate = _birthDateController.text.isNotEmpty
        ? _birthDateController.text
        : "1990-01-01"; // 默认日期

    // 验证必填字段是否为空
    if (name.isEmpty || phone.isEmpty || email.isEmpty) {
      _showErrorDialog('Please fill all required fields.');
      return;
    }

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');
      if (token != null) {
        UserAPI userAPI = UserAPI();
        Map<String, dynamic> data = {
          'name': name,
          'gender': _gender,
          'phone_number': phone,
          'email': email,
          'conditions': conditions,
          'birth_date': birthDate,
        };
        await userAPI.addPassenger(token, data); // 调用API添加乘机人
        Navigator.pop(context); // 关闭当前页面，返回上一页
      }
    } catch (e) {
      print('Error adding passenger: $e');
      _showErrorDialog('Failed to add passenger. Please try again later.');
    }
  }

  // 显示错误提示对话框
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
