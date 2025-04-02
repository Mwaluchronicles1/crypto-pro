import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:crypto_pro/services/wallet_connect_service.dart';

class NetworkSelector extends StatelessWidget {
  const NetworkSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<WalletConnectService>(
      builder: (context, service, _) {
        final currentNetwork = service.currentNetwork;
        final isConnected = service.isConnected;
        
        return PopupMenuButton<String>(
          onSelected: (String network) async {
            if (currentNetwork != network) {
              final success = await service.switchNetwork(network);
              if (!success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to switch to $network: ${service.errorMessage}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
          enabled: isConnected,
          itemBuilder: (context) => service.availableNetworks
              .map((network) => PopupMenuItem<String>(
                    value: network,
                    child: Row(
                      children: [
                        _getNetworkIcon(network),
                        const SizedBox(width: 8),
                        Text(_getNetworkName(network)),
                        if (currentNetwork == network) ...[
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 16,
                          ),
                        ],
                      ],
                    ),
                  ))
              .toList(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isConnected
                    ? Theme.of(context).primaryColor.withOpacity(0.5)
                    : Colors.grey.withOpacity(0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _getNetworkIcon(currentNetwork),
                const SizedBox(width: 8),
                Text(
                  _getNetworkName(currentNetwork),
                  style: TextStyle(
                    color: isConnected
                        ? Theme.of(context).primaryColor
                        : Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_drop_down,
                  color: isConnected
                      ? Theme.of(context).primaryColor
                      : Colors.grey,
                  size: 20,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _getNetworkIcon(String network) {
    Color color;
    IconData icon;

    switch (network) {
      case 'ethereum':
        color = Colors.blue.shade800;
        icon = Icons.all_inclusive;
        break;
      case 'sepolia':
        color = Colors.purple.shade700;
        icon = Icons.science_outlined;
        break;
      case 'polygon':
        color = Colors.purple;
        icon = Icons.pentagon_outlined;
        break;
      case 'binance':
        color = Colors.amber;
        icon = Icons.currency_bitcoin;
        break;
      default:
        color = Colors.grey;
        icon = Icons.public;
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        color: color,
        size: 16,
      ),
    );
  }

  String _getNetworkName(String network) {
    switch (network) {
      case 'ethereum':
        return 'Ethereum';
      case 'sepolia':
        return 'Sepolia';
      case 'polygon':
        return 'Polygon';
      case 'binance':
        return 'BNB Chain';
      default:
        return 'Unknown';
    }
  }
} 