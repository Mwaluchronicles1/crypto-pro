import 'package:flutter/services.dart';
import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/io.dart';

class ContractService {
  static const String rpcUrl = 'http://127.0.0.1:7545'; // Ganache RPC URL
  static const String wsUrl = 'ws://127.0.0.1:7545';
  static const String privateKey = '0xb4bb9508c8faa1c53a5d8c2a3d0dcaaa1a402100305ce89a88ae82effd86db86'; // Replace with your private key

  late Web3Client _web3client;
  late String _abiCode;
  late EthereumAddress _contractAddress;
  late Credentials _credentials;
  late DeployedContract _contract;
  late ContractFunction _registerDocument;
  late ContractFunction _verifyDocument;

  ContractService() {
    initialSetup();
  }

  Future<void> initialSetup() async {
    // Initialize Web3Client
    _web3client = Web3Client(
      rpcUrl,
      http.Client(),
      socketConnector: () => IOWebSocketChannel.connect(wsUrl).cast<String>(),
    );

    // Get contract ABI and address
    await getAbi();
    await getCredentials();
    await getDeployedContract();
  }

  Future<void> getAbi() async {
    // Read the contract ABI
    String abiStringFile = await rootBundle.loadString('assets/DocumentVerification.json');
    _contractAddress = EthereumAddress.fromHex('YOUR_CONTRACT_ADDRESS'); // Replace with your contract address
    _abiCode = abiStringFile;
  }

  Future<void> getCredentials() async {
    _credentials = EthPrivateKey.fromHex(privateKey);
  }

  Future<void> getDeployedContract() async {
    // Get the contract
    _contract = DeployedContract(
      ContractAbi.fromJson(_abiCode, 'DocumentVerification'),
      _contractAddress,
    );

    // Get contract functions
    _registerDocument = _contract.function('registerDocument');
    _verifyDocument = _contract.function('verifyDocument');
  }

  Future<String> registerDocument(String hash, String title) async {
    try {
      // Call the register document function
      final result = await _web3client.sendTransaction(
        _credentials,
        Transaction.callContract(
          contract: _contract,
          function: _registerDocument,
          parameters: [hash, title],
        ),
        chainId: 1337, // Ganache chain ID
      );
      return result;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> verifyDocument(String documentId) async {
    try {
      // Call the verify document function
      final result = await _web3client.call(
        contract: _contract,
        function: _verifyDocument,
        params: [documentId],
      );
      return result[0] as bool;
    } catch (e) {
      rethrow;
    }
  }

  void dispose() {
    _web3client.dispose();
  }
}