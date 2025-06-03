// import 'dart:async';
// import 'dart:io';
// import 'package:connectivity_plus/connectivity_plus.dart';

// class ConnectionService {
//   static final ConnectionService _instance = ConnectionService._internal();
//   factory ConnectionService() => _instance;
//   ConnectionService._internal();

//   final Connectivity _connectivity = Connectivity();
//   final StreamController<bool> _connectionController =
//       StreamController<bool>.broadcast();

//   Stream<bool> get connectionStream => _connectionController.stream;
//   bool _isConnected = true;
//   bool get isConnected => _isConnected;

//   Future<void> initialize() async {
//     await checkConnection();
//     _connectivity.onConnectivityChanged.listen((_) async {
//       await checkConnection();
//     });
//   }

//   Future<bool> checkConnection() async {
//     bool previousConnection = _isConnected;

//     try {
//       final connectivityResult = await _connectivity.checkConnectivity();
//       if (connectivityResult == ConnectivityResult.none) {
//         _isConnected = false;
//       } else {
//         // ✅ Perform actual internet check
//         final result = await InternetAddress.lookup('google.com');
//         _isConnected = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
//       }
//     } catch (e) {
//       _isConnected = false;
//     }

//     if (previousConnection != _isConnected) {
//       _connectionController.add(_isConnected);
//     }

//     return _isConnected;
//   }

//   void dispose() {
//     _connectionController.close();
//   }
// }

import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

/// Configuration class for connection testing parameters
class ConnectionConfig {
  final Duration connectionTimeout;
  final Duration requestTimeout;
  final Duration debounceDelay;
  final List<String> testEndpoints;
  final String userAgent;

  const ConnectionConfig({
    this.connectionTimeout = const Duration(seconds: 10),
    this.requestTimeout = const Duration(seconds: 15),
    this.debounceDelay = const Duration(milliseconds: 500),
    this.testEndpoints = const [
      'https://www.google.com',
      'https://httpbin.org/get',
      'https://jsonplaceholder.typicode.com/posts/1',
      'https://api.github.com',
    ],
    this.userAgent = 'smartassist-app',
  });
}

/// Interface for connection testing strategies
abstract class ConnectionTester {
  Future<bool> testConnection();
}

/// DNS-based connection tester
class DnsConnectionTester implements ConnectionTester {
  final Duration timeout;
  final String hostname;

  DnsConnectionTester({
    this.timeout = const Duration(seconds: 5),
    this.hostname = 'google.com',
  });

  @override
  Future<bool> testConnection() async {
    try {
      final result = await InternetAddress.lookup(hostname).timeout(timeout);
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      if (kDebugMode) print("DNS test failed: $e");
      return false;
    }
  }
}

/// HTTP-based connection tester using HttpClient
class HttpClientTester implements ConnectionTester {
  final ConnectionConfig config;

  HttpClientTester(this.config);

  @override
  Future<bool> testConnection() async {
    for (String endpoint in config.testEndpoints) {
      try {
        final client = HttpClient();
        client.connectionTimeout = config.connectionTimeout;
        client.idleTimeout = const Duration(seconds: 5);

        final request = await client.getUrl(Uri.parse(endpoint));
        request.headers.set('User-Agent', config.userAgent);

        final response = await request.close().timeout(
          config.connectionTimeout,
        );

        final isSuccess =
            response.statusCode >= 200 && response.statusCode < 400;
        client.close();

        if (isSuccess) return true;
      } catch (e) {
        if (kDebugMode) print("HTTP client test failed for $endpoint: $e");
        continue;
      }
    }
    return false;
  }
}

/// HTTP package-based connection tester
class HttpPackageTester implements ConnectionTester {
  final ConnectionConfig config;

  HttpPackageTester(this.config);

  @override
  Future<bool> testConnection() async {
    try {
      final response = await http
          .get(
            Uri.parse(config.testEndpoints.first),
            headers: {
              'User-Agent': config.userAgent,
              'Accept':
                  'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
            },
          )
          .timeout(config.requestTimeout);

      return response.statusCode >= 200 && response.statusCode < 400;
    } catch (e) {
      if (kDebugMode) print("HTTP package test failed: $e");
      return false;
    }
  }
}

/// Main connection service with singleton pattern
class ConnectionService {
  static final ConnectionService _instance = ConnectionService._internal();
  factory ConnectionService([ConnectionConfig? config]) {
    if (config != null) {
      _instance._config = config;
    }
    return _instance;
  }
  ConnectionService._internal();

