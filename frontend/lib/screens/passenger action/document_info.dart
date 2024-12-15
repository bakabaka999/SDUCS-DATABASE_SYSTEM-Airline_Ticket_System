import 'package:flutter/material.dart';
import 'package:frontend/models/document.dart';
import 'package:frontend/services/user_api/document_api_server.dart';

class PassengerDocumentsPage extends StatefulWidget {
  final int passengerId;

  PassengerDocumentsPage({required this.passengerId});

  @override
  _PassengerDocumentsPageState createState() => _PassengerDocumentsPageState();
}

class _PassengerDocumentsPageState extends State<PassengerDocumentsPage> {
  bool _isLoading = true;
  List<Document> _documents = [];
  final DocumentApi _documentApi = DocumentApi();

  @override
  void initState() {
    super.initState();
    _loadPassengerDocuments();
  }

  Future<void> _loadPassengerDocuments() async {
    setState(() => _isLoading = true);
    try {
      List<Document> documents =
          await _documentApi.getDocumentsByPassenger(widget.passengerId);
      setState(() {
        _documents = documents;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('获取证件失败: $e')),
      );
    }
  }

  Future<void> _deleteDocument(int documentId) async {
    try {
      await _documentApi.deleteDocument(documentId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('证件删除成功')),
      );
      _loadPassengerDocuments();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('删除失败: $e')),
      );
    }
  }

  void _navigateToAddOrEditDocumentPage({Document? document}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddOrEditDocumentPage(
          passengerId: widget.passengerId,
          document: document,
        ),
      ),
    ).then((_) => _loadPassengerDocuments());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // 侧边栏
          _buildSidebar(),

          // 主内容区域
          Expanded(
            child: Scaffold(
              backgroundColor: Colors.teal.shade50,
              appBar: AppBar(
                title: Text("证件管理"),
                centerTitle: true,
                flexibleSpace: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.teal.shade700, Colors.teal.shade300],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),
              body: _isLoading
                  ? Center(child: CircularProgressIndicator(color: Colors.teal))
                  : _documents.isEmpty
                      ? Center(
                          child: Text(
                            "暂无证件信息，请添加",
                            style:
                                TextStyle(fontSize: 18, color: Colors.black54),
                          ),
                        )
                      : Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: ListView.builder(
                            itemCount: _documents.length,
                            itemBuilder: (context, index) {
                              final document = _documents[index];
                              return _buildDocumentCard(document);
                            },
                          ),
                        ),
              floatingActionButton: FloatingActionButton.extended(
                onPressed: () => _navigateToAddOrEditDocumentPage(),
                label: Text("添加证件"),
                icon: Icon(Icons.add),
                backgroundColor: Colors.teal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 侧边栏
  Widget _buildSidebar() {
    return Container(
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
          SizedBox(height: 30),
          Icon(Icons.flight, size: 40, color: Colors.white),
          SizedBox(height: 10),
          Text("航班管理",
              style: TextStyle(
                  fontSize: 12,
                  color: Colors.white,
                  fontWeight: FontWeight.bold)),
          Spacer(),
          IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white, size: 30),
            onPressed: () => Navigator.pop(context),
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }

  // 证件卡片
  Widget _buildDocumentCard(Document document) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: EdgeInsets.all(16),
        leading: Icon(Icons.description, color: Colors.teal, size: 40),
        title: Text(
          document.type,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        subtitle: Text("证件号码: ${document.number}"),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.edit, color: Colors.orangeAccent),
              onPressed: () => _navigateToAddOrEditDocumentPage(
                document: document,
              ),
            ),
            IconButton(
              icon: Icon(Icons.delete, color: Colors.redAccent),
              onPressed: () => _deleteDocument(document.id),
            ),
          ],
        ),
      ),
    );
  }
}

class AddOrEditDocumentPage extends StatefulWidget {
  final int passengerId;
  final Document? document;

