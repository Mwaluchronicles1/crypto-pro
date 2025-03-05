import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:web3dart/web3dart.dart';

class ContractService {
  late Web3Client _client;
  late DeployedContract _contract;
  late ContractFunction _registerDocument;

  Future<void> initialize() async {
    // 1. Connect to Ganache
    _client = Web3Client('http://127.0.0.1:7545', Client());

    // 2. Load ABI
    String abiJson = await rootBundle.loadString('assets/contracts/DocumentVerification.json');
    final abi = jsonDecode(abiJson)['abi'];

    // 3. Initialize contract
    _contract = DeployedContract(
      ContractAbi.fromJson(abi, 'DocumentVerification'),
      EthereumAddress.fromHex('0x00d96B8ed99E154e676355c553482FD692A97c67'), // Use your deployed address
    );

    // 4. Get functions
    _registerDocument = _contract.function('registerDocument');
  }

  Future<void> registerDocument(String hash, String metadata) async {
    await _client.sendTransaction(
      // Use credentials (private key) from Ganache
      await _credentials.extractPrivateKey(),
      Transaction.callContract(
        contract: _contract,
        function: _registerDocument,
        parameters: [hash, metadata],
      ),
    );
  }
}

class _credentials {
  static extractPrivateKey() {}
}