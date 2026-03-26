import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../services/dio_service.dart';
import '../models/order.dart';
import '../services/hive_service.dart';

// State for History
class HistoryState {
  final bool loading;
  final List<Order> orders;
  final String? error;
  final int currentPage;
  final int lastPage;

  // Filters
  final String searchQuery;
  final String statusFilter;
  final String periodFilter; // 'today', 'week', 'month', 'year'
  final DateTime? startDate;
  final DateTime? endDate;

  HistoryState({
    this.loading = false,
    this.orders = const [],
    this.error,
    this.currentPage = 1,
    this.lastPage = 1,
    this.searchQuery = '',
    this.statusFilter = 'all',
    this.periodFilter = 'today',
    this.startDate,
    this.endDate,
  });

  HistoryState copyWith({
    bool? loading,
    List<Order>? orders,
    String? error,
    int? currentPage,
    int? lastPage,
    String? searchQuery,
    String? statusFilter,
    String? periodFilter,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return HistoryState(
      loading: loading ?? this.loading,
      orders: orders ?? this.orders,
      error: error ?? this.error,
      currentPage: currentPage ?? this.currentPage,
      lastPage: lastPage ?? this.lastPage,
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: statusFilter ?? this.statusFilter,
      periodFilter: periodFilter ?? this.periodFilter,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }
}

class HistoryNotifier extends StateNotifier<HistoryState> {
  final Dio _dio;

  HistoryNotifier(this._dio)
    : super(HistoryState(
        periodFilter: 'today',
        startDate: DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day), 
        endDate: DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day)
      ));

