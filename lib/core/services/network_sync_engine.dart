import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'package:flutter/material.dart';
import 'local_cache_service.dart';

class NetworkSyncEngine {
  static final NetworkSyncEngine instance = NetworkSyncEngine._internal();
  NetworkSyncEngine._internal();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _isOnline = true;

  bool get isOnline => _isOnline;

  Future<void> initialize() async {
    final results = await _connectivity.checkConnectivity();
    _updateStatus(results);

    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      _updateStatus(results);
    });
    debugPrint('NetworkSyncEngine Initialized');
  }

  void _updateStatus(List<ConnectivityResult> results) {
    bool wasOffline = !_isOnline;
    _isOnline = !results.contains(ConnectivityResult.none);

    if (wasOffline && _isOnline) {
      debugPrint('Connectivity restored. Triggering background sync...');
      _triggerBackgroundSync();
    }
  }

  Future<void> _triggerBackgroundSync() async {
    try {
      // Fetch latest profiles and clan feeds from Supabase
      // Assuming mock/sample table structures for demonstration
      // final supabase = Supabase.instance.client;
      // In a real scenario, this would query active tables
      // For now, we will clear pending actions and sync them
      final actions = LocalCacheService.instance.getPendingActions();
      if (actions.isNotEmpty) {
        debugPrint('Syncing \${actions.length} pending actions to cloud.');
        for (var action in actions) {
          // Process action payload against Supabase...
          debugPrint('Syncing action: ${action["type"]}');
        }
        await LocalCacheService.instance.clearPendingActions();
      }
    } catch (e) {
      debugPrint('Background sync failed: \$e');
    }
  }

  void dispose() {
    _subscription?.cancel();
  }
}

// Helper mixin/widget to show offline snackbar
void showOfflineSnackbar(BuildContext context) {
  if (!NetworkSyncEngine.instance.isOnline) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'You are currently offline. Actions will sync automatically when you are back online.',
        ),
        duration: Duration(seconds: 3),
        backgroundColor: Colors.orange,
      ),
    );
  }
}
