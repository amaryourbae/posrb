import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'hive_service.dart';


class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  Dio? _dio;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isSyncing = false;

  // Stream to notify UI of pending count changes
  final _pendingCountController = StreamController<int>.broadcast();
  Stream<int> get pendingCountStream => _pendingCountController.stream;

  void init(Dio dio) {
    _dio = dio;
    _updatePendingCount();

    // Listen to network changes
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      if (results.contains(ConnectivityResult.mobile) ||
          results.contains(ConnectivityResult.wifi) ||
          results.contains(ConnectivityResult.ethernet)) {
        syncPendingOrders();
      }
    });

    // Also try to sync on startup if there's connection
    _checkAndSyncOnStartup();
  }

  void _updatePendingCount() {
    final count = HiveService.getPendingOrders().length;
    _pendingCountController.add(count);
  }

  Future<void> _checkAndSyncOnStartup() async {
    final connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult.contains(ConnectivityResult.mobile) ||
        connectivityResult.contains(ConnectivityResult.wifi) ||
        connectivityResult.contains(ConnectivityResult.ethernet)) {
      syncPendingOrders();
    }
  }

  /// Triggers a background sync of all offline orders
  Future<void> syncPendingOrders() async {
    if (_dio == null) return;
    if (_isSyncing) return; // Prevent concurrent syncs

    final pendingOrders = HiveService.getPendingOrders();
    if (pendingOrders.isEmpty) return;

    _isSyncing = true;
    debugPrint(
      'SyncService: Starting to sync ${pendingOrders.length} orders...',
    );

    for (var order in pendingOrders) {
      try {
        final tempId = order['temp_id'];

        // Prepare payload (remove local-only fields)
        final payload = Map<String, dynamic>.from(order)
          ..remove('temp_id')
          ..remove('synced');

        // Set offline_id to prevent duplicates if network drops during response
        payload['offline_id'] = tempId;

        debugPrint('SyncService: Syncing order $tempId...');
        final response = await _dio!.post('/orders', data: payload);

        if (response.statusCode == 201 || response.statusCode == 200) {
          debugPrint('SyncService: Successfully synced order $tempId');
          // Mark as synced & remove
          await HiveService.markOrderSynced(tempId);
          await HiveService.removePendingOrder(tempId);
          _updatePendingCount();
        }
      } catch (e) {
        debugPrint('SyncService: Failed to sync order ${order['temp_id']}: $e');

        if (e is DioException && e.response?.statusCode == 400) {
          // Check if it failed due to duplicate offline_id (already synced but response dropped)
          final errorMsg = e.response?.data?['message'] ?? '';
          final errorDetails = e.response?.data?['errors']?.toString() ?? '';

          if (errorDetails.contains('offline id has already been taken') ||
              errorMsg.contains('offline id has already been taken')) {
            // Already exists on server, remove from local queue!
            debugPrint(
              'SyncService: Order ${order['temp_id']} was already processed by server. Removing local copy.',
            );
            await HiveService.removePendingOrder(order['temp_id']);
            _updatePendingCount();
          }
        }
        // Stop the loop if there's no internet or server is down to save battery/bandwidth
        if (e is DioException &&
            (e.type == DioExceptionType.connectionTimeout ||
                e.type == DioExceptionType.receiveTimeout ||
                e.type == DioExceptionType.unknown)) {
          debugPrint('SyncService: Network unavailable, stopping sync queue.');
          break;
        }
      }
    }

    _isSyncing = false;
    _updatePendingCount();
    debugPrint(
      'SyncService: Sync complete. Remaining pending: ${HiveService.getPendingOrders().length}',
    );
  }

  void dispose() {
    _connectivitySubscription?.cancel();
    _pendingCountController.close();
  }
}
