import 'package:flutter/material.dart';
import 'package:frontend/common/token_manager.dart';
import '../../../models/passenger.dart';
import '../../../models/document.dart';
import '../../services/user_api/account_api_server.dart';
import '../../services/user_api/document_api_server.dart';
import 'package:frontend/screens/passenger%20action/add_passenger_page.dart';

class SelectPassengerPage extends StatefulWidget {
  const SelectPassengerPage({Key? key}) : super(key: key);

  @override
  _SelectPassengerPageState createState() => _SelectPassengerPageState();
}

class _SelectPassengerPageState extends State<SelectPassengerPage> {
  List<Passenger> passengers = [];
  List<Document> documents = [];
  Passenger? selectedPassenger;
  Document? selectedDocument;
  bool _isLoadingPassengers = true;
  bool _isLoadingDocuments = false;

  @override
  void initState() {
    super.initState();
    _fetchPassengers();
  }

  Future<void> _fetchPassengers() async {
    try {
      String? token = TokenManager.getToken();
      if (token == null) throw Exception("未登录，请重新登录");

      final fetchedPassengers = await UserAPI().getPassengers(token);
      setState(() {
        passengers = fetchedPassengers;
        _isLoadingPassengers = false;
      });
    } catch (e) {
      print(e);
      setState(() => _isLoadingPassengers = false);
    }
  }

  Future<void> _fetchDocuments(int passengerId) async {
    setState(() {
      _isLoadingDocuments = true;
      documents = [];
    });

    try {
      final fetchedDocuments =
          await DocumentApi().getDocumentsByPassenger(passengerId);
      setState(() {
        documents = fetchedDocuments;
        _isLoadingDocuments = false;
      });
    } catch (e) {
      print(e);
      setState(() => _isLoadingDocuments = false);
    }
  }

  Widget _buildHeader(String title) {
    return Container(
      margin: EdgeInsets.only(left: 16, top: 8, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.teal.shade700,
        ),
      ),
    );
  }

  Widget _buildPassengerList() {
    return ListView.separated(
      padding: EdgeInsets.all(12),
      itemCount: passengers.length,
      separatorBuilder: (_, __) => SizedBox(height: 10),
      itemBuilder: (context, index) {
        final passenger = passengers[index];
        final isSelected = passenger == selectedPassenger;

        return Card(
          color: isSelected ? Colors.teal.shade50 : Colors.white,
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isSelected ? Colors.teal : Colors.grey.shade300,
              child: Icon(Icons.person, color: Colors.white),
            ),
            title: Text(
              passenger.name,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.teal.shade900,
              ),
            ),
            subtitle: Text(
              "类型: ${passenger.personType}",
              style: TextStyle(color: Colors.black54),
            ),
            trailing: isSelected
                ? Icon(Icons.check_circle, color: Colors.teal)
                : null,
            onTap: () {
              setState(() {
                selectedPassenger = passenger;
                selectedDocument = null;
                _fetchDocuments(passenger.id);
              });
            },
          ),
        );
      },
    );
  }

  Widget _buildDocumentList() {
    if (_isLoadingDocuments) {
      return Center(child: CircularProgressIndicator(color: Colors.teal));
    }

    if (documents.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          "该乘客没有证件信息",
          style: TextStyle(color: Colors.black54, fontSize: 16),
        ),
      );
    }

    return Container(
      height: 200,
      child: ListView.separated(
        padding: EdgeInsets.all(12),
        separatorBuilder: (_, __) => SizedBox(height: 10),
        itemCount: documents.length,
        itemBuilder: (context, index) {
          final document = documents[index];
          final isSelected = document == selectedDocument;

          return Card(
            color: isSelected ? Colors.orange.shade50 : Colors.white,
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: Icon(
                Icons.credit_card,
                color: isSelected ? Colors.orange : Colors.grey.shade700,
              ),
              title: Text(
                "${document.type}: ${document.number}",
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color:
                        isSelected ? Colors.orange.shade800 : Colors.black87),
              ),
              trailing: isSelected
                  ? Icon(Icons.check_circle, color: Colors.orange)
                  : null,
              onTap: () {
                setState(() {
                  selectedDocument = document;
                });
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildAddPassengerButton() {
    return ElevatedButton.icon(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => AddPassengerPage()),
        ).then((_) => _fetchPassengers());
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.teal,
        padding: EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: Icon(Icons.add, color: Colors.white),
      label: Text(
        "添加新乘机人",
        style: TextStyle(fontSize: 16, color: Colors.white),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("选择乘客", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.teal,
        actions: [
          TextButton(
            onPressed: selectedPassenger != null && selectedDocument != null
                ? () {
                    Navigator.pop(context, {
                      "passenger": selectedPassenger,
                      "document": selectedDocument,
                    });
                  }
                : null,
            child: Text(
              "完成",
              style: TextStyle(
                color: selectedPassenger != null && selectedDocument != null
                    ? Colors.white
                    : Colors.grey.shade400,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: _isLoadingPassengers
          ? Center(child: CircularProgressIndicator(color: Colors.teal))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader("选择乘客"),
                Expanded(child: _buildPassengerList()),
                SizedBox(height: 20),
                  _buildAddPassengerButton(),
            
                
                if (selectedPassenger != null) ...[
                  _buildHeader("选择证件"),
                  _buildDocumentList(),
                ],
              ],
            ),
    );
  }
}