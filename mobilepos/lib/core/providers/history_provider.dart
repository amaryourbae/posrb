import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../services/dio_service.dart';
import '../models/order.dart';

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
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }
}

class HistoryNotifier extends StateNotifier<HistoryState> {
  final Dio _dio;

  HistoryNotifier(this._dio)
    : super(HistoryState(startDate: DateTime.now(), endDate: DateTime.now()));

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
      params['status'] = state.statusFilter;
    }

    if (state.startDate != null) {
      params['start_date'] = state.startDate!.toIso8601String().split('T')[0];
    }
    if (state.endDate != null) {
      params['end_date'] = state.endDate!.toIso8601String().split('T')[0];
    }

    try {
      final response = await _dio.get('/admin/orders', queryParameters: params);
      dynamic data = response.data;
      List<dynamic> dataList = [];
      Map<String, dynamic> meta = {};

      if (data is Map<String, dynamic>) {
        if (data.containsKey('orders')) {
          final ordersData = data['orders'];
          if (ordersData is Map<String, dynamic> &&
              ordersData.containsKey('data')) {
            dataList = ordersData['data'];
            meta = ordersData;
          } else if (ordersData is List) {
            dataList = ordersData;
          }
        } else if (data.containsKey('data') && data['data'] is List) {
          dataList = data['data'];
          meta = data;
        } else if (data.containsKey('data') && data['data'] is List) {
          dataList = data['data'];
        }
      } else if (data is List) {
        dataList = data;
      }

      final newOrders = dataList.map((json) {
        if (json['items'] == null) json['items'] = [];
        return Order.fromJson(json);
      }).toList();

      state = state.copyWith(
        loading: false,
        orders: refresh ? newOrders : [...state.orders, ...newOrders],
        currentPage: meta['current_page'] ?? 1,
        lastPage: meta['last_page'] ?? 1,
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
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
    state = state.copyWith(startDate: start, endDate: end);
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
