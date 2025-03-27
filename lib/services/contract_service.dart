import 'package:flutter/services.dart';
import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/io.dart';
import 'dart:convert';

class ContractService {
  static const String rpcUrl = 'http://127.0.0.1:7545'; // Ganache RPC URL
  static const String wsUrl = 'ws://127.0.0.1:7545';
  static const String privateKey = '0xb4bb9508c8faa1c53a5d8c2a3d0dcaaa1a402100305ce89a88ae82effd86db86'; // Replace with your private key

  final Web3Client _client;
  final DeployedContract _contract;
  late String _abiCode;
  late EthereumAddress _contractAddress;
  late Credentials _credentials;
  late ContractFunction _registerDocument;
  late ContractFunction _verifyDocument;

  ContractService(this._client, this._contract) {
    initialSetup();
  }

  Future<void> initialSetup() async {
    // Get contract ABI and address
    await getAbi();
    await getCredentials();
  }

  Future<void> getAbi() async {
    // Read the contract ABI
    String abiStringFile = await rootBundle.loadString('assets/DocumentVerification.json');
    _contractAddress = EthereumAddress.fromHex('0x00d96B8ed99E154e676355c553482FD692A97c67'); // Replace with your contract address
    _abiCode = abiStringFile;
  }

  Future<void> getCredentials() async {
    _credentials = EthPrivateKey.fromHex(privateKey);
  }

  Future<String> registerDocument(String hash, String title) async {
    try {
      // Call the register document function
      final result = await _client.sendTransaction(
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
      final result = await _client.call(
        contract: _contract,
        function: _verifyDocument,
        params: [documentId],
      );
      return result[0] as bool;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<dynamic>> getDocument(String hash) async {
    try {
      // Get the function from the contract
      final function = _contract.function('getDocument');
      
      // Call the function
      final result = await _client.call(
        contract: _contract,
        function: function,
        params: [hash],
      );
      
      return result;
    } catch (e) {
      throw Exception('Failed to get document: $e');
    }
  }

  void dispose() {
    _client.dispose();
  }
}