  AddOrEditDocumentPage({required this.passengerId, this.document});

  @override
  _AddOrEditDocumentPageState createState() => _AddOrEditDocumentPageState();
}

class _AddOrEditDocumentPageState extends State<AddOrEditDocumentPage> {
  final _documentNumberController = TextEditingController();
  final DocumentApi _documentApi = DocumentApi();

  final List<Map<String, String>> _documentTypes = [
    {'value': 'id_card', 'label': '身份证'},
    {'value': 'passport', 'label': '护照'},
    {'value': 'hukou_booklet', 'label': '户口本'},
    {'value': 'birth_certificate', 'label': '出生证明'},
    {'value': 'other', 'label': '其他'},
  ];

  String? _selectedDocumentType;

  @override
  void initState() {
    super.initState();
    if (widget.document != null) {
      _selectedDocumentType = widget.document!.type;
      _documentNumberController.text = widget.document!.number;
    }
  }

  Future<void> _saveDocument() async {
    if (_selectedDocumentType == null ||
        _documentNumberController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('请填写完整信息')),
      );
      return;
    }

    try {
      if (widget.document == null) {
        await _documentApi.addDocument({
          'passenger_id': widget.passengerId,
          'document_type': _selectedDocumentType,
          'document_number': _documentNumberController.text,
        });
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('证件添加成功')));
      } else {
        await _documentApi.updateDocument(widget.document!.id, {
          'document_type': _selectedDocumentType,
          'document_number': _documentNumberController.text,
        });
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('证件修改成功')));
      }
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('保存失败: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // 侧边栏
          _buildSidebar(),

          // 主内容区域
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.teal.shade50, Colors.white],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Card(
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(),
                          SizedBox(height: 20),
                          _buildDropdown(),
                          SizedBox(height: 16),
                          _buildDocumentNumberField(),
                          SizedBox(height: 30),
                          _buildSaveButton(),
                        ],
                      ),
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

  // 侧边栏
  Widget _buildSidebar() {
    return Container(
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
          SizedBox(height: 30),
          Icon(Icons.flight, size: 40, color: Colors.white),
          SizedBox(height: 10),
          Text("航班管理",
              style: TextStyle(
                  fontSize: 12,
                  color: Colors.white,
                  fontWeight: FontWeight.bold)),
          Spacer(),
          IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white, size: 30),
            onPressed: () => Navigator.pop(context),
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }

  // 标题
  Widget _buildHeader() {
    return Center(
      child: Column(
        children: [
          Icon(Icons.assignment, size: 80, color: Colors.teal.shade700),
          SizedBox(height: 10),
          Text(
            widget.document == null ? "添加证件" : "编辑证件",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.teal.shade700,
            ),
          ),
          SizedBox(height: 10),
          Text(
            "请填写证件信息，确保数据准确无误",
            style: TextStyle(fontSize: 16, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  // 证件类型下拉框
  Widget _buildDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedDocumentType,
      decoration: InputDecoration(
        labelText: '证件类型',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      items: _documentTypes
          .map((type) => DropdownMenuItem<String>(
                value: type['value'],
                child: Text(type['label']!),
              ))
          .toList(),
      onChanged: (value) => setState(() => _selectedDocumentType = value),
    );
  }

  // 证件号码输入框
  Widget _buildDocumentNumberField() {
    return TextField(
      controller: _documentNumberController,
      decoration: InputDecoration(
        labelText: '证件号码',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        prefixIcon: Icon(Icons.confirmation_number, color: Colors.teal),
      ),
    );
  }

  // 保存按钮
  Widget _buildSaveButton() {
    return Center(
      child: ElevatedButton.icon(
        onPressed: _saveDocument,
        icon: Icon(Icons.save, color: Colors.white),
        label: Text(
          "保存证件",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.teal.shade700,
          padding: EdgeInsets.symmetric(vertical: 16, horizontal: 32),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
