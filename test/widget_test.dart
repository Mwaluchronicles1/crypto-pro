// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crypto_pro/main.dart';
import 'package:crypto_pro/services/document_service.dart';
import 'package:crypto_pro/services/wallet_service.dart';
import 'package:crypto_pro/services/contract_service.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('App renders without crashing', (WidgetTester tester) async {
    // Create mock services
    final walletService = WalletService();
    final contractService = ContractService();
    final documentService = DocumentService(walletService: walletService);
    
    // Build our app with MultiProvider for all services
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<WalletService>.value(value: walletService),
          ChangeNotifierProvider<ContractService>.value(value: contractService),
          ChangeNotifierProvider<DocumentService>.value(value: documentService),
        ],
        child: const MyApp(),
      ),
    );

    // Verify that our app renders without crashing
    expect(find.text('Document Verification'), findsOneWidget);
    // Additional test verifications could be added here
  });
}
