import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:walletconnect_flutter_v2/walletconnect_flutter_v2.dart';
import 'package:http/http.dart' as http;
import 'package:web3dart/web3dart.dart';

class WalletConnectService extends ChangeNotifier {
  bool _isConnected = false;
  bool _isBusy = false;
  String? _currentAddress;
  int? _chainId;
  String? _errorMessage;
  final List<String> _availableNetworks = ['ganache', 'ethereum', 'sepolia', 'polygon', 'binance'];
  String _currentNetwork = 'ganache'; // Default to Ganache
  
  // Chain Names (Human readable)
  final Map<String, String> _chainNames = {
    'ethereum': 'Ethereum',
    'sepolia': 'Sepolia Testnet',
    'polygon': 'Polygon',
    'binance': 'BNB Chain',
    'ganache': 'Ganache Local',
  };

  // Chain IDs
  final Map<String, int> _networkChainIds = {
    'ethereum': 1,
    'sepolia': 11155111,
    'polygon': 137,
    'binance': 56,
    'ganache': 1337,
  };
  
  // Network RPC URLs
  final Map<String, String> _networkRpcUrls = {
    'ethereum': 'https://mainnet.infura.io/v3/9aa3d95b3bc440fa88ea12eaa4456161',
    'sepolia': 'https://sepolia.infura.io/v3/9aa3d95b3bc440fa88ea12eaa4456161',
    'polygon': 'https://polygon-rpc.com',
    'binance': 'https://bsc-dataseed.binance.org/',
    'ganache': 'http://127.0.0.1:7545', // Local Ganache
  };
  
  // WalletConnect V2 Web3Wallet
  Web3App? _wcClient;

  // Web3 client for blockchain interaction
  Web3Client? _web3client;
  
  // Active session info
  SessionData? _session;
  
  // Getters
  bool get isConnected => _isConnected;
  bool get isBusy => _isBusy;
  String? get currentAddress => _currentAddress;
  String? get errorMessage => _errorMessage;
  int? get chainId => _chainId;
  List<String> get availableNetworks => _availableNetworks;
  String get currentNetwork => _currentNetwork;
  SessionData? get session => _session;
  
  // Initialize
  Future<void> initialize() async {
    try {
      // Initialize Web3Client with default Ganache network
      _web3client = Web3Client(_networkRpcUrls['ganache']!, http.Client());
      
      // Initialize WalletConnect client with a real Project ID
      _wcClient = await Web3App.createInstance(
        // Get a free project ID from https://cloud.walletconnect.com/
        projectId: 'c9f85244dfe36dcc01889098e37f1a8c',  // This is a real test project ID
        metadata: const PairingMetadata(
          name: 'Crypto Pro',
          description: 'A document verification platform using blockchain technology',
          url: 'https://cryptopro.app',
          icons: ['https://cryptopro.app/logo.png'],
        ),
      );
      
      // Setup event listeners
      _setupEventListeners();
      
      _errorMessage = null;
      notifyListeners();
      debugPrint('WalletConnect initialized successfully');
      debugPrint('Available networks: $_availableNetworks');
      debugPrint('Current network: $_currentNetwork (Chain ID: ${_networkChainIds[_currentNetwork]})');
    } catch (e) {
      _errorMessage = 'Failed to initialize WalletConnectService: $e';
      debugPrint('Error initializing WalletConnectService: $e');
      notifyListeners();
    }
  }
  
  // Setup WalletConnect event listeners
  void _setupEventListeners() {
    _wcClient?.onSessionConnect.subscribe((sessionEvent) {
      debugPrint('Session connected: ${sessionEvent.toString()}');
      // For SessionConnect events, access session property if not null
      if (sessionEvent != null && sessionEvent.session != null) {
        _handleSessionConnect(sessionEvent.session!);
      }
    });
    
    _wcClient?.onSessionDelete.subscribe((sessionEvent) {
      debugPrint('Session deleted: ${sessionEvent.toString()}');
      _handleSessionDisconnect();
    });
    
    _wcClient?.onSessionUpdate.subscribe((sessionEvent) {
      debugPrint('Session updated: ${sessionEvent.toString()}');
      // For SessionUpdate, handle directly - pass the updated session topic
      if (sessionEvent != null && sessionEvent.topic != null) {
        _handleSessionUpdate(sessionEvent.topic!);
      }
    });
  }
  
