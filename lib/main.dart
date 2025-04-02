import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:crypto_pro/services/wallet_connect_service.dart';
import 'package:crypto_pro/services/document_service.dart';
import 'package:crypto_pro/services/contract_service.dart';
import 'package:crypto_pro/screens/document_verification_screen.dart';
import 'package:crypto_pro/theme/app_theme.dart';
import 'package:crypto_pro/utils/constants.dart';
import 'package:crypto_pro/tools/wallet_test.dart';

Future<void> main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    
    // Initialize services
    final walletService = WalletConnectService();
    
    // Clear any previous session state and initialize fresh
    try {
      await walletService.initialize();
      debugPrint('WalletConnect service initialized successfully');
    } catch (walletError) {
      debugPrint('Non-fatal error initializing WalletConnect: $walletError');
      // Continue even if wallet service has issues
    }
    
    final contractService = ContractService(
      walletService: walletService,
    );
    
    try {
      await contractService.initialize();
      debugPrint('Contract service initialized successfully');
    } catch (contractError) {
      debugPrint('Non-fatal error initializing contract service: $contractError');
      // Continue even if contract service has issues
    }
    
    final documentService = DocumentService(
      walletService: walletService,
      contractService: contractService,
    );

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<WalletConnectService>(create: (_) => walletService),
          ChangeNotifierProvider<ContractService>(create: (_) => contractService),
          ChangeNotifierProvider<DocumentService>(create: (_) => documentService),
        ],
        child: const MyApp(),
      ),
    );
  } catch (e, stackTrace) {
    debugPrint('Error during app initialization: $e');
    debugPrint('Stack trace: $stackTrace');
    // Show error UI instead of crashing
    runApp(
      MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.black,
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Application Error',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'An error occurred during initialization: $e',
                    style: const TextStyle(color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
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
    final documentService = Provider.of<DocumentService>(context);
    final walletService = Provider.of<WalletConnectService>(context);
    
    // Sync the chain ID between wallet and contract service
    if (walletService.isConnected && walletService.chainId != null) {
      final contractService = Provider.of<ContractService>(context, listen: false);
      contractService.updateNetworkId(walletService.chainId!);
    }
    
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
      routes: {
        '/wallet_test': (context) => const WalletTestScreen(),
      },
    );
  }
}