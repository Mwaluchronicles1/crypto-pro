import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:crypto_pro/services/wallet_service.dart';
import 'package:crypto_pro/services/document_service.dart';
import 'package:crypto_pro/services/contract_service.dart';
import 'package:crypto_pro/screens/document_verification_screen.dart';
import 'package:crypto_pro/theme/app_theme.dart';
import 'package:crypto_pro/utils/constants.dart';

Future<void> main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    
    // Load environment variables
    await dotenv.load(fileName: ".env");

    final walletService = WalletService();
    await walletService.initialize();
    
    final contractService = ContractService();
    await contractService.initialize();
    
    final documentService = DocumentService(walletService: walletService);

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<WalletService>(create: (_) => walletService),
          ChangeNotifierProvider<DocumentService>(create: (_) => documentService),
          ChangeNotifierProvider<ContractService>(create: (_) => contractService),
        ],
        child: const MyApp(),
      ),
    );
  } catch (e, stackTrace) {
    debugPrint('Error during app initialization: $e');
    debugPrint('Stack trace: $stackTrace');
    rethrow;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final documentService = Provider.of<DocumentService>(context);
    final walletService = Provider.of<WalletService>(context);
    
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: AppStrings.appTitle,
      theme: AppTheme.darkTheme,
      home: Builder(
        builder: (context) {
          try {
            return DocumentVerificationScreen(
              documentService: documentService,
              walletService: walletService,
            );
          } catch (e) {
            debugPrint('Error building DocumentVerificationScreen: $e');
            return Scaffold(
              body: Center(
                child: Text(
                  'Error initializing app: $e',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            );
          }
        },
      ),
    );
  }
}