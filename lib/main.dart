import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:crypto_pro/services/wallet_service.dart';
import 'package:crypto_pro/services/document_service.dart';
import 'package:crypto_pro/screens/document_verification_screen.dart';
import 'package:crypto_pro/theme/app_theme.dart';
import 'package:crypto_pro/utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final walletService = WalletService();
  final documentService = DocumentService();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<WalletService>(create: (_) => walletService),
        ChangeNotifierProvider<DocumentService>(create: (_) => documentService),
      ],
      child: MyApp(
        documentService: documentService,
        walletService: walletService,
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  final DocumentService documentService;
  final WalletService walletService;

  const MyApp({
    super.key,
    required this.documentService,
    required this.walletService,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: AppStrings.appTitle,
      theme: AppTheme.darkTheme,
      home: DocumentVerificationScreen(
        documentService: documentService,
        walletService: walletService,
      ),
    );
  }
}