  // Connect to wallet with improved error handling
  Future<bool> connect() async {
    if (_isBusy) {
      debugPrint('Connection already in progress');
      return false;
    }
    if (_isConnected) {
      debugPrint('Already connected');
      return true;
    }
    
    try {
      _isBusy = true;
      _errorMessage = null;
      notifyListeners();
      
      if (_wcClient == null) {
        debugPrint('WalletConnect client not initialized, initializing now...');
        await initialize();
        if (_wcClient == null) {
          throw Exception('WalletConnect client initialization failed');
        }
      }
      
      // Ensure we're using Ganache
      _currentNetwork = 'ganache';
      
      // Output debugging info
      debugPrint('Using network: $_currentNetwork');
      debugPrint('Chain ID: ${_networkChainIds[_currentNetwork]}');
      
      // Required namespaces for EVM chains
      final requiredNamespaces = {
        'eip155': RequiredNamespace(
          chains: [
            'eip155:${_networkChainIds[_currentNetwork]}',
          ],
          methods: [
            'eth_sendTransaction',
            'eth_signTransaction',
            'eth_sign',
            'personal_sign',
            'eth_signTypedData',
          ],
          events: [
            'chainChanged',
            'accountsChanged',
          ],
        ),
      };
      
      debugPrint('Creating connection request for Ganache (Chain ID: ${_networkChainIds[_currentNetwork]})...');
      // Connect
      final connectResponse = await _wcClient!.connect(
        requiredNamespaces: requiredNamespaces,
      );
      
      // Create a URI to connect to the wallet
      final uri = connectResponse.uri;
      if (uri != null) {
        // Try to launch the wallet
        final url = uri.toString();
        debugPrint('WalletConnect URI generated: $url');
        _wcUri = url; // Store URI for QR code display
        
        // Launch MetaMask deep link for mobile
        final metamaskUri = 'metamask://wc?uri=${Uri.encodeComponent(url)}';
        try {
          final canLaunch = await canLaunchUrl(Uri.parse(metamaskUri));
          if (canLaunch) {
            debugPrint('Launching MetaMask with URI...');
            await launchUrl(Uri.parse(metamaskUri), mode: LaunchMode.externalApplication);
          } else {
            debugPrint('Cannot launch MetaMask app, trying direct URL...');
            // Fallback to opening the URL directly
            await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
          }
        } catch (e) {
          debugPrint('Error launching MetaMask: $e');
          // Fallback to showing URI
          _errorMessage = 'Please scan the QR code with MetaMask or copy: $url';
          notifyListeners();
        }
      } else {
        debugPrint('No URI generated for connection');
        _errorMessage = 'Failed to generate connection URI';
        notifyListeners();
        return false;
      }
      
      // Wait for the connection to be established with a timeout
      debugPrint('Waiting for user to approve connection in MetaMask...');
      try {
        final session = await connectResponse.session.future.timeout(
          const Duration(seconds: 60), // Reduced timeout to 1 minute
          onTimeout: () {
            debugPrint('Connection timeout after 60 seconds');
            throw TimeoutException('Connection timeout. Try again or check your wallet app.');
          },
        );
        
        debugPrint("Session received: ${session.toString()}");
        _handleSessionConnect(session);
        
        if (_isConnected) {
          debugPrint('Successfully connected to wallet');
          // Verify we're on Ganache
          if (_chainId != 1337) {
            _errorMessage = 'Connected to chain ${_chainId} but expected Ganache (1337). Please switch networks in MetaMask.';
            debugPrint(_errorMessage!);
            notifyListeners();
          }
        } else {
          debugPrint('Connection process completed but isConnected is still false');
        }
        
        return _isConnected; // Return actual connection status
      } catch (timeoutError) {
        debugPrint('Connection timeout: $timeoutError');
        _errorMessage = timeoutError.toString();
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error connecting wallet: $e';
      debugPrint('Error connecting wallet: $e');
      return false;
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }
  
  // Add this property to store the URI for QR code display
  String? _wcUri;
  String? get wcUri => _wcUri;
  
  // Disconnect wallet
  Future<void> disconnect() async {
    if (!_isConnected || _session == null || _wcClient == null) return;
    
    try {
      await _wcClient!.disconnectSession(
        topic: _session!.topic,
        reason: const WalletConnectError(code: 0, message: 'User disconnected'),
      );
      
      _handleSessionDisconnect();
    } catch (e) {
      _errorMessage = 'Error disconnecting wallet: $e';
      debugPrint('Error disconnecting wallet: $e');
      
      // Force disconnect on the client side
      _handleSessionDisconnect();
    }
  }
  
  // Handle session connect
  void _handleSessionConnect(SessionData session) {
    _session = session;
    
    // Extract accounts from namespaces
    final accounts = session.namespaces.values
        .expand((namespace) => namespace.accounts)
        .toList();
    
    if (accounts.isNotEmpty) {
      // Parse the account string (e.g., "eip155:1:0x123...")
      final parts = accounts[0].split(':');
      if (parts.length >= 3) {
        _currentAddress = parts[2];
        _chainId = int.tryParse(parts[1]);
        _isConnected = true;
        
        // Update the current network based on chain ID
        _updateCurrentNetworkFromChainId();
        
        debugPrint('Connected with address: $_currentAddress');
        debugPrint('Chain ID: $_chainId');
        
        // Update web3 client for the connected chain
        _updateWeb3Client();
      } else {
        debugPrint('Invalid account format: ${accounts[0]}');
        _isConnected = false;
      }
    } else {
      debugPrint('No accounts found in session');
      _isConnected = false;
    }
    
    notifyListeners();
  }
  
  // Handle session update - modify to accept a session topic instead of SessionData
  void _handleSessionUpdate(String? topic) {
    if (topic == null) return;
    
    // Find the session by topic if we have access to it
    if (_wcClient != null) {
      try {
        final session = _wcClient!.getActiveSessions()[topic];
        if (session != null) {
          _session = session;
          
          // Extract accounts from namespaces
          final accounts = session.namespaces.values
              .expand((namespace) => namespace.accounts)
              .toList();
          
          if (accounts.isNotEmpty) {
            // Parse the account string (e.g., "eip155:1:0x123...")
            final parts = accounts[0].split(':');
            if (parts.length >= 3) {
              _currentAddress = parts[2];
              _chainId = int.tryParse(parts[1]);
              
              // Update the current network based on chain ID
              _updateCurrentNetworkFromChainId();
              
              // Update web3 client for the connected chain
              _updateWeb3Client();
            }
          }
        }
      } catch (e) {
        debugPrint('Error getting session by topic: $e');
      }
    }
    
    notifyListeners();
  }
  
  // Handle session disconnect
  void _handleSessionDisconnect() {
    _session = null;
    _currentAddress = null;
    _chainId = null;
    _isConnected = false;
    
    notifyListeners();
    debugPrint('Wallet disconnected');
  }
  
  // Update current network based on chain ID
  void _updateCurrentNetworkFromChainId() {
    if (_chainId != null) {
      // Find network name by chain ID
      String? networkName;
      _networkChainIds.forEach((key, value) {
        if (value == _chainId) {
          networkName = key;
        }
      });
      
      if (networkName != null) {
        // Using ! to force unwrapping after null check
        _currentNetwork = networkName!;
      }
    }
  }
  
  // Update web3 client based on chain
  void _updateWeb3Client() {
    _web3client?.dispose();
    _web3client = Web3Client(_networkRpcUrls[_currentNetwork]!, http.Client());
  }
  
  // Switch network
  Future<bool> switchNetwork(String network) async {
    if (!_availableNetworks.contains(network)) {
      _errorMessage = 'Network not supported: $network';
      notifyListeners();
      return false;
    }
    
    if (!_isConnected || _session == null || _wcClient == null) {
      // Just update the current network if not connected
      _currentNetwork = network;
      _updateWeb3Client();
      notifyListeners();
      return true;
    }
    
    try {
      // Request chain switch with MetaMask
      final chainId = _networkChainIds[network]!;
      final chainIdHex = '0x${chainId.toRadixString(16)}';
      
      await _wcClient!.request(
        topic: _session!.topic,
        chainId: 'eip155:$chainId',
        request: SessionRequestParams(
          method: 'wallet_switchEthereumChain',
          params: [
            {
              'chainId': chainIdHex,
            },
          ],
        ),
      );
      
      // If we reach here, chain switch was successful
      _chainId = chainId;
      _currentNetwork = network;
      _updateWeb3Client();
      
      notifyListeners();
      return true;
    } catch (e) {
      if (e.toString().contains('4902')) {
        // Chain not added to wallet, try to add it
        return await _addChain(network);
      }
      
      _errorMessage = 'Failed to switch network: $e';
      debugPrint('Error switching network: $e');
      notifyListeners();
      return false;
    }
  }
  
  // Add chain to wallet
  Future<bool> _addChain(String network) async {
    if (!_isConnected || _session == null || _wcClient == null) {
      return false;
    }
    
    try {
      final chainId = _networkChainIds[network]!;
      final chainIdHex = '0x${chainId.toRadixString(16)}';
      
      await _wcClient!.request(
        topic: _session!.topic,
        chainId: 'eip155:$chainId',
        request: SessionRequestParams(
          method: 'wallet_addEthereumChain',
          params: [
            {
              'chainId': chainIdHex,
              'chainName': _chainNames[network],
              'rpcUrls': [_networkRpcUrls[network]],
              'nativeCurrency': {
                'name': network == 'binance' ? 'BNB' : (network == 'polygon' ? 'MATIC' : 'ETH'),
                'symbol': network == 'binance' ? 'BNB' : (network == 'polygon' ? 'MATIC' : 'ETH'),
                'decimals': 18,
              },
              'blockExplorerUrls': [
                network == 'ethereum' ? 'https://etherscan.io' :
                (network == 'sepolia' ? 'https://sepolia.etherscan.io' :
                (network == 'polygon' ? 'https://polygonscan.com' : 'https://bscscan.com')),
              ],
            },
          ],
        ),
      );
      
      // If we reach here, chain was added successfully
      _chainId = chainId;
      _currentNetwork = network;
      _updateWeb3Client();
      
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to add network: $e';
      debugPrint('Error adding network: $e');
      notifyListeners();
      return false;
    }
  }
  
  // Sign message
  Future<String?> signMessage(String message) async {
    if (!_isConnected || _session == null || _wcClient == null || _currentAddress == null) {
      _errorMessage = 'Wallet not connected';
      notifyListeners();
      return null;
    }
    
    try {
      final response = await _wcClient!.request(
        topic: _session!.topic,
        chainId: 'eip155:${_chainId ?? _networkChainIds[_currentNetwork]!}',
        request: SessionRequestParams(
          method: 'personal_sign',
          params: [
            message,
            _currentAddress!.toLowerCase(),
          ],
        ),
      );
      
      return response as String;
    } catch (e) {
      _errorMessage = 'Failed to sign message: $e';
      debugPrint('Error signing message: $e');
      notifyListeners();
      return null;
    }
  }
  
  // Send transaction
  Future<String?> sendTransaction({
    required String to,
    required BigInt value,
    String? data,
    int? gasLimit,
    EtherAmount? gasPrice,
  }) async {
    if (!_isConnected || _session == null || _wcClient == null || _currentAddress == null) {
      _errorMessage = 'Wallet not connected';
      notifyListeners();
      return null;
    }
    
    try {
      // Prepare transaction parameters
      final params = {
        'from': _currentAddress!.toLowerCase(),
        'to': to,
        'value': '0x${value.toRadixString(16)}',
      };
      
      if (data != null) {
        params['data'] = data;
      }
      
      if (gasLimit != null) {
        params['gas'] = '0x${gasLimit.toRadixString(16)}';
      }
      
      if (gasPrice != null) {
        params['gasPrice'] = '0x${gasPrice.getInWei.toRadixString(16)}';
      }
      
      // Send transaction through WalletConnect
      final response = await _wcClient!.request(
        topic: _session!.topic,
        chainId: 'eip155:${_chainId ?? _networkChainIds[_currentNetwork]!}',
        request: SessionRequestParams(
          method: 'eth_sendTransaction',
          params: [params],
        ),
      );
      
      return response as String;
    } catch (e) {
      _errorMessage = 'Failed to send transaction: $e';
      debugPrint('Error sending transaction: $e');
      notifyListeners();
      return null;
    }
  }
  
  // Get wallet balance
  Future<EtherAmount?> getBalance() async {
    if (!_isConnected || _currentAddress == null || _web3client == null) {
      _errorMessage = 'Wallet not connected';
      notifyListeners();
      return null;
    }
    
    try {
      final balance = await _web3client!.getBalance(
        EthereumAddress.fromHex(_currentAddress!),
      );
      
      return balance;
    } catch (e) {
      _errorMessage = 'Failed to get balance: $e';
      debugPrint('Error getting balance: $e');
      notifyListeners();
      return null;
    }
  }
  
  // For development testing only - connects directly using a local Ganache address
  Future<bool> connectDevelopmentWallet() async {
    if (_isBusy) {
      debugPrint('Connection already in progress');
      return false;
    }
    
    try {
      _isBusy = true;
      _errorMessage = null;
      notifyListeners();
      
      // Ensure we're using Ganache
      _currentNetwork = 'ganache';
      
      // Set up development address - use a safer approach than storing private keys
      const devAddress = '0x1308D78cd4d5Bd15Db18777Ed550926543bEC90C'; 
      _currentAddress = devAddress;
      _chainId = 1337; // Ganache's default chain ID
      _isConnected = true;
      
      // Update web3 client for the connected chain
      _updateWeb3Client();
      
      debugPrint('Successfully connected to development wallet (Ganache)');
      debugPrint('Connected with address: $_currentAddress');
      debugPrint('Chain ID: $_chainId');
      
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Error connecting development wallet: $e';
      debugPrint('Error connecting development wallet: $e');
      return false;
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }
  
  @override
  void dispose() {
    disconnect();
    _web3client?.dispose();
    super.dispose();
  }
} 