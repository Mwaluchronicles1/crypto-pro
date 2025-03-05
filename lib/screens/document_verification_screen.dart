import 'package:flutter/material.dart';
import '../services/document_service.dart';
import '../utils/constants.dart';

// Make sure the path matches your project structure
class DocumentVerificationScreen extends StatefulWidget {
  const DocumentVerificationScreen({super.key});

  @override
  State<DocumentVerificationScreen> createState() => _DocumentVerificationScreenState();
}

class _DocumentVerificationScreenState extends State<DocumentVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _hashController = TextEditingController();
  final _titleController = TextEditingController();
  final _documentIdController = TextEditingController();

  List<Map<String, String>> verificationHistory = [];

  bool _isUploading = false;
  bool _isVerifying = false;

  final DocumentService _documentService = DocumentService();

  void _showSnackBar(String message, bool isError) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(8),
      ),
    );
  }

  Future<void> _handleUpload() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isUploading = true);

      try {
        await _documentService.uploadDocument(
          hash: _hashController.text,
          title: _titleController.text,
        );

        setState(() {
          verificationHistory.add({
            'title': _titleController.text,
            'status': 'Registered on Blockchain',
          });
        });

        _showSnackBar('Document registered on blockchain successfully', false);
        _titleController.clear();
        _hashController.clear();
      } catch (e) {
        _showSnackBar('Failed to register document: ${e.toString()}', true);
      } finally {
        setState(() => _isUploading = false);
      }
    }
  }

  Future<void> _handleVerification() async {
    if (_documentIdController.text.isEmpty) {
      _showSnackBar(AppStrings.enterDocumentId, true);
      return;
    }

    setState(() => _isVerifying = true);

    try {
      final isVerified = await _documentService.verifyDocument(_documentIdController.text);

      setState(() {
        verificationHistory.add({
          'title': 'Document ${_documentIdController.text}',
          'status': isVerified ? 'Verified on Blockchain' : 'Not Found',
        });
      });

      _showSnackBar(
        isVerified ? 'Document verified on blockchain' : 'Document not found',
        !isVerified,
      );
      _documentIdController.clear();
    } catch (e) {
      _showSnackBar('Failed to verify document: ${e.toString()}', true);
    } finally {
      setState(() => _isVerifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: const Color(0xFF1E1E1E),
          appBar: AppBar(
            title: const Text('Document Verification Platform'),
            backgroundColor: const Color(0xFF2C2C2C),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Upload Section
                Card(
                  color: const Color(0xFF2C2C2C),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Upload Document',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _hashController,
                            decoration: const InputDecoration(
                              labelText: 'Document Hash',
                              labelStyle: TextStyle(color: Colors.grey),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.grey),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.blue),
                              ),
                            ),
                            style: const TextStyle(color: Colors.white),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _titleController,
                            decoration: const InputDecoration(
                              labelText: 'Document Title',
                              labelStyle: TextStyle(color: Colors.grey),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.grey),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.blue),
                              ),
                            ),
                            style: const TextStyle(color: Colors.white),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _isUploading ? null : _handleUpload,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                            ),
                            child: _isUploading
                                ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                                : const Text('Upload Document'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Verification Section
                Card(
                  color: const Color(0xFF2C2C2C),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Verify Document',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _documentIdController,
                          decoration: const InputDecoration(
                            labelText: 'Document ID',
                            labelStyle: TextStyle(color: Colors.grey),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.grey),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.blue),
                            ),
                          ),
                          style: const TextStyle(color: Colors.white),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _isVerifying ? null : _handleVerification,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          ),
                          child: _isVerifying
                              ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                              : const Text('Verify Document'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Status Display Section
                const Text(
                  'Verification History',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    itemCount: verificationHistory.length,
                    itemBuilder: (context, index) {
                      return Card(
                        color: const Color(0xFF2C2C2C),
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(
                            verificationHistory[index]['title'] ?? '',
                            style: const TextStyle(color: Colors.white),
                          ),
                          subtitle: Text(
                            verificationHistory[index]['status'] ?? '',
                            style: const TextStyle(color: Colors.grey),
                          ),
                          trailing: Icon(
                            verificationHistory[index]['status'] == 'Verified on Blockchain'
                                ? Icons.check_circle
                                : Icons.error,
                            color: verificationHistory[index]['status'] == 'Verified on Blockchain'
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_isUploading || _isVerifying)
          Container(
            color: Colors.black54,
            child: const Center(
              child: Card(
                color: Color(0xFF2C2C2C),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text(
                        'Processing...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  @override
  void dispose() {
    _hashController.dispose();
    _titleController.dispose();
    _documentIdController.dispose();
    _documentService.dispose();
    super.dispose();
  }
}