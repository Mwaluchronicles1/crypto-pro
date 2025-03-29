import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/wallet_service.dart';
import '../services/document_service.dart';
import '../widgets/wallet_connect_button.dart';
import '../models/verification_status.dart';
import '../models/document.dart';

class DocumentVerificationScreen extends StatefulWidget {
  final DocumentService documentService;
  final WalletService walletService;

  const DocumentVerificationScreen({
    super.key,
    required this.documentService,
    required this.walletService,
  });

  @override
  State<DocumentVerificationScreen> createState() => _DocumentVerificationScreenState();
}

class _DocumentVerificationScreenState extends State<DocumentVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _hashController = TextEditingController();
  final _titleController = TextEditingController();
  final _verifyHashController = TextEditingController();

  List<Map<String, dynamic>> verificationHistory = [];

  @override
  void dispose() {
    _hashController.dispose();
    _titleController.dispose();
    _verifyHashController.dispose();
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

  Future<void> _handleUpload(DocumentService documentService) async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final success = await documentService.uploadDocument(
        hash: _hashController.text,
        title: _titleController.text,
      );

      if (success && mounted) {
        setState(() {
          verificationHistory.insert(0, {
            'hash': _hashController.text,
            'title': _titleController.text,
            'status': 'Registered',
            'timestamp': DateTime.now().toIso8601String(),
            'verified': false,
          });
        });
        _titleController.clear();
        _hashController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleVerification() async {
    final documentHash = _verifyHashController.text;
    if (documentHash.isEmpty) {
      _showSnackBar('Please enter a document hash', true);
      return;
    }

    try {
      final verified = await widget.documentService.verifyDocument(
        documentHash,
        approved: true,
        reason: 'Document verified',
      );

      if (verified) {
        _showSnackBar('Document verified successfully', false);
        // Optionally refresh document details
        await _showDocumentDetails(documentHash);
      } else {
        _showSnackBar('Verification failed', true);
      }
    } catch (e) {
      _showSnackBar('Error verifying document: $e', true);
    }
  }

  Future<void> _showDocumentDetails(String documentHash) async {
    if (documentHash.isEmpty) {
      _showSnackBar('Please enter a document hash', true);
      return;
    }

    try {
      final details = await widget.documentService.getDocument(documentHash);
      
      if (mounted && details != null) {
        showDialog(
          context: context,
          builder: (context) => _buildDocumentDialog(details),
        );
      } else if (mounted) {
        _showSnackBar('Document not found', true);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Failed to fetch document details: $e', true);
      }
    }
  }

  String _getStatusString(VerificationStatus status) {
    switch (status) {
      case VerificationStatus.pending:
        return 'Pending';
      case VerificationStatus.approved:
        return 'Approved';
      case VerificationStatus.rejected:
        return 'Rejected';
    }
  }

  Widget _buildDocumentDialog(Map<String, dynamic> documentData) {
    // Convert the raw map to a Document object
    final document = Document.fromMap(documentData);
    
    return AlertDialog(
      backgroundColor: const Color(0xFF2C2C2C),
      title: const Text(
        'Document Details',
        style: TextStyle(color: Colors.white),
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDetailItem('Hash:', document.hash),
            _buildDetailItem('Title:', document.title),
            _buildDetailItem('Owner:', document.owner),
            _buildDetailItem(
              'Timestamp:',
              DateTime.fromMillisecondsSinceEpoch(
                int.parse(document.timestamp) * 1000,
              ).toString(),
            ),
            _buildDetailItem('Status:', _getStatusString(document.status)),
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

  Widget _buildDetailItem(String label, String value, {Key? key}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      key: key,
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

  Widget _buildUploadSection(DocumentService documentService) {
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
                  onPressed: documentService.isUploading ? null : () => _handleUpload(documentService),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: documentService.isUploading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Register Document'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVerificationSection(DocumentService documentService) {
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
              controller: _verifyHashController,
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
                    onPressed: documentService.isVerifying ? null : _handleVerification,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: documentService.isVerifying
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Verify'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: documentService.isFetching
                        ? null
                        : () => _showDocumentDetails(_verifyHashController.text),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: documentService.isFetching
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Details'),
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

  @override
  Widget build(BuildContext context) {
    return Consumer2<DocumentService, WalletService>(
      builder: (context, documentService, walletService, _) {
        final isWalletConnected = walletService.isConnected;
        final errorMessage = documentService.errorMessage;
        final isLoading = documentService.isLoading;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Document Verification'),
            actions: const [
              WalletConnectButton(),
            ],
          ),
          body: Stack(
            children: [
              if (!isWalletConnected)
                const Center(
                  child: Text('Please connect your wallet to continue'),
                )
              else
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (errorMessage != null)
                        ErrorBanner(message: errorMessage),
                      _buildUploadSection(documentService),
                      const SizedBox(height: 16),
                      _buildVerificationSection(documentService),
                      if (verificationHistory.isNotEmpty)
                        _buildHistorySection(),
                    ],
                  ),
                ),
              if (isLoading)
                const LoadingOverlay(),
            ],
          ),
        );
      },
    );
  }
}

// Loading overlay widget
class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      child: const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Processing...'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Error banner widget
class ErrorBanner extends StatelessWidget {
  final String message;

  const ErrorBanner({
    Key? key,
    required this.message,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      margin: const EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        color: Colors.red.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: Colors.red.shade700),
            ),
          ),
        ],
      ),
    );
  }
}