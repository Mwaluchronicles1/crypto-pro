import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:crypto_pro/services/wallet_connect_service.dart';
import 'package:crypto_pro/widgets/wallet_connect_qr_code.dart';

class WalletConnectButton extends StatefulWidget {
  const WalletConnectButton({super.key});

  @override
  State<WalletConnectButton> createState() => _WalletConnectButtonState();
}

class _WalletConnectButtonState extends State<WalletConnectButton> {
  bool _isConnecting = false;
  String? _wcUri;

  String _shortenAddress(String address) {
    if (address.length < 10) return address;
    return '${address.substring(0, 6)}...${address.substring(address.length - 4)}';
  }

  Future<void> _handleWalletConnection(BuildContext context, WalletConnectService walletService) async {
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
        setState(() {
          _isConnecting = true;
        });
        
        // Attempt to connect
        final connected = await walletService.connect();
        
        if (context.mounted) {
          if (walletService.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: ${walletService.errorMessage}'),
                backgroundColor: Colors.red,
              ),
            );
          } else if (walletService.isConnected) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Wallet connected successfully'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
        
        setState(() {
          _isConnecting = false;
          _wcUri = null;
        });
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
      
      setState(() {
        _isConnecting = false;
        _wcUri = null;
      });
    }
  }
  
  void _showQRCodeDialog(BuildContext context, String uri) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Connect Wallet'),
        content: SingleChildScrollView(
          child: WalletConnectQRCode(
            uri: uri,
            onCopied: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('WalletConnect URI copied to clipboard'),
                  backgroundColor: Colors.green,
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WalletConnectService>(
      builder: (context, walletService, _) {
        final connected = walletService.isConnected;
        final address = walletService.currentAddress;
        final chainName = walletService.currentNetwork;

        if (_isConnecting && _wcUri != null) {
          return ElevatedButton.icon(
            onPressed: () => _showQRCodeDialog(context, _wcUri!),
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('Scan QR Code'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              elevation: 2,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          );
        }

        return TextButton(
          onPressed: _isConnecting 
              ? null 
              : () => _handleWalletConnection(context, walletService),
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
          child: _isConnecting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      connected ? Icons.link : Icons.link_off,
                      color: connected ? Colors.green : Colors.grey,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      connected 
                          ? '${_shortenAddress(address ?? '')} ($chainName)'
                          : 'Connect Wallet',
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