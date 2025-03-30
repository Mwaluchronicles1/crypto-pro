import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';
import 'package:crypto_pro/services/wallet_service.dart';
import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart' as http;

enum VerificationStatus {
  pending,
  approved,
  rejected
}

class Document {
  final String hash;
  final String title;
  final String owner;
  final String timestamp;
  final VerificationStatus status;

  Document({
    required this.hash,
    required this.title,
    required this.owner,
    required this.timestamp,
    required this.status,
  });

  String get statusString {
    switch (status) {
      case VerificationStatus.approved:
        return 'Verified';
      case VerificationStatus.rejected:
        return 'Rejected';
      case VerificationStatus.pending:
      default:
        return 'Pending';
    }
  }

  factory Document.fromJson(Map<String, dynamic> json) {
    return Document(
      hash: json['hash'] as String,
      title: json['title'] as String,
      owner: json['owner'] as String,
      timestamp: json['timestamp'].toString(),
      status: VerificationStatus.values[json['status'] as int],
    );
  }

  factory Document.fromMap(Map<String, dynamic> map) {
    return Document(
      hash: map['hash'] as String,
      title: map['title'] as String,
      owner: map['owner'] as String,
      timestamp: map['timestamp'].toString(),
      status: map['status'] is VerificationStatus 
          ? map['status'] as VerificationStatus 
          : VerificationStatus.values[map['status'] as int],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hash': hash,
      'title': title,
      'owner': owner,
      'timestamp': timestamp,
      'status': status.index,
    };
  }
}

class DocumentService extends ChangeNotifier {
  final WalletService _walletService;
  final List<Document> _documents = [];
  bool _isLoading = false;
  String? _errorMessage;
  Web3Client? _ethClient;
  DeployedContract? _contract;
  
  DocumentService({required WalletService walletService}) : _walletService = walletService {
    _initializeWeb3();
  }

  List<Document> get documents => List.unmodifiable(_documents);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> _initializeWeb3() async {
    try {
      // Initialize Web3 client (connecting to local Ganache or a testnet)
      _ethClient = Web3Client(
        'http://127.0.0.1:7545', // Ganache default URL
        http.Client(),
      );
      
      // Load contract details would go here in a real implementation
      // This is just a stub for now
      debugPrint('Web3 client initialized');
    } catch (e) {
      debugPrint('Error initializing Web3: $e');
      _errorMessage = 'Failed to initialize blockchain connection: $e';
      notifyListeners();
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  String generateDocumentHash(String content) {
    final bytes = utf8.encode(content);
    final digest = sha256.convert(bytes);
    return '0x${digest.toString()}';
  }

  // Updated to match the call pattern in the UI
  Future<bool> uploadDocument({
    required String hash,
    required String title,
  }) async {
    if (!_walletService.isConnected) {
      throw Exception('Wallet not connected');
    }

    _setLoading(true);
    _errorMessage = null;

    try {
      // This would be a real blockchain interaction in production
      await Future.delayed(const Duration(seconds: 1));
      
      final newDocument = Document(
        hash: hash,
        title: title,
        owner: _walletService.currentAddress ?? 'Unknown',
        timestamp: (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString(),
        status: VerificationStatus.pending,
      );
      
      _documents.add(newDocument);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to upload document: ${e.toString()}';
      debugPrint(_errorMessage);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Updated to match the call pattern in the UI
  Future<bool> verifyDocument(
    String documentHash, {
    required bool approved,
    required String reason,
  }) async {
    if (!_walletService.isConnected) {
      throw Exception('Wallet not connected');
    }

    _setLoading(true);
    _errorMessage = null;

    try {
      // This would be a real blockchain verification in production
      await Future.delayed(const Duration(seconds: 1));
      
      final index = _documents.indexWhere((doc) => doc.hash == documentHash);
      if (index >= 0) {
        final document = _documents[index];
        final verifiedDocument = Document(
          hash: document.hash,
          title: document.title,
          owner: document.owner,
          timestamp: document.timestamp,
          status: approved ? VerificationStatus.approved : VerificationStatus.rejected,
        );
        
        _documents[index] = verifiedDocument;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Document not found';
        return false;
      }
    } catch (e) {
      _errorMessage = 'Failed to verify document: ${e.toString()}';
      debugPrint(_errorMessage);
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Added to match the method called in the UI
  Future<Map<String, dynamic>?> getDocument(String documentHash) async {
    _setLoading(true);
    _errorMessage = null;
    
    try {
      // This would fetch from blockchain in production
      await Future.delayed(const Duration(milliseconds: 500));
      
      final index = _documents.indexWhere((doc) => doc.hash == documentHash);
      if (index >= 0) {
        final document = _documents[index];
        // Convert to map for UI consumption
        return {
          'hash': document.hash,
          'title': document.title,
          'owner': document.owner,
          'timestamp': document.timestamp,
          'status': document.status,
        };
      } else {
        // Check if we're in demo mode and create a fake document
        if (_documents.isEmpty) {
          // Create a mock document for demo purposes
          return {
            'hash': documentHash,
            'title': 'Sample Document',
            'owner': _walletService.currentAddress ?? 'Unknown',
            'timestamp': (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString(),
            'status': VerificationStatus.pending,
          };
        }
        return null;
      }
    } catch (e) {
      _errorMessage = 'Failed to get document: ${e.toString()}';
      debugPrint(_errorMessage);
      return null;
    } finally {
      _setLoading(false);
    }
  }
}