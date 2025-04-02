import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:web3dart/web3dart.dart';
import 'package:flutter/foundation.dart';
import 'package:crypto_pro/utils/constants.dart';
import 'package:crypto_pro/services/wallet_connect_service.dart';

class ContractService extends ChangeNotifier {
  final String _contractAddress;
  Web3Client? _client;
  DeployedContract? _contract;
  Map<String, ContractFunction>? _functions;
  bool _isInitialized = false;
  String? _errorMessage;
  final WalletConnectService? _walletService;
  
  ContractService({
    String? contractAddress,
    this.networkId = 11155111, // Default to Sepolia
    WalletConnectService? walletService,
  }) : _contractAddress = contractAddress ?? ContractConstants.contractAddress,
       _walletService = walletService;
  
  bool get isInitialized => _isInitialized;
  String? get errorMessage => _errorMessage;
  int networkId;
  
  Map<int, String> networkRpcUrls = {
    1: 'https://mainnet.infura.io/v3/9aa3d95b3bc440fa88ea12eaa4456161', // Ethereum Mainnet
    11155111: 'https://sepolia.infura.io/v3/9aa3d95b3bc440fa88ea12eaa4456161', // Sepolia
    137: 'https://polygon-rpc.com', // Polygon
    56: 'https://bsc-dataseed.binance.org/', // BNB Chain
  };

  Future<void> initialize() async {
    try {
      // Connect to Ethereum node based on network ID
      final rpcUrl = networkRpcUrls[networkId] ?? networkRpcUrls[11155111]!;
      _client = Web3Client(rpcUrl, Client());
      
      debugPrint('Initializing contract at address: $_contractAddress on network: $networkId');
      
      // Load the contract ABI from assets
      final abiString = await rootBundle.loadString('assets/contracts/DocumentVerification.json');
      final jsonABI = jsonDecode(abiString);
      final abi = jsonABI['abi'];
      
      // Initialize contract
      _contract = DeployedContract(
        ContractAbi.fromJson(jsonEncode(abi), 'DocumentVerification'),
        EthereumAddress.fromHex(_contractAddress),
      );
      
      // Get all functions
      _functions = {};
      if (_contract != null) {
        for (var function in _contract!.functions) {
          _functions![function.name] = function;
        }
      }
      
      _isInitialized = true;
      _errorMessage = null;
      debugPrint('Contract initialized successfully with ${_functions?.length} functions');
    } catch (e) {
      _errorMessage = 'Contract initialization failed: $e';
      debugPrint('Error initializing contract: $e');
      _isInitialized = false;
    }
    notifyListeners();
  }
  
  Future<void> registerDocument(String hash, String metadata) async {
    if (!_isInitialized) {
      try {
        await initialize();
      } catch (e) {
        debugPrint('Failed to initialize before document registration: $e');
        _errorMessage = 'Failed to initialize blockchain: $e';
        notifyListeners();
        return;
      }
    }
    
    if (_walletService == null || !_walletService!.isConnected) {
      _errorMessage = 'Wallet not connected';
      notifyListeners();
      return;
    }
    
    try {
      final function = _functions!['registerDocument'];
      if (function == null) {
        throw Exception('Function registerDocument not found in contract');
      }
      
      // For WalletConnect, we need to encode the transaction data
      final data = function.encodeCall([hash, metadata]);
      
      // Convert Uint8List to hex string for WalletConnect
      final String hexData = '0x${bytesToHex(data)}';
      
      // Send via WalletConnect
      final txHash = await _walletService!.sendTransaction(
        to: _contractAddress,
        value: BigInt.zero,
        data: hexData,
      );
      
      if (txHash == null) {
        throw Exception('Transaction rejected by user');
      }
      
      debugPrint('Document registered on blockchain: $hash, tx: $txHash');
    } catch (e) {
      _errorMessage = 'Document registration failed: $e';
      debugPrint('Error registering document: $e');
      notifyListeners();
    }
  }
  
  Future<void> verifyDocument(String hash, bool approved, String reason) async {
    if (!_isInitialized) {
      try {
        await initialize();
      } catch (e) {
        debugPrint('Failed to initialize before document verification: $e');
        _errorMessage = 'Failed to initialize blockchain: $e';
        notifyListeners();
        return;
      }
    }
    
    if (_walletService == null || !_walletService!.isConnected) {
      _errorMessage = 'Wallet not connected';
      notifyListeners();
      return;
    }
    
    try {
      final function = _functions!['verifyDocument'];
      if (function == null) {
        throw Exception('Function verifyDocument not found in contract');
      }
      
      // For WalletConnect, we need to encode the transaction data
      final data = function.encodeCall([hash, approved, reason]);
      
      // Convert Uint8List to hex string for WalletConnect
      final String hexData = '0x${bytesToHex(data)}';
      
      // Send via WalletConnect
      final txHash = await _walletService!.sendTransaction(
        to: _contractAddress,
        value: BigInt.zero,
        data: hexData,
      );
      
      if (txHash == null) {
        throw Exception('Transaction rejected by user');
      }
      
      debugPrint('Document verified on blockchain: $hash (approved: $approved), tx: $txHash');
    } catch (e) {
      _errorMessage = 'Document verification failed: $e';
      debugPrint('Error verifying document: $e');
      notifyListeners();
    }
  }
  
  Future<Map<String, dynamic>?> getDocument(String hash) async {
    if (!_isInitialized) {
      try {
        await initialize();
      } catch (e) {
        debugPrint('Failed to initialize before getting document: $e');
        _errorMessage = 'Failed to initialize blockchain: $e';
        notifyListeners();
        return null;
      }
    }
    
    try {
      final function = _functions!['getDocument'];
      if (function == null) {
        throw Exception('Function getDocument not found in contract');
      }
      
      final result = await _client!.call(
        contract: _contract!,
        function: function,
        params: [hash],
      );
      
      if (result.isEmpty) return null;
      
      // Extract document data from the result based on new contract
      final String resultHash = result[0].toString();
      final String title = result[1].toString();
      final EthereumAddress owner = result[2] as EthereumAddress;
      final BigInt timestamp = result[3] as BigInt;
      final bool exists = result[4] as bool;
      final int status = (result[5] as BigInt).toInt();
      final List<dynamic> verifiers = result[6] as List<dynamic>;
      final String rejectionReason = result[7].toString();
      
      return {
        'hash': resultHash,
        'title': title,
        'owner': owner.hex,
        'timestamp': timestamp.toString(),
        'exists': exists,
        'status': status,
        'verifiers': verifiers.map((v) => (v as EthereumAddress).hex).toList(),
        'rejectionReason': rejectionReason,
      };
    } catch (e) {
      _errorMessage = 'Failed to get document: $e';
      debugPrint('Error getting document: $e');
      notifyListeners();
      return null;
    }
  }
  
  // Update network ID when chain changes
  void updateNetworkId(int newNetworkId) {
    if (networkId != newNetworkId) {
      networkId = newNetworkId;
      _isInitialized = false;
      initialize();
    }
  }
  
  // Helper method to convert bytes to hex string
  String bytesToHex(Uint8List bytes) {
    return bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join('');
  }
  
  @override
  void dispose() {
    _client?.dispose();
    super.dispose();
  }
}