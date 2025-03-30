import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:web3dart/web3dart.dart';
import 'package:flutter/foundation.dart';
import 'package:crypto_pro/utils/constants.dart';

class ContractService extends ChangeNotifier {
  final String _contractAddress;
  Web3Client? _client;
  DeployedContract? _contract;
  ContractFunction? _registerDocument;
  ContractFunction? _verifyDocument;
  ContractFunction? _getDocument;
  bool _isInitialized = false;
  
  ContractService({String? contractAddress}) 
      : _contractAddress = contractAddress ?? ContractConstants.contractAddress;
  
  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    try {
      // Connect to Ethereum node
      _client = Web3Client(
        'https://sepolia.infura.io/v3/9aa3d95b3bc440fa88ea12eaa4456161', // Use Sepolia testnet
        Client(),
      );
      
      debugPrint('Initializing contract at address: $_contractAddress');
      
      // This would load the actual ABI from assets in a real app
      const String abiJsonPlaceholder = '''
      [
        {
          "inputs": [
            {"internalType": "string", "name": "hash", "type": "string"},
            {"internalType": "string", "name": "metadata", "type": "string"}
          ],
          "name": "registerDocument",
          "outputs": [],
          "stateMutability": "nonpayable",
          "type": "function"
        },
        {
          "inputs": [
            {"internalType": "string", "name": "hash", "type": "string"},
            {"internalType": "bool", "name": "approved", "type": "bool"}
          ],
          "name": "verifyDocument",
          "outputs": [],
          "stateMutability": "nonpayable",
          "type": "function"
        },
        {
          "inputs": [
            {"internalType": "string", "name": "hash", "type": "string"}
          ],
          "name": "getDocument",
          "outputs": [
            {"internalType": "string", "name": "metadata", "type": "string"},
            {"internalType": "address", "name": "owner", "type": "address"},
            {"internalType": "uint256", "name": "timestamp", "type": "uint256"},
            {"internalType": "uint8", "name": "status", "type": "uint8"}
          ],
          "stateMutability": "view",
          "type": "function"
        }
      ]
      ''';
      
      // Initialize contract
      _contract = DeployedContract(
        ContractAbi.fromJson(abiJsonPlaceholder, 'DocumentVerification'),
        EthereumAddress.fromHex(_contractAddress),
      );
      
      // Get functions
      _registerDocument = _contract!.function('registerDocument');
      _verifyDocument = _contract!.function('verifyDocument');
      _getDocument = _contract!.function('getDocument');
      
      _isInitialized = true;
      debugPrint('Contract initialized successfully');
    } catch (e) {
      debugPrint('Error initializing contract: $e');
      rethrow;
    }
  }
  
  Future<void> registerDocument(String hash, String metadata, Credentials credentials) async {
    if (!_isInitialized) await initialize();
    
    try {
      await _client!.sendTransaction(
        credentials,
        Transaction.callContract(
          contract: _contract!,
          function: _registerDocument!,
          parameters: [hash, metadata],
        ),
        chainId: 11155111, // Sepolia chain ID
      );
      debugPrint('Document registered on blockchain: $hash');
    } catch (e) {
      debugPrint('Error registering document: $e');
      rethrow;
    }
  }
  
  Future<void> verifyDocument(String hash, bool approved, Credentials credentials) async {
    if (!_isInitialized) await initialize();
    
    try {
      await _client!.sendTransaction(
        credentials,
        Transaction.callContract(
          contract: _contract!,
          function: _verifyDocument!,
          parameters: [hash, approved],
        ),
        chainId: 11155111, // Sepolia chain ID
      );
      debugPrint('Document verified on blockchain: $hash (approved: $approved)');
    } catch (e) {
      debugPrint('Error verifying document: $e');
      rethrow;
    }
  }
  
  Future<Map<String, dynamic>?> getDocument(String hash) async {
    if (!_isInitialized) await initialize();
    
    try {
      final result = await _client!.call(
        contract: _contract!,
        function: _getDocument!,
        params: [hash],
      );
      
      if (result.isEmpty) return null;
      
      // Extract document data from the result
      final String metadata = result[0].toString();
      final String owner = (result[1] as EthereumAddress).hex;
      final BigInt timestamp = result[2] as BigInt;
      final int status = (result[3] as BigInt).toInt();
      
      return {
        'hash': hash,
        'title': metadata,
        'owner': owner,
        'timestamp': timestamp.toString(),
        'status': status,
      };
    } catch (e) {
      debugPrint('Error getting document: $e');
      // We're returning null instead of throwing because this might be a legitimate case
      // where the document doesn't exist on the blockchain
      return null;
    }
  }
  
  @override
  void dispose() {
    _client?.dispose();
    super.dispose();
  }
}