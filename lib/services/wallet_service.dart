import 'dart:typed_data';
import 'package:crypto_pro/services/wallet_service.dart';
import 'package:flutter/material.dart';
import 'package:walletconnect_dart/walletconnect_dart.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart' as web3;
import 'package:http/http.dart';
import 'package:url_launcher/url_launcher.dart';

import 'wallet_service.dart';

// Helper functions for hex conversion
Uint8List hexToBytes(String hex) {
  return Uint8List.fromList(
    hex.substring(2).split('').map((c) => int.parse(c, radix: 16)).toList(),
  );
}

String bytesToHex(Uint8List bytes) {
  return '0x' + bytes.map((e) => e.toRadixString(16).padLeft(2, '0')).join();
}

// Define a custom MsgSignature class
class CustomMsgSignature {
  final Uint8List r;
  final Uint8List s;
  final int v;

  CustomMsgSignature({required this.r, required this.s, required this.v});
}

// Custom Credentials Class
class CustomWalletConnectCredentials extends web3.Credentials {
  final WalletConnect connector;
  @override
  final web3.EthereumAddress address;

  CustomWalletConnectCredentials({
    required this.connector,
    required this.address,
  });

  @override
  Future<web3.EthereumAddress> extractAddress() async => address;

  @override
  Future<web3.MsgSignature> signToSignature(
      Uint8List payload, {
        int? chainId,
        bool isEIP1559 = false,
      }) async {
    try {
      // Use WalletConnect to sign the message
      final signatureHex = await connector.signPersonalMessage(
        message: payload,
        address: address.hex,
      );

      // Convert signature hex to bytes
      final signature = hexToBytes(signatureHex);
      final r = signature.sublist(0, 32);
      final s = signature.sublist(32, 64);
      final v = signature[64];

      return web3.MsgSignature(r, s, v);
    } catch (e) {
      rethrow;
    }
  }

  @override
  web3.MsgSignature signToEcSignature(
      Uint8List payload, {
        int? chainId,
        bool isEIP1559 = false,
      }) {
    throw UnsupportedError('EC signatures not supported with WalletConnect');
  }
}

class WalletService extends ChangeNotifier {
  static const String _rpcUrl = 'http://127.0.0.1:7545';
  static const int _chainId = 1337;

  WalletConnect? _connector;
  String? _currentAddress;
  bool _isConnected = false;
  web3.Web3Client? _web3client;

  bool get isConnected => _isConnected;
  String? get currentAddress => _currentAddress;
  web3.Web3Client? get web3Client => _web3client;

  WalletService() {
    _initializeWalletConnect();
  }

  void _initializeWalletConnect() {
    _connector = WalletConnect(
      bridge: 'https://bridge.walletconnect.org',
      clientMeta: const PeerMeta(
        name: 'Document Verification DApp',
        description: 'A document verification DApp',
        url: 'https://your-website.com',
        icons: ['https://your-website.com/icon.png'],
      ),
    );

    _web3client = web3.Web3Client(_rpcUrl, Client());

    _connector?.on('connect', (dynamic session) {
      final s = session as WalletConnectSession;
      if (s.accounts.isNotEmpty) {
        _currentAddress = s.accounts[0];
        _isConnected = true;
        notifyListeners();
      }
    });

    _connector?.on('disconnect', (_) => _handleDisconnect());

    _connector?.on('session_update', (dynamic payload) {
      final p = payload as WalletConnectSession;
      if (p.accounts.isNotEmpty) {
        _currentAddress = p.accounts[0];
        notifyListeners();
      }
    });
  }

  Future<void> connect() async {
    try {
      if (_connector == null) _initializeWalletConnect();

      if (!_connector!.connected) {
        final session = await _connector!.createSession(
          chainId: _chainId,
          onDisplayUri: (uri) async {
            final url = Uri.parse(uri);
            if (await canLaunchUrl(url)) {
              await launchUrl(url);
            }
          },
        );

        if (session.accounts.isNotEmpty) {
          _currentAddress = session.accounts[0];
          _isConnected = true;
          notifyListeners();
        }
      }
    } catch (e) {
      _handleDisconnect();
      rethrow;
    }
  }

  Future<void> disconnect() async {
    if (_connector?.connected ?? false) {
      await _connector!.killSession();
    }
    _handleDisconnect();
  }

  void _handleDisconnect() {
    _currentAddress = null;
    _isConnected = false;
    notifyListeners();
  }

  Future<web3.Credentials> getCredentials() async {
    if (_connector == null || _currentAddress == null) {
      throw Exception('Wallet not connected');
    }

    return CustomWalletConnectCredentials(
      connector: _connector!,
      address: web3.EthereumAddress.fromHex(_currentAddress!),
    );
  }

  @override
  void dispose() {
    _connector?.killSession();
    _web3client?.dispose();
    super.dispose();
  }
}