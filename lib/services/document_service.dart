import 'dart:convert';
import 'package:web3dart/web3dart.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import './wallet_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/verification_status.dart';

class DocumentService extends ChangeNotifier {
  final WalletService _walletService;
  late Web3Client _client;
  late DeployedContract _contract;
  bool _initialized = false;
  bool _isLoading = false;
  String? _errorMessage;
  final Map<String, bool> _operationLoading = {
    'upload': false,
    'verify': false,
    'fetch': false,
  };

  // Input validation patterns
  final RegExp _hexRegExp = RegExp(r'^[a-fA-F0-9]+$');
  final RegExp _injectionChars = RegExp(r'[<>{}]');

  // Move constants inside class as final fields
  final int maxHashLength = 64;
  final int minTitleLength = 3;
  final int maxTitleLength = 100;
  final int maxReasonLength = 200;
  final int maxRetries = 3;

  DocumentService() : _walletService = WalletService();

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isUploading => _operationLoading['upload'] ?? false;
  bool get isVerifying => _operationLoading['verify'] ?? false;
  bool get isFetching => _operationLoading['fetch'] ?? false;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _setOperationLoading(String operation, bool value) {
    _operationLoading[operation] = value;
    _isLoading = _operationLoading.values.any((loading) => loading);
    notifyListeners();
  }

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Create Web3Client
      _client = Web3Client('http://127.0.0.1:7545', Client());

      // Load contract ABI
      final abiString = await rootBundle.loadString('assets/contracts/DocumentVerification.json');
      final abiJson = jsonDecode(abiString);
      final contractAddress = EthereumAddress.fromHex('0x00d96B8ed99E154e676355c553482FD692A97c67');

      _contract = DeployedContract(
        ContractAbi.fromJson(jsonEncode(abiJson['abi']), 'DocumentVerification'),
        contractAddress,
      );

