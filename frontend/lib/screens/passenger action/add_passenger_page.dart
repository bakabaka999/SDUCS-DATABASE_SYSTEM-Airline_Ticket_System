import 'package:flutter/material.dart';
import 'package:frontend/common/token_manager.dart';
import 'package:frontend/services/user_api/account_api_server.dart';
import 'package:frontend/common/token_manager.dart';

class AddPassengerPage extends StatefulWidget {
  @override
  _AddPassengerPageState createState() => _AddPassengerPageState();
}

class _AddPassengerPageState extends State<AddPassengerPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  // final _conditionsController = TextEditingController();
  final _birthDateController = TextEditingController();
  bool _gender = true; // 默认性别为男性

  String? _selectedPersonType = "adult"; // 默认类型为成人

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal.shade50,
      body: Row(
        children: [
          // 侧边栏 (保持不变)
          Container(
            width: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.teal.shade700, Colors.teal.shade300],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Column(
              children: [
                SizedBox(height: 20),
                Icon(Icons.flight, size: 50, color: Colors.white),
                SizedBox(height: 10),
                Text(
                  "航班管理",
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.bold),
                ),
                Spacer(),
                IconButton(
                  icon: Icon(Icons.arrow_back, color: Colors.white, size: 30),
                  onPressed: () => Navigator.pop(context),
                ),
                SizedBox(height: 20),
              ],
            ),
          ),

          // 主内容区域
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
              child: SingleChildScrollView(
                child: Card(
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(),
                        SizedBox(height: 20),
                        _buildForm(),
                        SizedBox(height: 20),
                        _buildSubmitButton(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 页面顶部标题
  Widget _buildHeader() {
    return Center(
      child: Column(
        children: [
          Icon(Icons.person_add_alt_1,
              size: 70, color: Colors.teal.shade700), // 添加乘机人图标
          SizedBox(height: 10),
          Text(
            "添加新乘机人",
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.teal.shade700,
            ),
          ),
          Text(
            "请填写乘机人信息",
            style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }

  // 表单
  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          _buildTextField("姓名", _nameController, "请输入乘机人姓名", true),
          SizedBox(height: 15),
          _buildGenderField(),
          SizedBox(height: 15),
          _buildTextField("电话", _phoneController, "请输入电话号码", true),
          SizedBox(height: 15),
          _buildTextField("邮箱", _emailController, "请输入邮箱地址", true),
          SizedBox(height: 15),
          /*_buildTextField(
              "认证条件 (可选)", _conditionsController, "例如：学生、教师等", false),*/
          _buildPersonTypeField(),
          SizedBox(height: 15),
          _buildDatePickerField(),
        ],
      ),
    );
  }

  // 乘机人类型选择
  Widget _buildPersonTypeField() {
    return Row(
      children: [
        Text("乘机人类型 *: ", style: TextStyle(fontSize: 16)),
        Row(
          children: [
            Radio(
              value: "adult",
              groupValue: _selectedPersonType,
              onChanged: (String? value) {
                setState(() {
                  _selectedPersonType = value;
                });
              },
            ),
            Text("成人"),
            Radio(
              value: "student",
              groupValue: _selectedPersonType,
              onChanged: (String? value) {
                setState(() {
                  _selectedPersonType = value;
                });
              },
            ),
            Text("学生"),
            Radio(
              value: "teacher",
              groupValue: _selectedPersonType,
              onChanged: (String? value) {
                setState(() {
                  _selectedPersonType = value;
                });
              },
            ),
            Text("教师"),
            Radio(
              value: "senior",
              groupValue: _selectedPersonType,
              onChanged: (String? value) {
                setState(() {
                  _selectedPersonType = value;
                });
              },
            ),
            Text("老人"),
          ],
        ),
      ],
    );
  }

  // 构建输入框
  Widget _buildTextField(String label, TextEditingController controller,
      String hint, bool required) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: "$label ${required ? '*' : ''}",
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      validator:
          required ? (value) => value!.isEmpty ? "$label不能为空" : null : null,
    );
  }

  // 性别选择
  Widget _buildGenderField() {
    return Row(
      children: [
        Text("性别 *: ", style: TextStyle(fontSize: 16)),
        Row(
          children: [
            Radio(
              value: true,
              groupValue: _gender,
              onChanged: (bool? value) {
                setState(() {
                  _gender = value!;
                });
              },
            ),
            Text("男"),
            Radio(
              value: false,
              groupValue: _gender,
              onChanged: (bool? value) {
                setState(() {
                  _gender = value!;
                });
              },
            ),
            Text("女"),
          ],
        ),
      ],
    );
  }

  // 出生日期选择器
  Widget _buildDatePickerField() {
    return GestureDetector(
      onTap: () async {
        DateTime? pickedDate = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(1900),
          lastDate: DateTime.now(),
        );
        if (pickedDate != null) {
          setState(() {
            _birthDateController.text =
                pickedDate.toIso8601String().split('T')[0];
          });
        }
      },
      child: AbsorbPointer(
        child: TextFormField(
          controller: _birthDateController,
          decoration: InputDecoration(
            labelText: "出生日期 (可选)",
            hintText: "请选择出生日期",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.white,
            suffixIcon: Icon(Icons.calendar_today, color: Colors.teal),
          ),
        ),
      ),
    );
  }

  // 提交按钮
  Widget _buildSubmitButton() {
    return Center(
      child: ElevatedButton(
        onPressed: _addPassenger,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.teal,
          padding: EdgeInsets.symmetric(vertical: 14, horizontal: 40),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          "确认添加",
          style: TextStyle(fontSize: 18, color: Colors.white),
        ),
      ),
    );
  }

  // 添加乘机人的方法
  Future<void> _addPassenger() async {
    if (!_formKey.currentState!.validate()) return;

    String name = _nameController.text;
    String phone = _phoneController.text;
    String email = _emailController.text;
    // String conditions = _conditionsController.text.isNotEmpty
    //     ? _conditionsController.text
    //     : "None";
    String birthDate = _birthDateController.text.isNotEmpty
        ? _birthDateController.text
        : "1990-01-01"; // 默认日期

    try {
      String? token = TokenManager.getToken();
      if (token != null) {
        UserAPI userAPI = UserAPI();
        Map<String, dynamic> data = {
          'name': name,
          'gender': _gender,
          'phone_number': phone,
          'email': email,
          // 'conditions': conditions,
          'birth_date': birthDate,
          'person_type': _selectedPersonType,
        };
        await userAPI.addPassenger(token, data);
        Navigator.pop(context);
      }
    } catch (e) {
      _showErrorDialog('添加乘机人失败，请稍后重试');
    }
  }

  // 错误提示对话框
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("错误"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("确定"),
          ),
        ],
      ),
    );
  }
}
