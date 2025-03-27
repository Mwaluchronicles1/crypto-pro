import 'package:http/http.dart';
import 'package:web3dart/web3dart.dart';
import 'package:flutter/services.dart';

// Security Constants
const int MAX_HASH_LENGTH = 64; // For SHA-256 hashes
const int MIN_TITLE_LENGTH = 3;
const int MAX_TITLE_LENGTH = 100;
const int MAX_REASON_LENGTH = 200;
const int MAX_RETRIES = 3;

class DocumentService {
  late Web3Client _client;
  late DeployedContract _contract;
  late Credentials _credentials;
  bool _initialized = false;

  // Input validation patterns
  final RegExp _hexRegExp = RegExp(r'^[a-fA-F0-9]+$');
  final RegExp _injectionChars = RegExp(r'[<>{}]');

  // Add these missing methods:
  String _sanitizeInput(String input) {
    return input.replaceAll(_injectionChars, '').trim();
  }

  void _validateHash(String hash) {
    if (hash.isEmpty) throw ArgumentError('Document hash cannot be empty');
    if (hash.length != MAX_HASH_LENGTH) {
      throw ArgumentError('Document hash must be exactly $MAX_HASH_LENGTH characters');
    }
    if (!_hexRegExp.hasMatch(hash)) {
      throw ArgumentError('Document hash must be hexadecimal');
    }
  }

  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      await initialize();
    }
  }

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      _client = Web3Client('http://127.0.0.1:7545', Client());
      _credentials = await _client.credentialsFromPrivateKey(
        '0xb4bb9508c8faa1c53a5d8c2a3d0dcaaa1a402100305ce89a88ae82effd86db86',
      );

      final abi = await rootBundle.loadString('assets/contracts/DocumentVerification.json');
      _contract = DeployedContract(
        ContractAbi.fromJson(abi, 'DocumentVerification'),
        EthereumAddress.fromHex('0x00d96B8ed99E154e676355c553482FD692A97c67'),
      );
      _initialized = true;
    } catch (e) {
      _initialized = false;
      throw Exception('Initialization failed: $e');
    }
  }

  Future<T> _executeWithRetry<T>(Future<T> Function() operation) async {
    int attempts = 0;
    while (attempts < MAX_RETRIES) {
      try {
        return await operation();
      } catch (e) {
        attempts++;
        if (attempts == MAX_RETRIES) rethrow;
        await Future.delayed(Duration(seconds: 1 << attempts));
      }
    }
    throw Exception('Max retries exceeded');
  }

  Future<void> uploadDocument({
    required String hash,
    required String title,
  }) async {
    final sanitizedHash = _sanitizeInput(hash);
    final sanitizedTitle = _sanitizeInput(title);

    _validateHash(sanitizedHash);
    _validateTitle(sanitizedTitle);

    await _executeWithRetry(() async {
      await registerDocument(hash: sanitizedHash, title: sanitizedTitle);
    });
  }

  void _validateTitle(String title) {
    if (title.isEmpty) throw ArgumentError('Document title cannot be empty');
    if (title.length < MIN_TITLE_LENGTH) {
      throw ArgumentError('Title must be at least $MIN_TITLE_LENGTH characters');
    }
    if (title.length > MAX_TITLE_LENGTH) {
      throw ArgumentError('Title cannot exceed $MAX_TITLE_LENGTH characters');
    }
  }

  Future<void> registerDocument({
    required String hash,
    required String title,
  }) async {
    await _ensureInitialized();
    final function = _contract.function('registerDocument');

    await _client.sendTransaction(
      _credentials,
      Transaction.callContract(
        contract: _contract,
        function: function,
        parameters: [hash, title],
        maxGas: 100000,
      ),
    );
  }

  Future<bool> verifyDocument(
      String documentId, {
        required bool approved,
        required String hash,
        required String reason,
      }) async {
    final sanitizedHash = _sanitizeInput(hash);
    final sanitizedReason = _sanitizeInput(reason);

    _validateHash(sanitizedHash);
    _validateReason(sanitizedReason);

    await _executeWithRetry(() async {
      await _performVerification(
        hash: sanitizedHash,
        approved: approved,
        reason: sanitizedReason,
      );
    });

    return approved;
  }

  void _validateReason(String reason) {
    if (reason.isEmpty) throw ArgumentError('Reason cannot be empty');
    if (reason.length > MAX_REASON_LENGTH) {
      throw ArgumentError('Reason cannot exceed $MAX_REASON_LENGTH characters');
    }
  }

  Future<void> _performVerification({
    required String hash,
    required bool approved,
    required String reason,
  }) async {
    await _ensureInitialized();
    final function = _contract.function('verifyDocument');

    await _client.sendTransaction(
      _credentials,
      Transaction.callContract(
        contract: _contract,
        function: function,
        parameters: [hash, approved, reason],
        maxGas: 100000,
      ),
    );
  }

  Future<Map<String, dynamic>> getDocument(String hash) async {
    final sanitizedHash = _sanitizeInput(hash);
    _validateHash(sanitizedHash);

    return await _executeWithRetry<Map<String, dynamic>>(() async {
      return await getDocumentDetails(sanitizedHash);
    });
  }

  Future<Map<String, dynamic>> getDocumentDetails(String hash) async {
    await _ensureInitialized();
    final function = _contract.function('getDocument');

    final result = await _client.call(
      contract: _contract,
      function: function,
      params: [hash],
    );

    return {
      'hash': result[0],
      'title': result[1],
      'owner': result[2],
      'timestamp': result[3],
      'verified': result[5] == 1,
      'status': _parseStatus(result[5]),
      'reason': result[7] ?? '',
    };
  }

  String _parseStatus(dynamic status) {
    switch (status) {
      case 0: return 'Pending';
      case 1: return 'Approved';
      case 2: return 'Rejected';
      default: return 'Unknown';
    }
  }

  Future<void> requestVerification(String hash) async {
    final sanitizedHash = _sanitizeInput(hash);
    _validateHash(sanitizedHash);

    await _executeWithRetry(() async {
      await _ensureInitialized();
      final function = _contract.function('requestVerification');

      await _client.sendTransaction(
        _credentials,
        Transaction.callContract(
          contract: _contract,
          function: function,
          parameters: [sanitizedHash],
          maxGas: 100000,
        ),
      );
    });
  }

  Future<void> addVerifier(String address) async {
    final sanitizedAddress = _sanitizeInput(address);

    await _executeWithRetry(() async {
      await _ensureInitialized();
      final function = _contract.function('addVerifier');

      await _client.sendTransaction(
        _credentials,
        Transaction.callContract(
          contract: _contract,
          function: function,
          parameters: [EthereumAddress.fromHex(sanitizedAddress)],
          maxGas: 100000,
        ),
      );
    });
  }

  void dispose() {
    _client.dispose();
    _initialized = false;
  }
}