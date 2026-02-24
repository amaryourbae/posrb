import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

/// Base URL for API requests
String get apiBaseUrl => AppConfig.apiUrl;

/// Base URL for storage/media files (without /api)
String get storageBaseUrl => AppConfig.baseUrl;

/// Convert a relative storage path to full URL
/// Uses storage-proxy API endpoint for Flutter web CORS support
String? getFullImageUrl(String? path) {
  if (path == null || path.isEmpty) return null;
  if (path.startsWith('http')) return path;

  // Use the storage-proxy API route which has proper CORS headers
  // This proxies: /storage/products/xxx.jpg -> /api/storage-proxy?path=storage/products/xxx.jpg
  final relativePath = path.startsWith('/') ? path.substring(1) : path;
  return '$apiBaseUrl/storage-proxy?path=$relativePath';
}

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      // Ensure this matches your Laravel local IP or localhost
      baseUrl: apiBaseUrl,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) async {
        if (e.response?.statusCode == 401) {
          // Clear token from storage
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('token');
          // Note: We can't easily access Ref here to update AuthProvider state directly
          // without passing it in. But clearing the token means the next app restart
          // or checkLoginStatus will fail.
          // Ideally, we'd use a broadcast stream or similar to notify app of logout.
        }
        return handler.next(e);
      },
    ),
  );

  return dio;
});
