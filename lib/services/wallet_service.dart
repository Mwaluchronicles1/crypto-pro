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
  String? _errorMessage;

  String? get currentAddress => _address?.hex;
  bool get isConnected => _isConnected;
  Credentials? get credentials => _credentials;
  String? get errorMessage => _errorMessage;

  Future<void> initialize() async {
    try {
      final infuraUrl = 'https://sepolia.infura.io/v3/9aa3d95b3bc440fa88ea12eaa4456161';
      _ethClient = Web3Client(infuraUrl, http.Client());
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to initialize WalletService: $e';
      debugPrint('Error initializing WalletService: $e');
      notifyListeners();
      // Do not rethrow - just log and continue
    }
  }

  Future<bool> connect() async {
    try {
      if (_ethClient == null) {
        await initialize();
        if (_ethClient == null) {
          _errorMessage = 'Failed to initialize Web3 client';
          notifyListeners();
          return false;
        }
      }
      
      // In a real app, get the private key from secure storage
      // For demo purposes, we're using a hardcoded private key or .env file
      // NEVER use a real private key with funds in a production app
      _privateKey = dotenv.env['ETHEREUM_PRIVATE_KEY'] ?? 
                   '0x0000000000000000000000000000000000000000000000000000000000000001'; // Demo key
      
      _credentials = EthPrivateKey.fromHex(_privateKey!);
      _address = await _credentials!.extractAddress();
      _isConnected = true;
      _errorMessage = null;
      
      notifyListeners();
      debugPrint('Wallet connected: ${_address?.hex}');
      return true;
    } catch (e) {
      _isConnected = false;
      _errorMessage = 'Failed to connect wallet: $e';
      debugPrint('Error connecting wallet: $e');
      notifyListeners();
      return false;
    }
  }

  Future<void> disconnect() async {
    _credentials = null;
    _address = null;
    _isConnected = false;
    notifyListeners();
    debugPrint('Wallet disconnected');
  }

  Future<String?> getBalance() async {
    if (!_isConnected || _ethClient == null || _address == null) {
      _errorMessage = 'Wallet not connected';
      notifyListeners();
      return null;
    }

    try {
      final balance = await _ethClient!.getBalance(_address!);
      return balance.getValueInUnit(EtherUnit.ether).toString();
    } catch (e) {
      _errorMessage = 'Failed to get balance: $e';
      debugPrint('Error getting balance: $e');
      notifyListeners();
      return null;
    }
  }
  
  Future<String?> signMessage(String message) async {
    if (!_isConnected || _credentials == null) {
      _errorMessage = 'Wallet not connected';
      notifyListeners();
      return null;
    }
    
    try {
      final Uint8List messageBytes = Uint8List.fromList(message.codeUnits);
      final signature = await _credentials!.signPersonalMessage(messageBytes);
      return '0x${hex.encode(signature)}';
    } catch (e) {
      _errorMessage = 'Failed to sign message: $e';
      debugPrint('Error signing message: $e');
      notifyListeners();
      return null;
    }
  }
  
  @override
  void dispose() {
    _ethClient?.dispose();
    super.dispose();
  }
}