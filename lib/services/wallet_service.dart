import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart' as http;
import 'package:convert/convert.dart';

class WalletService extends ChangeNotifier {
  Web3Client? _ethClient;
  String? _privateKey;
  Credentials? _credentials;
  EthereumAddress? _address;
  bool _isConnected = false;

  String? get currentAddress => _address?.hex;
  bool get isConnected => _isConnected;
  Credentials? get credentials => _credentials;

  Future<void> initialize() async {
    try {
      final infuraUrl = 'https://sepolia.infura.io/v3/9aa3d95b3bc440fa88ea12eaa4456161';
      _ethClient = Web3Client(infuraUrl, http.Client());
      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing WalletService: $e');
      rethrow;
    }
  }

  Future<void> connect() async {
    try {
      if (_ethClient == null) await initialize();
      
      // In a real app, get the private key from secure storage
      // For demo purposes, we're using a hardcoded private key or .env file
      // NEVER use a real private key with funds in a production app
      _privateKey = dotenv.env['ETHEREUM_PRIVATE_KEY'] ?? 
                   '0x0000000000000000000000000000000000000000000000000000000000000001'; // Demo key
      
      _credentials = EthPrivateKey.fromHex(_privateKey!);
      _address = await _credentials!.extractAddress();
      _isConnected = true;
      
      notifyListeners();
      debugPrint('Wallet connected: ${_address?.hex}');
    } catch (e) {
      _isConnected = false;
      debugPrint('Error connecting wallet: $e');
      rethrow;
    }
  }

  Future<void> disconnect() async {
    _credentials = null;
    _address = null;
    _isConnected = false;
    notifyListeners();
    debugPrint('Wallet disconnected');
  }

  Future<String> getBalance() async {
    if (!_isConnected || _ethClient == null || _address == null) {
      throw Exception('Wallet not connected');
    }

    try {
      final balance = await _ethClient!.getBalance(_address!);
      return balance.getValueInUnit(EtherUnit.ether).toString();
    } catch (e) {
      debugPrint('Error getting balance: $e');
      rethrow;
    }
  }
  
  Future<String> signMessage(String message) async {
    if (!_isConnected || _credentials == null) {
      throw Exception('Wallet not connected');
    }
    
    try {
      final Uint8List messageBytes = Uint8List.fromList(message.codeUnits);
      final signature = await _credentials!.signPersonalMessage(messageBytes);
      return '0x${hex.encode(signature)}';
    } catch (e) {
      debugPrint('Error signing message: $e');
      rethrow;
    }
  }
  
  @override
  void dispose() {
    _ethClient?.dispose();
    super.dispose();
  }
}