import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

class WalletConnectQRCode extends StatelessWidget {
  final String uri;
  final VoidCallback? onCopied;

  const WalletConnectQRCode({
    super.key,
    required this.uri,
    this.onCopied,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: QrImageView(
            data: uri,
            version: QrVersions.auto,
            size: 250,
            backgroundColor: Colors.white,
            padding: const EdgeInsets.all(16),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Scan with your wallet',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Open MetaMask wallet and scan this QR code',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        InkWell(
          onTap: () async {
            await Clipboard.setData(ClipboardData(text: uri));
            onCopied?.call();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Theme.of(context).primaryColor,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.copy,
                  color: Theme.of(context).primaryColor,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'Copy to clipboard',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
} 