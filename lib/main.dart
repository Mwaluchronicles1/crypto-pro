import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:crypto_pro/services/wallet_service.dart';
import 'package:crypto_pro/services/document_service.dart';
import 'package:crypto_pro/screens/document_verification_screen.dart';
import 'package:crypto_pro/theme/app_theme.dart';
import 'package:crypto_pro/utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Create services
    final walletService = WalletService();
    final documentService = DocumentService(); // Remove the parameter since DocumentService creates its own WalletService

    // Initialize document service
    await documentService.initialize();

    runApp(
      MultiProvider(
        providers: [
          Provider<WalletService>(create: (_) => walletService),
          Provider<DocumentService>(create: (_) => documentService),
        ],
        child: const MyApp(),
      ),
    );
  } catch (e) {
    print('Initialization error: $e'); // Add logging for debugging
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Initialization failed: $e'),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: AppStrings.appTitle,
      theme: AppTheme.darkTheme,
      home: const DocumentVerificationScreen(),
    );
  }
}