  Future<void> fetchOrders({bool refresh = false}) async {
    if (state.loading) return;

    state = state.copyWith(loading: true, error: null);

    // Build query params
    final params = <String, dynamic>{
      'page': refresh ? 1 : state.currentPage + 1,
    };

    if (state.searchQuery.isNotEmpty) {
      params['search'] = state.searchQuery;
    }

    if (state.statusFilter != 'all') {
      // Map Flutter status labels to backend payment_status values
      String backendStatus = state.statusFilter;
      if (backendStatus == 'completed') backendStatus = 'paid';
      params['status'] = backendStatus;
    }

    if (state.startDate != null) {
      params['start_date'] = state.startDate!.toIso8601String().split('T')[0];
    }
    if (state.endDate != null) {
      params['end_date'] = state.endDate!.toIso8601String().split('T')[0];
    }

    try {
      debugPrint('HistoryProvider: Fetching /admin/orders with params=$params');
      final response = await _dio.get('/admin/orders', queryParameters: params);
      dynamic data = response.data;
      debugPrint('HistoryProvider: Response type=${data.runtimeType}');
      List<dynamic> dataList = [];
      Map<String, dynamic> meta = {};

      // Support direct list OR laravel paginated resource format
      if (data is Map<String, dynamic>) {
        debugPrint('HistoryProvider: Response keys=${data.keys.toList()}');
        if (data.containsKey('orders') &&
            data['orders'] is Map &&
            data['orders'].containsKey('data')) {
          dataList = data['orders']['data'];
          meta = Map<String, dynamic>.from(data['orders'] as Map);
          debugPrint('HistoryProvider: Parsed from orders.data, items=${dataList.length}');
        } else if (data.containsKey('data') && data['data'] is List) {
          dataList = data['data'];
          meta = data;
          debugPrint('HistoryProvider: Parsed from data[], items=${dataList.length}');
        } else {
          debugPrint('HistoryProvider: Could not parse response. Keys: ${data.keys.toList()}');
        }
      } else if (data is List) {
        dataList = data;
        debugPrint('HistoryProvider: Response is raw list, items=${dataList.length}');
      } else {
        debugPrint('HistoryProvider: Unexpected response type: ${data.runtimeType}');
      }

      final newOrders = dataList.map((json) {
        if (json['items'] == null) json['items'] = [];
        return Order.fromJson(json as Map<String, dynamic>);
      }).toList();

      List<Order> mergedOrders = refresh ? newOrders : [...state.orders, ...newOrders];
      debugPrint('HistoryProvider: Found ${newOrders.length} orders from server. Refresh=$refresh');

      // Merge offline pending orders if it's "Today" and we are on page 1 (refresh)
      final isTodayFilter = state.startDate == null || _isToday(state.startDate!);
      debugPrint('HistoryProvider: isTodayFilter=$isTodayFilter, statusFilter=${state.statusFilter}');
      
      if (refresh && isTodayFilter) {
        final pendingRaw = HiveService.getPendingOrders();
        debugPrint('HistoryProvider: Raw pending orders in Hive: ${pendingRaw.length}');
        
        final pendingOrders = pendingRaw.map((json) {
          return Order.fromJson({
            ...json,
            'id': json['temp_id'] ?? 'offline-${DateTime.now().millisecondsSinceEpoch}',
            'order_number': json['order_number'] ?? (json['temp_id'] ?? 'OFFLINE'),
            'status': 'pending',
          });
        }).toList();
        
        // Filter by status if needed
        final filteredPending = state.statusFilter == 'all' || state.statusFilter == 'pending'
            ? pendingOrders
            : <Order>[];
        
        debugPrint('HistoryProvider: Pending orders after status filter: ${filteredPending.length}');
        
        final serverOrderNumbers = newOrders.map((o) => o.orderNumber).toSet();
        final uniquePending = filteredPending.where((o) => !serverOrderNumbers.contains(o.orderNumber)).toList();
        debugPrint('HistoryProvider: Unique pending orders to add: ${uniquePending.length}');
        
        mergedOrders = [...uniquePending, ...newOrders];
      }

      state = state.copyWith(
        loading: false,
        orders: mergedOrders,
        currentPage: meta['current_page'] ?? 1,
        lastPage: meta['last_page'] ?? 1,
      );
    } catch (e) {
      debugPrint('HistoryProvider: Error fetching orders: $e');
      
      // If refresh failed (e.g. offline), still show local pending orders if it's today
      if (refresh && (state.startDate == null || _isToday(state.startDate!))) {
        final pendingRaw = HiveService.getPendingOrders();
        final pendingOrders = pendingRaw.map((json) {
          return Order.fromJson({
            ...json,
            'id': json['temp_id'] ?? 'offline-${DateTime.now().millisecondsSinceEpoch}',
            'order_number': json['order_number'] ?? (json['temp_id'] ?? 'OFFLINE'),
            'status': 'pending',
          });
        }).toList();
        
        if (pendingOrders.isNotEmpty) {
           state = state.copyWith(
            loading: false,
            orders: pendingOrders,
            error: null, // Don't show error if we have offline data
          );
          return;
        }
      }
      
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  void setSearch(String query) {
    if (state.searchQuery == query) return;
    state = state.copyWith(searchQuery: query);
    fetchOrders(refresh: true);
  }

  void setStatusFilter(String status) {
    if (state.statusFilter == status) return;
    state = state.copyWith(statusFilter: status);
    fetchOrders(refresh: true);
  }

  void setDateFilter(DateTime? start, DateTime? end) {
    state = state.copyWith(startDate: start, endDate: end, periodFilter: 'custom');
    fetchOrders(refresh: true);
  }

  void setPeriodFilter(String period) {
    if (state.periodFilter == period) return;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    DateTime start;
    DateTime end = today;

    switch (period) {
      case 'week':
        start = today.subtract(const Duration(days: 6));
        break;
      case 'month':
        start = DateTime(now.year, now.month, 1);
        break;
      case 'year':
        start = DateTime(now.year, 1, 1);
        break;
      case 'today':
      default:
        start = today;
        break;
    }

    state = state.copyWith(periodFilter: period, startDate: start, endDate: end);
    fetchOrders(refresh: true);
  }

  void shiftPeriod(int direction) {
    if (state.startDate == null || state.endDate == null) return;
    
    DateTime newStart = state.startDate!;
    DateTime newEnd = state.endDate!;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // Don't allow shifting into the future for "today" or future periods
    if (direction > 0 && 
        (state.periodFilter == 'today' || newEnd.isAfter(today) || newEnd.isAtSameMomentAs(today))) {
      return; 
    }

    switch (state.periodFilter) {
      case 'week':
        newStart = newStart.add(Duration(days: 7 * direction));
        newEnd = newStart.add(const Duration(days: 6));
        break;
      case 'month':
        newStart = DateTime(newStart.year, newStart.month + direction, 1);
        final nextMonth = DateTime(newStart.year, newStart.month + 1, 1);
        newEnd = nextMonth.subtract(const Duration(days: 1));
        break;
      case 'year':
        newStart = DateTime(newStart.year + direction, 1, 1);
        newEnd = DateTime(newStart.year, 12, 31);
        break;
      case 'today':
      case 'custom':
      default:
        // Shift by the current difference in days between start and end
        final diff = newEnd.difference(newStart).inDays + 1;
        newStart = newStart.add(Duration(days: diff * direction));
        newEnd = newStart.add(Duration(days: diff - 1));
        
        // If the new period filter was 'today', it technically becomes 'custom' or 'yesterday'
        // We'll keep the periodFilter as 'custom' if it shifts away from today
        state = state.copyWith(periodFilter: _isToday(newStart) ? 'today' : 'custom');
        break;
    }
    
    // Ensure we don't end in the future
    if (newEnd.isAfter(today)) {
      newEnd = today;
    }

    state = state.copyWith(startDate: newStart, endDate: newEnd);
    fetchOrders(refresh: true);
  }

  Future<bool> refundOrder(String orderId, String pin) async {
    try {
      await _dio.post('/admin/orders/$orderId/refund', data: {'pin': pin});
      fetchOrders(refresh: true);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> cancelOrder(String orderId, String pin) async {
    try {
      await _dio.post(
        '/admin/orders/$orderId/cancel',
        data: {'manager_pin': pin},
      );
      fetchOrders(refresh: true);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> sendReceipt(String orderId, String phone) async {
    try {
      await _dio.post(
        '/admin/orders/$orderId/whatsapp-receipt',
        data: {'phone': phone},
      );
      return true;
    } catch (e) {
      return false;
    }
  }
}

final historyProvider = StateNotifierProvider<HistoryNotifier, HistoryState>((
  ref,
) {
  final dio = ref.read(dioProvider);
  return HistoryNotifier(dio);
});
