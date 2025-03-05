import 'package:flutter/foundation.dart';
import 'contract_service.dart';

class DocumentService {
  final ContractService _contractService;

  DocumentService() : _contractService = ContractService();

  Future<void> uploadDocument({
    required String hash,
    required String title,
  }) async {
    try {
      final txHash = await _contractService.registerDocument(hash, title);
      if (kDebugMode) {
        print('Document registered with transaction hash: $txHash');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error registering document: $e');
      }
      rethrow;
    }
  }

  Future<bool> verifyDocument(String documentId) async {
    try {
      final isVerified = await _contractService.verifyDocument(documentId);
      if (kDebugMode) {
        print('Document verification result: $isVerified');
      }
      return isVerified;
    } catch (e) {
      if (kDebugMode) {
        print('Error verifying document: $e');
      }
      rethrow;
    }
  }

  void dispose() {
    _contractService.dispose();
  }
}