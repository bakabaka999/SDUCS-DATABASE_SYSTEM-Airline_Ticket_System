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
        SnackBar(content: Text('Error fetching documents: $e')),
      );
    }
  }

  Future<void> _deleteDocument(int documentId) async {
    try {
      await _documentApi.deleteDocument(documentId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Document deleted successfully')),
      );
      _loadPassengerDocuments();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting document: $e')),
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
      appBar: AppBar(
        title: Text('Passenger Documents'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _documents.isEmpty
              ? Center(
                  child: Text(
                    'No documents available',
                    style: TextStyle(fontSize: 18),
                  ),
                )
              : ListView.builder(
                  itemCount: _documents.length,
                  itemBuilder: (context, index) {
                    final document = _documents[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: ListTile(
                        title: Text(
                          document.type,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text('Document Number: ${document.number}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _navigateToAddOrEditDocumentPage(
                                  document: document),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteDocument(document.id),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddOrEditDocumentPage(),
        child: Icon(Icons.add),
        backgroundColor: Colors.blue,
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
    {'value': 'id_card', 'label': 'ID Card'},
    {'value': 'passport', 'label': 'Passport'},
    {'value': 'hukou_booklet', 'label': 'Hukou Booklet'},
    {'value': 'birth_certificate', 'label': 'Birth Certificate'},
    {'value': 'other', 'label': 'Other'},
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

  Future<void> _saveDocument(BuildContext context) async {
    if (_selectedDocumentType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a document type')),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Document added successfully')),
        );
      } else {
        await _documentApi.updateDocument(widget.document!.id, {
          'passenger_id': widget.passengerId,
          'document_type': _selectedDocumentType,
          'document_number': _documentNumberController.text,
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Document updated successfully')),
        );
      }
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving document: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.document == null ? 'Add Document' : 'Edit Document'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Document Type',
                border: OutlineInputBorder(),
              ),
              value: _selectedDocumentType,
              items: _documentTypes
                  .map((type) => DropdownMenuItem<String>(
                        value: type['value'],
                        child: Text(type['label']!),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedDocumentType = value;
                });
              },
            ),
            SizedBox(height: 16),
            TextField(
              controller: _documentNumberController,
              decoration: InputDecoration(
                labelText: 'Document Number',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _saveDocument(context),
              child: Text(
                  widget.document == null ? 'Add Document' : 'Save Changes'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 24.0),
                textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
