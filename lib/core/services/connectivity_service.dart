import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Singleton service managing network connectivity checks
/// using connectivity_plus and active host lookup.
class ConnectivityService {
  ConnectivityService._();
  static final ConnectivityService instance = ConnectivityService._();

  final Connectivity _connectivity = Connectivity();

  /// Performs active lookup to ensure the device has actual internet routing.
  Future<bool> hasInternetConnection() async {
    if (kIsWeb) return true;
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 4));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Checks if the device is currently offline (no network interface or failed lookup).
  Future<bool> isOffline() async {
    try {
      final status = await _connectivity.checkConnectivity();
      if (status.isEmpty || status.contains(ConnectivityResult.none)) {
        return true;
      }
      final hasInternet = await hasInternetConnection();
      return !hasInternet;
    } catch (_) {
      return true;
    }
  }
}
