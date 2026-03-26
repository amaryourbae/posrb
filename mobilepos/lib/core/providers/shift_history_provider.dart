import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/shift.dart';
import '../services/dio_service.dart';

class ShiftHistoryState {
  final bool isLoading;
  final List<Shift> shifts;
  final int currentPage;
  final int lastPage;
  final int total;
  final String? error;

  ShiftHistoryState({
    this.isLoading = false,
    this.shifts = const [],
    this.currentPage = 1,
    this.lastPage = 1,
    this.total = 0,
    this.error,
  });

  factory ShiftHistoryState.initial() {
    return ShiftHistoryState();
  }

  ShiftHistoryState copyWith({
    bool? isLoading,
    List<Shift>? shifts,
    int? currentPage,
    int? lastPage,
    int? total,
    String? error,
  }) {
    return ShiftHistoryState(
      isLoading: isLoading ?? this.isLoading,
      shifts: shifts ?? this.shifts,
      currentPage: currentPage ?? this.currentPage,
      lastPage: lastPage ?? this.lastPage,
      total: total ?? this.total,
      error: error ?? this.error,
    );
  }
}

class ShiftHistoryNotifier extends StateNotifier<ShiftHistoryState> {
  final Dio _dio;

  ShiftHistoryNotifier(this._dio) : super(ShiftHistoryState.initial());

  Future<void> fetchShifts({int page = 1, String? userId}) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final Map<String, dynamic> queryParams = {'page': page};
      if (userId != null) {
        queryParams['user_id'] = userId;
      }

      final response = await _dio.get(
        '/admin/shifts',
        queryParameters: queryParams,
      );

      var data = response.data;
      // Handle API Resource wrapper: { data: { data: [...], meta: ... } }
      if (data is Map<String, dynamic> &&
          data.containsKey('data') &&
          data['data'] is! List) {
        data = data['data'];
      }

      final paginated = PaginatedShifts.fromJson(data);

      state = state.copyWith(
        isLoading: false,
        shifts: paginated.data,
        currentPage: paginated.currentPage,
        lastPage: paginated.lastPage,
        total: paginated.total,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final shiftHistoryProvider =
    StateNotifierProvider<ShiftHistoryNotifier, ShiftHistoryState>((ref) {
      return ShiftHistoryNotifier(ref.watch(dioProvider));
    });