  ConnectionConfig _config = const ConnectionConfig();
  bool _isConnected = false;
  bool _isInitialized = false;
  StreamSubscription? _connectivitySubscription;

  // Getters
  bool get isConnected => _isConnected;
  bool get isInitialized => _isInitialized;

  /// Initialize the connection service with optional configuration
  Future<void> initialize([ConnectionConfig? config]) async {
    if (config != null) _config = config;

    try {
      if (kDebugMode) print("=== Initializing ConnectionService ===");

      _setupConnectivityListener();
      await checkConnection();
      _isInitialized = true;

      if (kDebugMode) print("ConnectionService initialized successfully");
    } catch (e) {
      if (kDebugMode) print("Error initializing ConnectionService: $e");
      _isInitialized = true;
      _isConnected = kReleaseMode; // Assume connected in release mode
    }
  }

  /// Set up real-time connectivity monitoring
  void _setupConnectivityListener() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
      _handleConnectivityChange,
    );
  }

  /// Handle connectivity changes with debouncing
  void _handleConnectivityChange(dynamic connectivityResults) async {
    if (kDebugMode) print("Connectivity changed: $connectivityResults");
    await Future.delayed(_config.debounceDelay);
    await checkConnection();
  }

  /// Check connection using multiple strategies
  Future<void> checkConnection() async {
    try {
      if (kDebugMode) print("=== Starting connection check ===");

      if (!await _hasBasicConnectivity()) {
        _isConnected = false;
        return;
      }

      _isConnected = await _testInternetConnection();
      if (kDebugMode) print("Final connection status: $_isConnected");
    } catch (e) {
      if (kDebugMode) print("Error in checkConnection: $e");
      _isConnected = kReleaseMode; // Fallback for release mode
    }
  }

  /// Check basic connectivity using the connectivity plugin
  Future<bool> _hasBasicConnectivity() async {
    final connectivityResults = await Connectivity().checkConnectivity();

    if (connectivityResults is List) {
      return connectivityResults.any(
        (result) => result != ConnectivityResult.none,
      );
    }
    return connectivityResults != ConnectivityResult.none;
  }

  /// Test actual internet connection using multiple strategies
  Future<bool> _testInternetConnection() async {
    final testers = [
      DnsConnectionTester(),
      HttpClientTester(_config),
      HttpPackageTester(_config),
    ];

    for (final tester in testers) {
      if (await tester.testConnection()) {
        return true;
      }
    }

    // Last resort: assume connected in release mode to avoid false negatives
    return kReleaseMode;
  }

  /// Quick connection check using DNS only
  Future<bool> hasInternetQuick() async {
    return await DnsConnectionTester(
      timeout: const Duration(seconds: 3),
    ).testConnection();
  }

  /// Force connection check without relying on cached status
  Future<bool> forceCheckConnection() async {
    try {
      if (kDebugMode) print("Force checking connection...");
      final hasInternet = await _testInternetConnection();
      _isConnected = hasInternet;
      return hasInternet;
    } catch (e) {
      if (kDebugMode) print("Force check failed: $e");
      _isConnected = kReleaseMode;
      return _isConnected;
    }
  }

  /// Update configuration
  void updateConfig(ConnectionConfig config) {
    _config = config;
  }

  /// Dispose resources
  void dispose() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
  }
}

// import 'package:connectivity_plus/connectivity_plus.dart';
// import 'package:http/http.dart' as http;
// import 'dart:io';
// import 'package:flutter/foundation.dart';

// class ConnectionService {
//   static final ConnectionService _instance = ConnectionService._internal();
//   factory ConnectionService() => _instance;
//   ConnectionService._internal();

//   bool _isConnected = false;
//   bool _isInitialized = false;
//   bool get isConnected => _isConnected;
//   bool get isInitialized => _isInitialized;

//   // Initialize the connection service
//   Future<void> initialize() async {
//     try {
//       print("=== Initializing ConnectionService ===");

//       // Set up connectivity listener for real-time updates
//       Connectivity().onConnectivityChanged.listen((connectivityResults) {
//         print("Connectivity changed: $connectivityResults");
//         _handleConnectivityChange(connectivityResults);
//       });

//       // Perform initial connection check
//       await checkConnection();
//       _isInitialized = true;
//       print("ConnectionService initialized successfully");
//     } catch (e) {
//       print("Error initializing ConnectionService: $e");
//       _isInitialized = true; // Mark as initialized even if failed
//       _isConnected = true; // Assume connected to avoid blocking
//     }
//   }

//   void _handleConnectivityChange(dynamic connectivityResults) async {
//     print("Handling connectivity change...");
//     // Debounce rapid connectivity changes
//     await Future.delayed(const Duration(milliseconds: 500));
//     await checkConnection();
//   }

