import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'hive_service.dart';

/// Service to handle connectivity monitoring and sync operations.
class SyncService extends ChangeNotifier {
  final Dio _dio;
  final Connectivity _connectivity = Connectivity();

  bool _isOnline = true;
  bool _isSyncing = false;
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  bool get isOnline => _isOnline;
  bool get isSyncing => _isSyncing;

  SyncService(this._dio) {
    _initConnectivity();
  }

  void _initConnectivity() {
    _subscription = _connectivity.onConnectivityChanged.listen(
      _updateConnectionStatus,
    );
    // Check initial status
    _connectivity.checkConnectivity().then(_updateConnectionStatus);
  }

  void _updateConnectionStatus(List<ConnectivityResult> results) {
    final bool wasOnline = _isOnline;
    _isOnline =
        results.isNotEmpty && !results.contains(ConnectivityResult.none);

    if (_isOnline != wasOnline) {
      notifyListeners();

      // Trigger sync if we came back online
      if (_isOnline && !wasOnline) {
        syncPendingData();
      }
    }
  }

  /// Sync all pending data to server
  Future<void> syncPendingData() async {
    if (!_isOnline || _isSyncing) return;

    _isSyncing = true;
    notifyListeners();

    try {
      await _syncPendingOrders();
      await _syncQueue();
    } catch (e) {
      debugPrint('Sync error: $e');
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// Sync pending offline orders
  Future<void> _syncPendingOrders() async {
    final pendingOrders = HiveService.getPendingOrders();

    for (var orderData in pendingOrders) {
      try {
        final tempId = orderData['temp_id'] as String;
        orderData.remove('temp_id');
        orderData.remove('synced');

        final response = await _dio.post('/admin/orders', data: orderData);

        if (response.statusCode == 200 || response.statusCode == 201) {
          await HiveService.removePendingOrder(tempId);
          debugPrint('Synced order: $tempId');
        }
      } catch (e) {
        debugPrint('Failed to sync order: $e');
        // Keep in pending, will retry next sync
      }
    }
  }

  /// Process generic sync queue
  Future<void> _syncQueue() async {
    final queue = HiveService.getSyncQueue();

    for (var entry in queue) {
      try {
        final request = entry.value;
        final String method = request['method'] ?? 'POST';
        final String url = request['url'] ?? '';
        final data = request['data'];

        Response response;
        if (method.toUpperCase() == 'GET') {
          response = await _dio.get(url);
        } else if (method.toUpperCase() == 'PUT') {
          response = await _dio.put(url, data: data);
        } else if (method.toUpperCase() == 'DELETE') {
          response = await _dio.delete(url);
        } else {
          response = await _dio.post(url, data: data);
        }

        if (response.statusCode != null && response.statusCode! < 400) {
          await HiveService.removeFromSyncQueue(entry.key);
        }
      } catch (e) {
        debugPrint('Failed to process queue item: $e');
      }
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
