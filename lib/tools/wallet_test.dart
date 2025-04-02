import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:crypto_pro/services/wallet_connect_service.dart';
import 'package:provider/provider.dart';
import 'package:crypto_pro/utils/network_config.dart';

/// Test screen for debugging wallet connection issues
class WalletTestScreen extends StatefulWidget {
  const WalletTestScreen({super.key});

  @override
  State<WalletTestScreen> createState() => _WalletTestScreenState();
}

class _WalletTestScreenState extends State<WalletTestScreen> {
  String _message = '';
  bool _isTesting = false;
  
  @override
  Widget build(BuildContext context) {
    final walletService = Provider.of<WalletConnectService>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wallet Connection Test'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'MetaMask Status',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Connected: ${walletService.isConnected}'),
                    Text('Address: ${walletService.currentAddress ?? 'Not connected'}'),
                    Text('Network: ${walletService.currentNetwork}'),
                    Text('Chain ID: ${walletService.chainId ?? 'Unknown'}'),
                    if (walletService.errorMessage != null) 
                      Text(
                        'Error: ${walletService.errorMessage}',
                        style: const TextStyle(color: Colors.red),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'MetaMask Network',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => NetworkConfig.addGanacheToMetaMask(context),
                      icon: const Icon(Icons.add_circle_outline),
                      label: const Text('Add Ganache to MetaMask'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'If MetaMask is not connecting to the correct network, use this button to add Ganache.',
                      style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Launch Tests',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _testMetaMaskLaunch,
                      child: const Text('Test MetaMask Launch'),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => _testWalletconnect(walletService),
                      child: const Text('Test WalletConnect'),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => _testDevWallet(walletService),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      child: const Text('Connect Development Wallet'),
                    ),
                    const SizedBox(height: 8),
                    if (walletService.isConnected)
                      ElevatedButton(
                        onPressed: () => _disconnect(walletService),
                        child: const Text('Disconnect'),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Results',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      constraints: const BoxConstraints(
                        minHeight: 100,
                      ),
                      width: double.infinity,
                      child: _isTesting
                          ? const Center(child: CircularProgressIndicator())
                          : Text(_message),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Test if MetaMask can be launched directly
  Future<void> _testMetaMaskLaunch() async {
    setState(() {
      _isTesting = true;
      _message = 'Testing MetaMask launch...';
    });
    
    try {
      // Direct URL test
      final canLaunchDirect = await canLaunchUrl(Uri.parse('metamask://'));
      
      // URI scheme test
      final testUri = 'metamask://wc?uri=wc:00000000000000000000000000000000';
      final canLaunchUri = await canLaunchUrl(Uri.parse(testUri));
      
      setState(() {
        _message = 'MetaMask direct launch: ${canLaunchDirect ? 'SUPPORTED' : 'NOT SUPPORTED'}\n'
            'MetaMask URI scheme: ${canLaunchUri ? 'SUPPORTED' : 'NOT SUPPORTED'}\n\n'
            'If both are NOT SUPPORTED, you need to install MetaMask or use a different device.';
        _isTesting = false;
      });
    } catch (e) {
      setState(() {
        _message = 'Error testing MetaMask launch: $e';
        _isTesting = false;
      });
    }
  }
  
  // Test WalletConnect initialization and connection
  Future<void> _testWalletconnect(WalletConnectService service) async {
    setState(() {
      _isTesting = true;
      _message = 'Testing WalletConnect initialization...';
    });
    
    try {
      // Reset service state
      if (service.isConnected) {
        await service.disconnect();
      }
      
      // Initialize service
      await service.initialize();
      
      setState(() {
        _message += '\nWalletConnect initialized successfully.';
        _message += '\nTesting connection...';
      });
      
      // Try to connect
      final connected = await service.connect();
      
      setState(() {
        _message += '\nConnection result: ${connected ? 'SUCCESS' : 'FAILED'}';
        if (service.errorMessage != null) {
          _message += '\nError: ${service.errorMessage}';
        }
        _isTesting = false;
      });
    } catch (e) {
      setState(() {
        _message += '\nError: $e';
        _isTesting = false;
      });
    }
  }
  
  // Test the development wallet connection for assignments
  Future<void> _testDevWallet(WalletConnectService service) async {
    setState(() {
      _isTesting = true;
      _message = 'Connecting to development wallet...';
    });
    
    try {
      // Disconnect if already connected
      if (service.isConnected) {
        await service.disconnect();
      }
      
      // Connect to development wallet
      final connected = await service.connectDevelopmentWallet();
      
      setState(() {
        _message += '\nDevelopment wallet connection: ${connected ? 'SUCCESS' : 'FAILED'}';
        if (connected) {
          _message += '\nAddress: ${service.currentAddress}';
          _message += '\nNetwork: ${service.currentNetwork}';
          _message += '\nChain ID: ${service.chainId}';
          _message += '\n\nNOTE: This is a test wallet for development only.';
        } else if (service.errorMessage != null) {
          _message += '\nError: ${service.errorMessage}';
        }
        _isTesting = false;
      });
    } catch (e) {
      setState(() {
        _message += '\nError: $e';
        _isTesting = false;
      });
    }
  }
  
  // Disconnect wallet
  Future<void> _disconnect(WalletConnectService service) async {
    setState(() {
      _isTesting = true;
      _message = 'Disconnecting wallet...';
    });
    
    try {
      await service.disconnect();
      setState(() {
        _message = 'Wallet disconnected successfully.';
        _isTesting = false;
      });
    } catch (e) {
      setState(() {
        _message = 'Error disconnecting wallet: $e';
        _isTesting = false;
      });
    }
  }
} 