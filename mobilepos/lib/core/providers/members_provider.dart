import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/member.dart';
import '../services/dio_service.dart';

class MembersState {
  final bool isLoading;
  final List<Member> members;
  final int currentPage;
  final int lastPage;
  final int total;
  final String searchQuery;
  final String? error;

  MembersState({
    this.isLoading = false,
    this.members = const [],
    this.currentPage = 1,
    this.lastPage = 1,
    this.total = 0,
    this.searchQuery = '',
    this.error,
  });

  factory MembersState.initial() {
    return MembersState();
  }

  MembersState copyWith({
    bool? isLoading,
    List<Member>? members,
    int? currentPage,
    int? lastPage,
    int? total,
    String? searchQuery,
    String? error,
  }) {
    return MembersState(
      isLoading: isLoading ?? this.isLoading,
      members: members ?? this.members,
      currentPage: currentPage ?? this.currentPage,
      lastPage: lastPage ?? this.lastPage,
      total: total ?? this.total,
      searchQuery: searchQuery ?? this.searchQuery,
      error: error ?? this.error,
    );
  }
}

class MembersNotifier extends StateNotifier<MembersState> {
  final Dio _dio;

  MembersNotifier(this._dio) : super(MembersState.initial());

  Future<void> fetchMembers({int page = 1, String? search}) async {
    state = state.copyWith(
      isLoading: true,
      searchQuery: search ?? state.searchQuery,
      error: null,
    );

    try {
      final response = await _dio.get(
        '/admin/customers',
        queryParameters: {
          'page': page,
          'search': search ?? state.searchQuery,
          'per_page': 12,
        },
      );

      var data = response.data;
      if (data is Map<String, dynamic> &&
          data.containsKey('data') &&
          data['data'] is! List) {
        data = data['data'];
      }

      final paginated = PaginatedMembers.fromJson(data);

      state = state.copyWith(
        isLoading: false,
        members: paginated.data,
        currentPage: paginated.currentPage,
        lastPage: paginated.lastPage,
        total: paginated.total,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> createMember(Map<String, dynamic> data) async {
    try {
      await _dio.post('/admin/customers', data: data);
      await fetchMembers(page: state.currentPage);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> updateMember(String id, Map<String, dynamic> data) async {
    try {
      await _dio.put('/admin/customers/$id', data: data);
      await fetchMembers(page: state.currentPage);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> deleteMember(String id) async {
    try {
      await _dio.delete('/admin/customers/$id');
      await fetchMembers(page: state.currentPage);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }
}

final membersProvider = StateNotifierProvider<MembersNotifier, MembersState>((
  ref,
) {
  return MembersNotifier(ref.read(dioProvider));
});