//   Future<void> checkConnection() async {
//     try {
//       print("=== Starting connection check ===");

//       // Step 1: Check basic connectivity
//       var connectivityResults = await Connectivity().checkConnectivity();
//       print("Connectivity results: $connectivityResults");

//       // Handle both single result and list of results (newer versions)
//       bool hasConnectivity = false;
//       if (connectivityResults is List) {
//         hasConnectivity = connectivityResults.any(
//           (result) => result != ConnectivityResult.none,
//         );
//       } else {
//         hasConnectivity = connectivityResults != ConnectivityResult.none;
//       }

//       if (!hasConnectivity) {
//         print("No basic connectivity detected");
//         _isConnected = false;
//         return;
//       }

//       print("Basic connectivity detected, testing actual internet...");

//       // Step 2: Test actual internet connection with multiple fallbacks
//       _isConnected = await _testInternetWithFallbacks();
//       print("Final connection status: $_isConnected");
//     } catch (e) {
//       print("Error in checkConnection: $e");
//       // In case of any error, assume connected to avoid false negatives
//       _isConnected = true;
//     }
//   }

//   Future<bool> _testInternetWithFallbacks() async {
//     // List of reliable endpoints to test
//     final testEndpoints = [
//       'https://www.google.com',
//       'https://httpbin.org/get',
//       'https://jsonplaceholder.typicode.com/posts/1',
//       'https://api.github.com',
//     ];

//     // Test DNS resolution first
//     try {
//       print("Testing DNS resolution...");
//       final result = await InternetAddress.lookup(
//         'google.com',
//       ).timeout(const Duration(seconds: 5));
//       if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
//         print("DNS resolution successful");
//       }
//     } catch (e) {
//       print("DNS resolution failed: $e");
//       // Don't return false here, continue with HTTP tests
//     }

//     // Test HTTP connections with multiple endpoints
//     for (String endpoint in testEndpoints) {
//       try {
//         print("Testing HTTP connection to: $endpoint");

//         final client = HttpClient();
//         client.connectionTimeout = const Duration(seconds: 10);
//         client.idleTimeout = const Duration(seconds: 5);

//         final request = await client.getUrl(Uri.parse(endpoint));
//         request.headers.set('User-Agent', 'smartassist-app');

//         final response = await request.close().timeout(
//           const Duration(seconds: 10),
//         );

//         print("HTTP response status: ${response.statusCode} for $endpoint");

//         if (response.statusCode >= 200 && response.statusCode < 400) {
//           client.close();
//           return true;
//         }

//         client.close();
//       } catch (e) {
//         print("HTTP test failed for $endpoint: $e");
//         continue; // Try next endpoint
//       }
//     }

//     // If all HTTP tests fail, try with http package as fallback
//     return await _testWithHttpPackage();
//   }

//   Future<bool> _testWithHttpPackage() async {
//     try {
//       print("Testing with http package as fallback...");

//       final response = await http
//           .get(
//             Uri.parse('https://www.google.com'),
//             headers: {
//               'User-Agent': 'smartassist-app',
//               'Accept':
//                   'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
//             },
//           )
//           .timeout(const Duration(seconds: 15));

//       print("Http package test result: ${response.statusCode}");
//       return response.statusCode >= 200 && response.statusCode < 400;
//     } catch (e) {
//       print("Http package test failed: $e");

//       // Last resort: if we're in release mode and all tests fail,
//       // assume we have internet to avoid false negatives
//       if (kReleaseMode) {
//         print(
//           "Release mode: assuming internet connectivity to avoid false negative",
//         );
//         return true;
//       }

//       return false;
//     }
//   }

//   // Alternative simpler method for quick checks
//   Future<bool> hasInternetQuick() async {
//     try {
//       final result = await InternetAddress.lookup(
//         'google.com',
//       ).timeout(const Duration(seconds: 3));
//       return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
//     } catch (e) {
//       // In release mode, if quick check fails, assume internet is available
//       return kReleaseMode;
//     }
//   }

//   // Force connection check without relying on cached status
//   Future<bool> forceCheckConnection() async {
//     try {
//       print("Force checking connection...");
//       final hasInternet = await _testInternetWithFallbacks();
//       _isConnected = hasInternet;
//       return hasInternet;
//     } catch (e) {
//       print("Force check failed: $e");
//       // In release mode, assume connected to avoid false negatives
//       _isConnected = kReleaseMode;
//       return _isConnected;
//     }
//   }
// }
