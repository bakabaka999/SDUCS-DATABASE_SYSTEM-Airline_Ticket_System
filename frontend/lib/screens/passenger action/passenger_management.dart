import 'package:flutter/material.dart';
import 'package:frontend/common/token_manager.dart';
import 'package:frontend/screens/passenger%20action/add_passenger_page.dart';
import 'package:frontend/screens/passenger%20action/document_info.dart';
import 'package:frontend/models/passenger.dart';
import 'package:frontend/services/user_api/account_api_server.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PassengerInfoPage extends StatefulWidget {
  @override
  _PassengerInfoPageState createState() => _PassengerInfoPageState();
}

class _PassengerInfoPageState extends State<PassengerInfoPage> {
  late Passenger? _selectedPassenger;
  bool _isLoading = true;
  List<Passenger> _passengerList = [];
  bool _isEditing = false;

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _birthDateController = TextEditingController();
  String? _selectedPersonType;
  bool? _selectedGender;

  @override
  void initState() {
    super.initState();
    _loadPassengerInfo();
  }

  // 获取乘机人信息
  Future<void> _loadPassengerInfo() async {
    String token = await _getToken();
    try {
      List<Passenger> passengers = await UserAPI().getPassengers(token);
      setState(() {
        _passengerList = passengers;
        _isLoading = false;

        if (passengers.isNotEmpty) {
          _selectedPassenger = passengers.first;
          _initializePassengerDetails(_selectedPassenger!);
        } else {
          _selectedPassenger = null;
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 初始化乘机人详情
  void _initializePassengerDetails(Passenger passenger) {
    _nameController.text = passenger.name;
    _phoneController.text = passenger.phoneNumber;
    _emailController.text = passenger.email;
    _birthDateController.text = passenger.birthDate;
    _selectedPersonType = passenger.personType;
    _selectedGender = passenger.gender;
  }

  Future<String> _getToken() async {
    String? token = TokenManager.getToken();
    if (token == null || token.isEmpty) {
      throw Exception("用户未登录，请重新登录");
    }
    return token;
  }

  // 更新乘机人信息
  Future<void> _updatePassengerInfo() async {
    String token = await _getToken();
    if (_selectedPassenger == null) return;

    Map<String, dynamic> updatedData = {
      'name': _nameController.text,
      'gender': _selectedGender,
      'phone': _phoneController.text,
      'email': _emailController.text,
      'birth_date': _birthDateController.text,
      'person_type': _selectedPersonType,
    };

    try {
      await UserAPI()
          .updatePassenger(token, _selectedPassenger!.id, updatedData);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('更新成功')));

      setState(() {
        _isEditing = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('更新失败，请重试')));
    }
  }

  // 跳转到证件管理页面
  void _navigateToDocumentsPage() {
    if (_selectedPassenger != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PassengerDocumentsPage(
            passengerId: _selectedPassenger!.id,
          ),
        ),
      );
    }
  }

  
  // 构建界面
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal.shade50,
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.teal))
          : _passengerList.isEmpty
              ? _buildEmptyState() // 使用自定义方法展示空状态和添加按钮
              : _buildPassengerManagement(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_alt, size: 100, color: Colors.teal.shade200),
          SizedBox(height: 16),
          Text(
            "暂无乘机人信息，请添加！",
            style: TextStyle(fontSize: 18, color: Colors.black54),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddPassengerPage()),
              ).then((_) => _loadPassengerInfo()); // 添加后刷新数据
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              padding: EdgeInsets.symmetric(vertical: 14, horizontal: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: Icon(Icons.add, color: Colors.white),
            label: Text(
              "添加乘机人",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPassengerManagement() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildAddPassengerButton(),
          SizedBox(height: 20),
          Expanded(
            child: SingleChildScrollView(
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildDropdown(),
                      Divider(height: 30),
                      _buildDetailSection("姓名", _nameController),
                      _buildGenderSection(),
                      _buildDetailSection("电话", _phoneController),
                      _buildDetailSection("邮箱", _emailController),
                      _buildDetailSection("出生日期", _birthDateController),
                      _buildPersonTypeSection(),
                      SizedBox(height: 20),
                      _buildActionButtons(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddPassengerButton() {
    return ElevatedButton.icon(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => AddPassengerPage()),
        ).then((_) => _loadPassengerInfo());
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.teal,
        padding: EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: Icon(Icons.add, color: Colors.white),
      label:
          Text("添加新乘机人", style: TextStyle(fontSize: 16, color: Colors.white)),
    );
  }

  Widget _buildDropdown() {
    return DropdownButton<Passenger>(
      isExpanded: true,
      value: _selectedPassenger,
      onChanged: (Passenger? newValue) {
        if (_isEditing) {
          _showDiscardChangesDialog(newValue!);
        } else {
          setState(() {
            _selectedPassenger = newValue!;
            _initializePassengerDetails(newValue);
          });
        }
      },
      items: _passengerList.map<DropdownMenuItem<Passenger>>((Passenger p) {
        return DropdownMenuItem<Passenger>(
          value: p,
          child: Text(p.name, style: TextStyle(fontSize: 16)),
        );
      }).toList(),
    );
  }

  Widget _buildDetailSection(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextField(
        controller: controller,
        enabled: _isEditing,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: _isEditing ? Colors.white : Colors.grey.shade100,
        ),
      ),
    );
  }

  Widget _buildGenderSection() {
    return _buildDropdownField(
        "性别", _selectedGender, [true, false], ["男", "女"]);
  }

  Widget _buildPersonTypeSection() {
    List<String> personTypes = ["adult", "student", "teacher", "senior"];
    List<String> labels = ["成人", "学生", "教师", "老人"];
    return _buildDropdownField(
        "乘机人类型", _selectedPersonType, personTypes, labels);
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton(
          onPressed: _navigateToDocumentsPage,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orangeAccent,
            padding: EdgeInsets.symmetric(vertical: 14, horizontal: 20),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child:
              Text("证件管理", style: TextStyle(fontSize: 16, color: Colors.white)),
        ),
        ElevatedButton(
          onPressed: () {
            if (_isEditing) _updatePassengerInfo();
            setState(() {
              _isEditing = !_isEditing;
            });
          },
         
          style: ElevatedButton.styleFrom(
            backgroundColor:_isEditing ? Colors.green : Colors.blueAccent,
            padding: EdgeInsets.symmetric(vertical: 14, horizontal: 20),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(
            _isEditing ? "保存修改" : "编辑信息",
            style: TextStyle(fontSize: 16, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField(
      String label, dynamic value, List<dynamic> items, List<String> labels) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: DropdownButtonFormField(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: _isEditing ? Colors.white : Colors.grey.shade100,
        ),
        items: items.asMap().entries.map((entry) {
          int idx = entry.key;
          dynamic item = entry.value;
          return DropdownMenuItem(
            value: item,
            child: Text(labels[idx]),
          );
        }).toList(),
        onChanged: _isEditing
            ? (val) => setState(() {
                  if (label == "性别") {
                    _selectedGender = val as bool;
                  } else {
                    _selectedPersonType = val as String;
                  }
                })
            : null,
      ),
    );
  }

  Future<void> _showDiscardChangesDialog(Passenger newValue) async {
    bool discard = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text("放弃更改？"),
            content: Text("切换乘机人将丢弃当前未保存的修改，是否继续？"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text("取消"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text("确认", style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ) ??
        false;

    if (discard) {
      setState(() {
        _isEditing = false;
        _selectedPassenger = newValue;
        _initializePassengerDetails(newValue);
      });
    }
  }
}