      _initialized = true;
    } catch (e) {
      _initialized = false;
      throw Exception('Initialization failed: $e');
    }
  }

  Future<Map<String, dynamic>?> getDocument(String hash) async {
    try {
      _setOperationLoading('fetch', true);
      _setError(null);

      final sanitizedHash = _sanitizeInput(hash);
      _validateHash(sanitizedHash);

      await _ensureInitialized();

      final function = _contract.function('getDocument');
      final result = await _client.call(
        contract: _contract,
        function: function,
        params: [sanitizedHash],
      );

      if (result.isEmpty) return null;

      final document = _processDocumentData(result);
      document['verifiers'] = _convertVerifiersToList(document['verifiers'] as List<dynamic>);
      return document;
    } catch (e) {
      _setError(e.toString());
      return null;
    } finally {
      _setOperationLoading('fetch', false);
    }
  }

  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      await initialize();
    }
  }

  String _sanitizeInput(String input) {
    return input.replaceAll(_injectionChars, '').trim();
  }

  void _validateHash(String hash) {
    if (hash.isEmpty) throw ArgumentError('Document hash cannot be empty');
    if (hash.length != maxHashLength) {
      throw ArgumentError('Document hash must be exactly $maxHashLength characters');
    }
    if (!_hexRegExp.hasMatch(hash)) {
      throw ArgumentError('Document hash must be hexadecimal');
    }
  }

  void _validateTitle(String title) {
    if (title.isEmpty) throw ArgumentError('Document title cannot be empty');
    if (title.length < minTitleLength) {
      throw ArgumentError('Title must be at least $minTitleLength characters');
    }
    if (title.length > maxTitleLength) {
      throw ArgumentError('Title cannot exceed $maxTitleLength characters');
    }
  }

  Future<T> _executeWithRetry<T>(Future<T> Function() operation) async {
    int attempts = 0;
    while (attempts < maxRetries) {
      try {
        return await operation();
      } catch (e) {
        attempts++;
        if (attempts == maxRetries) rethrow;
        await Future.delayed(Duration(seconds: 1 << attempts));
      }
    }
    throw Exception('Max retries exceeded');
  }

  @override
  void dispose() {
    _client.dispose();
    super.dispose();
  }

  Future<bool> uploadDocument({
    required String hash,
    required String title,
  }) async {
    try {
      _setOperationLoading('upload', true);
      _setError(null);

      final sanitizedHash = _sanitizeInput(hash);
      final sanitizedTitle = _sanitizeInput(title);

      _validateHash(sanitizedHash);
      _validateTitle(sanitizedTitle);

      await _ensureInitialized();

      if (!_walletService.isConnected) {
        throw Exception('Wallet not connected');
      }

      final credentials = await _walletService.getCredentials();
      final function = _contract.function('registerDocument');
      
      final transaction = await _client.sendTransaction(
        credentials as Credentials,
        Transaction.callContract(
          contract: _contract,
          function: function,
          parameters: [sanitizedHash, sanitizedTitle],
          maxGas: 100000,
        ),
      );

      final receipt = await _waitForTransaction(transaction);
      if (receipt == null) {
        throw Exception('Failed to get transaction receipt');
      }
      return _hasEvent(receipt, 'DocumentRegistered');
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setOperationLoading('upload', false);
    }
  }

  Future<void> requestVerification(String hash) async {
    final sanitizedHash = _sanitizeInput(hash);
    _validateHash(sanitizedHash);

    await _executeWithRetry(() async {
      await _ensureInitialized();

      if (!_walletService.isConnected) {
        throw Exception('Wallet not connected');
      }

      final credentials = await _walletService.getCredentials();
      final function = _contract.function('requestVerification');
      
      final transaction = await _client.sendTransaction(
        credentials as Credentials,
        Transaction.callContract(
          contract: _contract,
          function: function,
          parameters: [sanitizedHash],
          maxGas: 100000,
        ),
        chainId: 1337,
      );

      final receipt = await _waitForTransaction(transaction);
      if (receipt == null) {
        throw Exception('Failed to get transaction receipt');
      }
    });
  }

  // Helper method to check for events
  bool _hasEvent(TransactionReceipt receipt, String eventName) {
    final event = _contract.event(eventName);
    return receipt.logs.any((log) => 
      log.topics != null && 
      log.topics!.isNotEmpty && 
      log.topics!.first == event.signature
    );
  }

  // Add this helper method for transaction handling
  Future<TransactionReceipt?> _waitForTransaction(String transactionHash) async {
    int attempts = 0;
    const maxAttempts = 30;
    
    while (attempts < maxAttempts) {
      final receipt = await _client.getTransactionReceipt(transactionHash);
      if (receipt != null) {
        return receipt;
      }
      await Future.delayed(const Duration(seconds: 1));
      attempts++;
    }
    
    throw Exception('Transaction not mined within timeout period');
  }

  Future<bool> verifyDocument(
    String documentHash, {
    required bool approved,
    required String reason,
  }) async {
    try {
      _setOperationLoading('verify', true);
      _setError(null);

      final sanitizedHash = _sanitizeInput(documentHash);
      final sanitizedReason = _sanitizeInput(reason);

      _validateHash(sanitizedHash);
      if (!approved && sanitizedReason.isEmpty) {
        throw ArgumentError('Rejection reason required');
      }

      await _ensureInitialized();

      if (!_walletService.isConnected) {
        throw Exception('Wallet not connected');
      }

      final credentials = await _walletService.getCredentials();
      final function = _contract.function('verifyDocument');
      
      final transaction = await _client.sendTransaction(
        credentials as Credentials,
        Transaction.callContract(
          contract: _contract,
          function: function,
          parameters: [sanitizedHash, approved, sanitizedReason],
          maxGas: 100000,
        ),
      );

      final receipt = await _waitForTransaction(transaction);
      if (receipt == null) {
        throw Exception('Failed to get transaction receipt');
      }
      return _hasEvent(receipt, 'DocumentVerified');
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setOperationLoading('verify', false);
    }
  }

  Future<List<Map<String, dynamic>>> getDocumentHistory(String hash) async {
    final sanitizedHash = _sanitizeInput(hash);
    _validateHash(sanitizedHash);

    return await _executeWithRetry(() async {
      await _ensureInitialized();

      final function = _contract.function('getDocumentHistory');
      final result = await _client.call(
        contract: _contract,
        function: function,
        params: [sanitizedHash],
      );

      if (result.isEmpty) return [];

      return (result[0] as List).map((item) {
        return {
          'verifier': (item[0] as EthereumAddress).hexEip55,
          'timestamp': (item[1] as BigInt).toString(),
          'approved': item[2] as bool,
          'reason': item[3].toString(),
        };
      }).toList();
    });
  }

  // Add method to check if user can verify documents
  Future<bool> canVerifyDocuments() async {
    await _ensureInitialized();

    if (!_walletService.isConnected) {
      return false;
    }

    final credentials = await _walletService.getCredentials();
    final address = credentials.address;
    
    final function = _contract.function('verifiers');
    final result = await _client.call(
      contract: _contract,
      function: function,
      params: [address],
    );

    return result[0] as bool;
  }

  Future<VerificationStatus> getVerificationStatus(String hash) async {
    final sanitizedHash = _sanitizeInput(hash);
    _validateHash(sanitizedHash);

    return await _executeWithRetry(() async {
      await _ensureInitialized();

      final function = _contract.function('getVerificationStatus');
      final result = await _client.call(
        contract: _contract,
        function: function,
        params: [sanitizedHash],
      );

      return VerificationStatus.fromInt(result[0] as int);
    });
  }

  Future<bool> isVerifier(String address) async {
    await _ensureInitialized();

    final function = _contract.function('verifiers');
    final result = await _client.call(
      contract: _contract,
      function: function,
      params: [EthereumAddress.fromHex(address)],
    );

    return result[0] as bool;
  }

  List<String> _convertVerifiersToList(List<dynamic> verifiers) {
    return verifiers
        .map((addr) => (addr as EthereumAddress).hexEip55)
        .toList();
  }

  String _getStatusString(int status) {
    switch (status) {
      case 0:
        return 'Pending';
      case 1:
        return 'Approved';
      case 2:
        return 'Rejected';
      default:
        return 'Unknown';
    }
  }

  Map<String, dynamic> _processDocumentData(List<dynamic> result) {
    return {
      'hash': result[0].toString(),
      'title': result[1].toString(),
      'owner': (result[2] as EthereumAddress).hexEip55,
      'timestamp': (result[3] as BigInt).toString(),
      'exists': result[4] as bool,
      'status': VerificationStatus.fromInt(result[5] as int),
      'verifiers': result[6] as List<dynamic>,
      'rejectionReason': result[7].toString(),
    };
  }
}