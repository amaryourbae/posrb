import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/dio_service.dart';

class ShiftDetailState {
  final bool isLoading;
  final Map<String, dynamic>? detail;
  final String? error;

  ShiftDetailState({this.isLoading = false, this.detail, this.error});

  ShiftDetailState copyWith({
    bool? isLoading,
    Map<String, dynamic>? detail,
    String? error,
  }) {
    return ShiftDetailState(
      isLoading: isLoading ?? this.isLoading,
      detail: detail ?? this.detail,
      error: error,
    );
  }
}

class ShiftDetailNotifier extends StateNotifier<ShiftDetailState> {
  final Ref ref;

  ShiftDetailNotifier(this.ref) : super(ShiftDetailState());

  Future<void> fetchDetail(String shiftId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final dio = ref.read(dioProvider);
      final response = await dio.get('/admin/shifts/$shiftId');

      if (response.statusCode == 200) {
        state = state.copyWith(isLoading: false, detail: response.data['data']);
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response.data['message'] ?? 'Failed to fetch shift details',
        );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final shiftDetailProvider =
    StateNotifierProvider.family<ShiftDetailNotifier, ShiftDetailState, String>(
      (ref, shiftId) {
        final notifier = ShiftDetailNotifier(ref);
        notifier.fetchDetail(shiftId);
        return notifier;
      },
    );
