import 'package:flutter/material.dart';
import 'package:frontend/models/passenger.dart';
import 'package:frontend/screens/add_passenger_page.dart';
import 'package:frontend/services/user_api/account_api.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PassengerInfoPage extends StatefulWidget {
  @override
  _PassengerInfoPageState createState() => _PassengerInfoPageState();
}

class _PassengerInfoPageState extends State<PassengerInfoPage> {
  late Passenger? _selectedPassenger; // 允许为空
  bool _isLoading = true;
  List<Passenger> _passengerList = []; // 存储乘机人列表
  bool _isEditing = false; // 控制是否进入编辑模式
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

  // 加载乘机人信息列表
  Future<void> _loadPassengerInfo() async {
    String token = await _getToken();
    try {
      List<Passenger> passengers = await UserAPI().getPassengers(token);
      setState(() {
        _passengerList = passengers;
        _isLoading = false;

        if (passengers.isNotEmpty) {
          _selectedPassenger = passengers.first;

          // 初始化表单内容
          _initializePassengerDetails(_selectedPassenger!);
        } else {
          _selectedPassenger = null; // 无乘客信息
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error loading passenger info: $e');
    }
  }

  // 初始化乘客详情到表单中
  void _initializePassengerDetails(Passenger passenger) {
    _nameController.text = passenger.name;
    _phoneController.text = passenger.phoneNumber;
    _emailController.text = passenger.email;
    _birthDateController.text = passenger.birthDate;
    _selectedPersonType = passenger.personType;
    _selectedGender = passenger.gender;
  }

  // 获取 Token
  Future<String> _getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token') ?? '';
  }

  // 跳转到添加乘机人页面
  void _navigateToAddPassengerPage() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddPassengerPage()),
    );
    _loadPassengerInfo(); // 刷新列表
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
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Passenger updated successfully')));

      setState(() {
        _isEditing = false;
      });
    } catch (e) {
      print('Error updating passenger info: $e');
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to update passenger')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Passenger Info')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('Passenger Info')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: <Widget>[
            ElevatedButton(
              onPressed: _navigateToAddPassengerPage,
              child: Text('Add New Passenger'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 24.0),
                textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(height: 20),
            if (_passengerList.isNotEmpty)
              DropdownButton<Passenger>(
                value: _selectedPassenger,
                onChanged: (Passenger? newValue) {
                  setState(() {
                    _selectedPassenger = newValue!;
                    _initializePassengerDetails(newValue);
                  });
                },
                items: _passengerList
                    .map<DropdownMenuItem<Passenger>>((Passenger passenger) {
                  return DropdownMenuItem<Passenger>(
                    value: passenger,
                    child: Text(passenger.name),
                  );
                }).toList(),
              ),
            SizedBox(height: 20),
            _buildTextField(
                controller: _nameController,
                label: 'Name',
                enabled: _isEditing),
            SizedBox(height: 16),
            _buildDropdownField(
              label: 'Gender',
              value: _selectedGender,
              items: [
                DropdownMenuItem(value: true, child: Text('Male')),
                DropdownMenuItem(value: false, child: Text('Female')),
              ],
              onChanged: _isEditing
                  ? (value) => setState(() => _selectedGender = value as bool?)
                  : null,
            ),
            SizedBox(height: 16),
            _buildTextField(
                controller: _phoneController,
                label: 'Phone',
                enabled: _isEditing),
            SizedBox(height: 16),
            _buildTextField(
                controller: _emailController,
                label: 'Email',
                enabled: _isEditing),
            SizedBox(height: 16),
            _buildDatePickerField(
              controller: _birthDateController,
              label: 'Birth Date',
              enabled: _isEditing,
            ),
            SizedBox(height: 16),
            _buildDropdownField(
              label: 'Person Type',
              value: _selectedPersonType,
              items: [
                DropdownMenuItem(value: 'adult', child: Text('Adult')),
                DropdownMenuItem(value: 'student', child: Text('Student')),
                DropdownMenuItem(value: 'teacher', child: Text('Teacher')),
                DropdownMenuItem(
                    value: 'senior', child: Text('Senior Citizen')),
              ],
              onChanged: _isEditing
                  ? (value) => setState(() => _selectedPersonType = value as String?)
                  : null,
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  if (_isEditing) {
                    _updatePassengerInfo();
                  } else {
                    _isEditing = true;
                  }
                });
              },
              child: Text(_isEditing ? 'Submit Changes' : 'Edit Info'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isEditing ? Colors.green : Colors.blue,
                padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 24.0),
                textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required bool enabled,
  }) {
    return TextField(
      controller: controller,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        filled: true,
        fillColor: Colors.white70,
      ),
    );
  }

  Widget _buildDropdownField<T>({
    required String label,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?)? onChanged,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      decoration:
          InputDecoration(labelText: label, border: OutlineInputBorder()),
      items: items,
      onChanged: onChanged,
    );
  }

  Widget _buildDatePickerField({
    required TextEditingController controller,
    required String label,
    required bool enabled,
  }) {
    return GestureDetector(
      onTap: enabled
          ? () async {
              DateTime? selectedDate = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(1900),
                lastDate: DateTime(2100),
              );
              if (selectedDate != null) {
                setState(() {
                  controller.text =
                      selectedDate.toIso8601String().split('T').first;
                });
              }
            }
          : null,
      child: AbsorbPointer(
        child: TextField(
          controller: controller,
          enabled: enabled,
          decoration: InputDecoration(
            labelText: label,
            border: OutlineInputBorder(),
            filled: true,
            fillColor: Colors.white70,
          ),
        ),
      ),
    );
  }
}
