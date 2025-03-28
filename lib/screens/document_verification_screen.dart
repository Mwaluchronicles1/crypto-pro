import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/wallet_service.dart';
import '../services/document_service.dart';
import '../widgets/wallet_connect_button.dart';
import '../utils/constants.dart';

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

  List<Map<String, dynamic>> verificationHistory = [];
  Map<String, dynamic>? _selectedDocument;

  bool _isUploading = false;
  bool _isVerifying = false;
  bool _isFetching = false;
  bool _isLoading = false;
  String? _error;

  final DocumentService _documentService = DocumentService();

  @override
  void dispose() {
    _hashController.dispose();
    _titleController.dispose();
    _documentIdController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, bool isError) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
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

        final document = {
          'hash': _hashController.text,
          'title': _titleController.text,
          'status': 'Registered',
          'timestamp': DateTime.now().toIso8601String(),
          'verified': false,
        };

        setState(() {
          verificationHistory.insert(0, document);
        });

        _showSnackBar('Document registered successfully', false);
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
      _showSnackBar('Please enter a document ID', true);
      return;
    }

    setState(() => _isVerifying = true);

    try {
      final isVerified = await _documentService.verifyDocument(
        _documentIdController.text,
        approved: true, // Set based on your verification logic
        hash: _documentIdController.text,
        reason: 'Manual verification', // Set appropriate reason
      );

      final updatedDoc = {
        'hash': _documentIdController.text,
        'status': isVerified ? 'Verified' : 'Rejected',
        'timestamp': DateTime.now().toIso8601String(),
        'verified': isVerified,
      };

      setState(() {
        verificationHistory.insert(0, updatedDoc);
      });

      _showSnackBar(
        isVerified ? 'Document verified' : 'Document rejected',
        !isVerified,
      );
    } catch (e) {
      _showSnackBar('Failed to verify document: ${e.toString()}', true);
    } finally {
      setState(() => _isVerifying = false);
    }
  }

  Future<void> _showDocumentDetails(String hash) async {
    setState(() {
      _isFetching = true;
      _selectedDocument = null;
    });

    try {
      final details = await _documentService.getDocument(hash);
      setState(() => _selectedDocument = details);

      showDialog(
        context: context,
        builder: (context) => _buildDocumentDialog(details),
      );
    } catch (e) {
      _showSnackBar('Failed to fetch document details', true);
    } finally {
      setState(() => _isFetching = false);
    }
  }

  Widget _buildDocumentDialog(Map<String, dynamic> doc) {
    return AlertDialog(
      backgroundColor: const Color(0xFF2C2C2C),
      title: const Text('Document Details', style: TextStyle(color: Colors.white)),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDetailItem('Hash:', doc['hash'] ?? ''),
            _buildDetailItem('Title:', doc['title'] ?? ''),
            _buildDetailItem('Owner:', doc['owner']?.toString() ?? ''),
            _buildDetailItem('Timestamp:',
                DateTime.tryParse(doc['timestamp']?.toString() ?? '')?.toLocal().toString() ?? ''),
            _buildDetailItem('Status:',
                doc['verified'] == true ? 'Verified' : 'Not Verified'),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(int index) {
    final item = verificationHistory[index];
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: const Color(0xFF2C2C2C),
      child: InkWell(
        onTap: () => _showDocumentDetails(item['hash']),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(
                item['verified'] == true ? Icons.check_circle : Icons.error,
                color: item['verified'] == true ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['title'] ?? item['hash'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item['status'],
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 12,
                      ),
                    ),
                    if (item['timestamp'] != null)
                      Text(
                        '${DateTime.tryParse(item['timestamp'])?.toLocal().toString().split('.')[0]}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 10,
                        ),
                      ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        title: const Text(
          'Document Verification',
          style: TextStyle(fontSize: 20),
        ),
        backgroundColor: const Color(0xFF2C2C2C),
        actions: const [
          WalletConnectButton(),
        ],
      ),
      body: Consumer2<WalletService, DocumentService>(
        builder: (context, walletService, documentService, _) {
          if (_isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (!walletService.isConnected) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2C2C2C),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.account_balance_wallet,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Connect your wallet to continue',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const WalletConnectButton(),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          return SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: true,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Upload Section
                        _buildUploadSection(),
                        const SizedBox(height: 20),
                        
                        // Verification Section
                        _buildVerificationSection(),
                        const SizedBox(height: 20),
                        
                        // History Section
                        _buildHistorySection(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildUploadSection() {
    return Card(
      color: const Color(0xFF2C2C2C),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Register Document',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _hashController,
                decoration: InputDecoration(
                  labelText: 'Document Hash',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Document Title',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isUploading ? null : _handleUpload,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isUploading
                      ? const CircularProgressIndicator()
                      : const Text('Register Document'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVerificationSection() {
    return Card(
      color: const Color(0xFF2C2C2C),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Verify Document',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _documentIdController,
              decoration: InputDecoration(
                labelText: 'Document Hash',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isVerifying ? null : _handleVerification,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isVerifying
                        ? const CircularProgressIndicator()
                        : const Text('Verify'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (_documentIdController.text.isNotEmpty) {
                        _showDocumentDetails(_documentIdController.text);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Details'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Verification History',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: verificationHistory.length,
          itemBuilder: (context, index) => _buildHistoryItem(index),
        ),
      ],
    );
  }
}