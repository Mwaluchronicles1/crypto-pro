import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:crypto_pro/services/wallet_service.dart';

class WalletConnectButton extends StatelessWidget {
  const WalletConnectButton({super.key});

  String _shortenAddress(String address) {
    if (address.length < 10) return address;
    return '${address.substring(0, 6)}...${address.substring(address.length - 4)}';
  }

  Future<void> _handleWalletConnection(BuildContext context, WalletService walletService) async {
    try {
      if (walletService.isConnected) {
        await walletService.disconnect();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Wallet disconnected'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        await walletService.connect();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Wallet connected successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WalletService>(
      builder: (context, walletService, _) {
        final connected = walletService.isConnected;
        final address = walletService.currentAddress;

        return TextButton(
          onPressed: () => _handleWalletConnection(context, walletService),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            side: BorderSide(
              color: connected ? Colors.green.withAlpha(200) : Colors.grey.withAlpha(200),
              width: 1,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                connected ? Icons.link : Icons.link_off,
                color: connected ? Colors.green : Colors.grey,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                connected ? _shortenAddress(address ?? '') : 'Connect Wallet',
                style: TextStyle(
                  color: connected ? Colors.green : Colors.grey,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
} 