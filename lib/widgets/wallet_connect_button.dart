import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:crypto_pro/services/wallet_connect_service.dart';
import 'package:crypto_pro/widgets/wallet_connect_qr_code.dart';
import 'dart:async';

class WalletConnectButton extends StatefulWidget {
  const WalletConnectButton({super.key});

  @override
  State<WalletConnectButton> createState() => _WalletConnectButtonState();
}

class _WalletConnectButtonState extends State<WalletConnectButton> {
  bool _isConnecting = false;
  
  String _shortenAddress(String address) {
    if (address.length < 10) return address;
    return '${address.substring(0, 6)}...${address.substring(address.length - 4)}';
  }

  Future<void> _handleWalletConnection(BuildContext context, WalletConnectService walletService) async {
    try {
      setState(() {
        _isConnecting = true;
      });
      
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
        // Set a timeout for the connection process
        bool connectTimeoutReached = false;
        
        // Start a timeout timer
        Timer timeoutTimer = Timer(const Duration(seconds: 45), () {
          connectTimeoutReached = true;
          setState(() {
            _isConnecting = false;
          });
          
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Connection is taking too long. Try again or check your wallet.'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 5),
              ),
            );
          }
        });
        
        // Attempt to connect
        final connected = await walletService.connect();
        
        // If we have a URI and still connecting, show the QR code dialog
        if (walletService.wcUri != null && _isConnecting && !connectTimeoutReached) {
          if (context.mounted) {
            _showQRCodeDialog(context, walletService.wcUri!);
          }
        }
        
        // Cancel timeout timer if not triggered yet
        if (!connectTimeoutReached) {
          timeoutTimer.cancel();
          
          if (context.mounted) {
            if (walletService.errorMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error: ${walletService.errorMessage}'),
                  backgroundColor: Colors.red,
                ),
              );
            } else if (connected) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Wallet connected successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          }
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
    } finally {
      if (mounted) {
        setState(() {
          _isConnecting = false;
        });
      }
    }
  }
  
  void _showQRCodeDialog(BuildContext context, String uri) {
    showDialog(
      context: context,
      barrierDismissible: false, // User must tap button to close dialog
      builder: (context) => AlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Connect Wallet'),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                Navigator.of(context).pop();
                final walletService = Provider.of<WalletConnectService>(context, listen: false);
                _handleWalletConnection(context, walletService);
              },
              tooltip: 'Retry connection',
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Scan this QR code with your MetaMask app or copy the link below.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              WalletConnectQRCode(
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
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (mounted) {
                setState(() {
                  _isConnecting = false;
                });
              }
            },
            child: const Text('Cancel'),
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
        final errorMessage = walletService.errorMessage;
        final isGanache = walletService.chainId == 1337;
        
        // If there's an error message and we're not connecting, show it on hover
        Widget connectionButton = TextButton(
          onPressed: _isConnecting 
              ? null 
              : () => _handleWalletConnection(context, walletService),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            side: BorderSide(
              color: connected 
                  ? (isGanache ? Colors.green.withAlpha(200) : Colors.orange.withAlpha(200)) 
                  : (errorMessage != null ? Colors.orange.withAlpha(200) : Colors.grey.withAlpha(200)),
              width: 1,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: _isConnecting
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      walletService.wcUri != null ? 'Open Wallet' : 'Connecting...',
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ],
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      connected 
                          ? (isGanache ? Icons.link : Icons.warning)
                          : (errorMessage != null ? Icons.error_outline : Icons.link_off),
                      color: connected 
                          ? (isGanache ? Colors.green : Colors.orange)
                          : (errorMessage != null ? Colors.orange : Colors.grey),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      connected 
                          ? '${_shortenAddress(address ?? '')} (${isGanache ? 'Ganache' : chainName})'
                          : 'Connect Wallet',
                      style: TextStyle(
                        color: connected 
                            ? (isGanache ? Colors.green : Colors.orange)
                            : (errorMessage != null ? Colors.orange : Colors.grey),
                      ),
                    ),
                  ],
                ),
        );

        // QR Code button takes precedence when we have a URI and are connecting
        if (_isConnecting && walletService.wcUri != null) {
          return ElevatedButton.icon(
            onPressed: () => _showQRCodeDialog(context, walletService.wcUri!),
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
        
        // Add warning if connected but not to Ganache
        if (connected && !isGanache) {
          return Tooltip(
            message: 'Warning: Connected to ${chainName} instead of Ganache. Please switch to Ganache in MetaMask.',
            child: connectionButton,
          );
        }
        
        // Add tooltip if there's an error message
        if (errorMessage != null && !connected) {
          return Tooltip(
            message: errorMessage,
            child: connectionButton,
          );
        }

        return connectionButton;
      },
    );
  }
} 