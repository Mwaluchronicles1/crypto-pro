import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class NetworkConfig {
  // Constants for Ganache network
  static const int ganacheChainId = 1337;
  static const String ganacheRpcUrl = 'http://127.0.0.1:7545';
  static const String ganacheName = 'Ganache Local';
  static const String ganacheSymbol = 'ETH';
  static const String ganacheBlockExplorer = ''; // No block explorer for local Ganache
  
  // Method to help user add Ganache network to MetaMask
  static Future<void> addGanacheToMetaMask(BuildContext context) async {
    // Show dialog explaining what's happening
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Ganache to MetaMask'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'We need to add Ganache as a custom network in your MetaMask wallet.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Text('Please follow these steps:'),
              SizedBox(height: 8),
              Text('1. Open MetaMask'),
              Text('2. Tap on the network selector at the top'),
              Text('3. Scroll down and tap "Add network"'),
              Text('4. Choose "Add a network manually"'),
              Text('5. Enter the following details:'),
              SizedBox(height: 8),
              Text('Network Name: Ganache Local'),
              Text('RPC URL: http://127.0.0.1:7545'),
              Text('Chain ID: 1337'),
              Text('Currency Symbol: ETH'),
              SizedBox(height: 12),
              Text(
                'After adding the network, please select it and return to the app.',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('I\'ll do it manually'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              // Try to automatically add the network
              await _launchMetaMaskDeepLink();
            },
            child: const Text('Add to MetaMask'),
          ),
        ],
      ),
    );
  }
  
  // Try to automatically add Ganache to MetaMask using deep link
  static Future<void> _launchMetaMaskDeepLink() async {
    try {
      // Create the deep link URL (only works on some platforms and recent MetaMask versions)
      final deepLink = Uri.encodeFull(
        'https://metamask.app.link/dapp/add-chain?'
        'chainId=0x${ganacheChainId.toRadixString(16)}'
        '&chainName=${Uri.encodeComponent(ganacheName)}'
        '&rpcUrl=${Uri.encodeComponent(ganacheRpcUrl)}'
        '&nativeCurrency=${Uri.encodeComponent('{"name":"Ether","symbol":"ETH","decimals":18}')}'
      );
      
      // Try to launch the deep link
      final canLaunch = await canLaunchUrl(Uri.parse(deepLink));
      if (canLaunch) {
        await launchUrl(Uri.parse(deepLink), mode: LaunchMode.externalApplication);
      } else {
        // If deep link doesn't work, try to launch MetaMask directly
        final canLaunchApp = await canLaunchUrl(Uri.parse('metamask://'));
        if (canLaunchApp) {
          await launchUrl(Uri.parse('metamask://'), mode: LaunchMode.externalApplication);
        }
      }
    } catch (e) {
      debugPrint('Error launching MetaMask deep link: $e');
    }
  }
} 