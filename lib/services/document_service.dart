import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';
import 'package:crypto_pro/services/wallet_connect_service.dart';
import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart' as http;
import 'package:crypto_pro/services/contract_service.dart';

enum VerificationStatus {
  pending,
  approved,
  rejected
}

class Document {
  final String hash;
  final String title;
  final String owner;
  final DateTime timestamp;
  final bool exists;
  final VerificationStatus status;
  final List<String>? verifiers;
  final String? rejectionReason;

  Document({
    required this.hash,
    required this.title,
    required this.owner,
    required this.timestamp,
    this.exists = true,
    this.status = VerificationStatus.pending,
    this.verifiers,
    this.rejectionReason,
  });

  // Create from blockchain data
  factory Document.fromBlockchain(Map<String, dynamic> data) {
    return Document(
      hash: data['hash'] as String,
      title: data['title'] as String,
      owner: data['owner'] as String,
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        int.parse(data['timestamp']) * 1000,
      ),
      exists: data['exists'] as bool,
      status: VerificationStatus.values[data['status'] as int],
      verifiers: (data['verifiers'] as List<dynamic>?)?.cast<String>(),
      rejectionReason: data['rejectionReason'] as String?,
    );
  }

  // Check if document is verified
  bool get isVerified => status == VerificationStatus.approved;
  
  // Check if document is rejected
  bool get isRejected => status == VerificationStatus.rejected;

  String get statusString {
    switch (status) {
      case VerificationStatus.approved:
        return 'Approved';
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
      timestamp: DateTime.parse(json['timestamp']),
      exists: json['exists'] as bool,
      status: VerificationStatus.values[json['status'] as int],
      verifiers: json['verifiers'] as List<String>?,
      rejectionReason: json['rejectionReason'] as String?,
    );
  }

  factory Document.fromMap(Map<String, dynamic> map) {
    return Document(
      hash: map['hash'] as String,
      title: map['title'] as String,
      owner: map['owner'] as String,
      timestamp: DateTime.parse(map['timestamp']),
      exists: map['exists'] as bool,
      status: VerificationStatus.values[map['status'] as int],
      verifiers: map['verifiers'] as List<String>?,
      rejectionReason: map['rejectionReason'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hash': hash,
      'title': title,
      'owner': owner,
      'timestamp': timestamp.toIso8601String(),
      'exists': exists,
      'status': status.index,
      'verifiers': verifiers,
      'rejectionReason': rejectionReason,
    };
  }
}

class DocumentService extends ChangeNotifier {
  final ContractService _contractService;
  final WalletConnectService _walletService;
  final List<Document> _documents = [];
  bool _isLoading = false;
  String? _errorMessage;
  Web3Client? _ethClient;
  DeployedContract? _contract;
  bool _isDemoMode = false;
  
  DocumentService({
    required ContractService contractService,
    required WalletConnectService walletService,
  }) : _contractService = contractService,
       _walletService = walletService {
    _initializeWeb3();
  }

  List<Document> get documents => List.unmodifiable(_documents);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isDemoMode => _isDemoMode;

