import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../services/dio_service.dart';

class AuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final String? error;
  final Map<String, dynamic>? user;
  final Map<String, dynamic>? settings;
  final bool otpSent;

  AuthState({
    this.isLoading = false,
    this.isAuthenticated = false,
    this.error,
    this.user,
    this.settings,
    this.otpSent = false,
  });

  AuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    String? error,
    Map<String, dynamic>? user,
    Map<String, dynamic>? settings,
    bool? otpSent,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      error: error,
      user: user ?? this.user,
      settings: settings ?? this.settings,
      otpSent: otpSent ?? this.otpSent,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final Dio _dio;

  AuthNotifier(this._dio) : super(AuthState()) {
    checkLoginStatus();
    fetchSettings();
  }

  Future<void> checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token != null) {
      state = state.copyWith(isLoading: true);
      try {
        // Validate token by fetching user profile
        final response = await _dio.get('/user');

        dynamic userData = response.data;
        if (userData is Map<String, dynamic> && userData.containsKey('data')) {
          userData = userData['data'];
        }

        state = state.copyWith(
          isAuthenticated: true,
          user: userData,
          isLoading: false,
        );
      } catch (e) {
        // Token invalid or expired
        await prefs.remove('token');
        state = state.copyWith(
          isAuthenticated: false,
          user: null,
          isLoading: false,
        );
      }
    } else {
      state = state.copyWith(isLoading: false, isAuthenticated: false);
    }
  }

  Future<void> fetchSettings() async {
    try {
      final response = await _dio.get('/public/settings');
      dynamic settingsData = response.data;
      if (settingsData is Map<String, dynamic> &&
          settingsData.containsKey('data')) {
        settingsData = settingsData['data'];
      }
      debugPrint('Fetched Settings: $settingsData');
      state = state.copyWith(settings: settingsData);
    } catch (e) {
      // Silent fail or default
      debugPrint('Error fetching settings: $e');
    }
  }

  Future<void> login({
    required String method, // 'email' or 'whatsapp'
    String? email,
    String? password,
    String? phone,
    String? otp,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final payload = <String, dynamic>{};

      if (method == 'email') {
        payload['email'] = email;
        payload['password'] = password;
      } else {
        payload['phone'] = phone;
        payload['is_otp'] = true;
        if (otp != null) {
          payload['otp'] = otp;
        }
      }

      final response = await _dio.post('/login', data: payload);

      dynamic resData = response.data;

      // Unwrap if needed
      if (resData is Map<String, dynamic> && resData.containsKey('data')) {
        // But wait, standard login response might be flat { token: ... } or wrapped { data: { token: ... } }
        // If wrapped, we unwrap.
        // Note: "is_otp_sent" might be in wrapper OR in data?
        // Laravel Resource usually puts everything in data.
        // If resData has 'data', use it.
        if (resData['data'] != null) {
          resData = resData['data'];
        }
      }

      // Check for OTP Sent response
      if (resData is Map && resData['is_otp_sent'] == true) {
        state = state.copyWith(isLoading: false, otpSent: true);
        return;
      }

      final token = resData['token'];
      final user = resData['user'];

      if (token == null) {
        throw Exception("Login failed: No token returned");
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token);

      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        user: user,
        otpSent: false, // Reset
      );
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.response?.data['message'] ?? 'Login failed',
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    state = AuthState();
    // Re-fetch settings maybe?
    fetchSettings();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final dio = ref.watch(dioProvider);
  return AuthNotifier(dio);
});
