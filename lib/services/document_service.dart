import 'dart:convert';
import 'package:web3dart/web3dart.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import './wallet_service.dart';

// Security Constants
const int MAX_HASH_LENGTH = 64;
const int MIN_TITLE_LENGTH = 3;
const int MAX_TITLE_LENGTH = 100;
const int MAX_REASON_LENGTH = 200;
const int MAX_RETRIES = 3;

class DocumentService {
  final WalletService _walletService;
  late Web3Client _client;
  late DeployedContract _contract;
  bool _initialized = false;

  // Input validation patterns
  final RegExp _hexRegExp = RegExp(r'^[a-fA-F0-9]+$');
  final RegExp _injectionChars = RegExp(r'[<>{}]');

  DocumentService() : _walletService = WalletService();

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

  Future<Map<String, dynamic>> getDocument(String hash) async {
    final sanitizedHash = _sanitizeInput(hash);
    _validateHash(sanitizedHash);

    return await _executeWithRetry(() async {
      await _ensureInitialized();

      final function = _contract.function('getDocument');
      final result = await _client.call(
        contract: _contract,
        function: function,
        params: [sanitizedHash],
      );

      // Handle empty result
      if (result.isEmpty) {
        return {
          'hash': '',
          'title': '',
          'owner': '0x0000000000000000000000000000000000000000',
          'timestamp': '0',
          'exists': false,
          'verified': false,
        };
      }

      // Convert List<dynamic> to Map<String, dynamic>
      return {
        'hash': result[0].toString(),
        'title': result[1].toString(),
        'owner': (result[2] as EthereumAddress).hexEip55,
        'timestamp': (result[3] as BigInt).toString(),
        'exists': result[4] as bool,
        'verified': result[5] as bool,
      };
    });
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
    if (hash.length != MAX_HASH_LENGTH) {
      throw ArgumentError('Document hash must be exactly $MAX_HASH_LENGTH characters');
    }
    if (!_hexRegExp.hasMatch(hash)) {
      throw ArgumentError('Document hash must be hexadecimal');
    }
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

  void dispose() {
    _client.dispose();
    _initialized = false;
  }

  verifyDocument(String text, {required bool approved, required String hash, required String reason}) {}

  Future<void> uploadDocument({
    required String hash,
    required String title,
  }) async {
    final sanitizedHash = _sanitizeInput(hash);
    final sanitizedTitle = _sanitizeInput(title);

    _validateHash(sanitizedHash);
    _validateTitle(sanitizedTitle);

    await _executeWithRetry(() async {
      await _ensureInitialized();

      if (!_walletService.isConnected) {
        throw Exception('Wallet not connected');
      }

      final credentials = await _walletService.getCredentials();
      final function = _contract.function('registerDocument');
      
      await _client.sendTransaction(
        credentials,
        Transaction.callContract(
          contract: _contract,
          function: function,
          parameters: [sanitizedHash, sanitizedTitle],
          maxGas: 100000,
        ),
      );
    });
  }
}