  Future<void> _initializeWeb3() async {
    try {
      // Initialize Web3 client (connecting to local Ganache or a testnet)
      _ethClient = Web3Client(
        'http://127.0.0.1:7545', // Ganache default URL
        http.Client(),
      );
      
      // Initialize contract service if needed
      if (!_contractService.isInitialized) {
        await _contractService.initialize();
      }
      
      debugPrint('Web3 client initialized');
    } catch (e) {
      debugPrint('Error initializing Web3: $e');
      _errorMessage = 'Failed to initialize blockchain connection: $e';
      _isDemoMode = true; // Fall back to demo mode
      notifyListeners();
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
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
    if (!_walletService.isConnected && !_isDemoMode) {
      _setError('Wallet not connected');
      return false;
    }

    _setLoading(true);
    _setError(null);

    try {
      if (_contractService.isInitialized && _walletService.isConnected) {
        // Try to use the blockchain if available
        await _contractService.registerDocument(hash, title);
      } else {
        // Fall back to demo mode
        _isDemoMode = true;
        // Simulate blockchain interaction
        await Future.delayed(const Duration(seconds: 1));
      }
      
      final newDocument = Document(
        hash: hash,
        title: title,
        owner: _walletService.currentAddress ?? 'Unknown',
        timestamp: DateTime.now(),
        status: VerificationStatus.pending,
      );
      
      _documents.add(newDocument);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to upload document: ${e.toString()}');
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
    if (!_walletService.isConnected && !_isDemoMode) {
      _setError('Wallet not connected');
      return false;
    }

    _setLoading(true);
    _setError(null);

    try {
      if (_contractService.isInitialized && _walletService.isConnected) {
        // Try to use the blockchain if available
        await _contractService.verifyDocument(documentHash, approved, reason);
      } else {
        // Fall back to demo mode
        _isDemoMode = true;
        // Simulate blockchain verification
        await Future.delayed(const Duration(seconds: 1));
      }
      
      final index = _documents.indexWhere((doc) => doc.hash == documentHash);
      if (index >= 0) {
        final document = _documents[index];
        final verifiedDocument = Document(
          hash: document.hash,
          title: document.title,
          owner: document.owner,
          timestamp: document.timestamp,
          status: approved ? VerificationStatus.approved : VerificationStatus.rejected,
          rejectionReason: approved ? null : reason,
        );
        
        _documents[index] = verifiedDocument;
        notifyListeners();
        return true;
      } else if (_isDemoMode) {
        // In demo mode, create a fake document if it doesn't exist
        final fakeDocument = Document(
          hash: documentHash,
          title: 'Sample Document',
          owner: _walletService.currentAddress ?? 'Unknown',
          timestamp: DateTime.now(),
          status: approved ? VerificationStatus.approved : VerificationStatus.rejected,
          rejectionReason: approved ? null : reason,
        );
        _documents.add(fakeDocument);
        notifyListeners();
        return true;
      } else {
        _setError('Document not found');
        return false;
      }
    } catch (e) {
      _setError('Failed to verify document: ${e.toString()}');
      debugPrint(_errorMessage);
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Get document details by hash
  Future<Map<String, dynamic>?> getDocument(String documentHash) async {
    _setLoading(true);
    _setError(null);
    
    try {
      // Try blockchain first if available
      if (_contractService.isInitialized) {
        final blockchainDocument = await _contractService.getDocument(documentHash);
        if (blockchainDocument != null) {
          return blockchainDocument;
        }
      }
      
      // Fall back to local data
      final index = _documents.indexWhere((doc) => doc.hash == documentHash);
      if (index >= 0) {
        final document = _documents[index];
        // Convert to map for UI consumption
        return {
          'hash': document.hash,
          'title': document.title,
          'owner': document.owner,
          'timestamp': document.timestamp.millisecondsSinceEpoch ~/ 1000,
          'status': document.status.index,
          'exists': true,
          'verifiers': document.verifiers,
          'rejectionReason': document.rejectionReason,
        };
      } else {
        // Check if we're in demo mode and create a fake document
        if (_isDemoMode || _documents.isEmpty) {
          // Create a mock document for demo purposes
          return {
            'hash': documentHash,
            'title': 'Sample Document',
            'owner': _walletService.currentAddress ?? 'Unknown',
            'timestamp': (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString(),
            'status': VerificationStatus.pending.index,
            'exists': true,
            'verifiers': [],
            'rejectionReason': null,
          };
        }
        return null;
      }
    } catch (e) {
      _setError('Failed to get document: ${e.toString()}');
      debugPrint(_errorMessage);
      return null;
    } finally {
      _setLoading(false);
    }
  }

  @override
  void dispose() {
    _ethClient?.dispose();
    super.dispose();
  }
}