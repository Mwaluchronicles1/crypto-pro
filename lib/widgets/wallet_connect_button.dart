import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/wallet_service.dart';

class WalletConnectButton extends StatelessWidget {
  const WalletConnectButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<WalletService>(
      builder: (context, walletService, _) {
        final isConnected = walletService.isConnected;
        final address = walletService.currentAddress;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isConnected && address != null)
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Text(
                  '${address.substring(0, 6)}...${address.substring(address.length - 4)}',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            IconButton(
              icon: Icon(
                isConnected ? Icons.account_balance_wallet : Icons.wallet,
                color: isConnected ? Colors.green : Colors.white,
              ),
              onPressed: () => _handleWalletConnection(context, walletService),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleWalletConnection(BuildContext context, WalletService walletService) async {
    try {
      if (walletService.isConnected) {
        await walletService.disconnect();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Wallet disconnected')),
        );
      } else {
        await walletService.connect();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Wallet connected successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to connect wallet: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
} 