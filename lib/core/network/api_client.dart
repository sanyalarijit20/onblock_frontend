import 'package:dio/dio.dart';
import '../auth/secure_storage.dart';
import '../config/app_config.dart';

class ApiClient {
  late Dio _dio;
  final SecureStorage _storage = SecureStorage();

  ApiClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // This Interceptor grabs the token from storage and adds it to headers automatically.
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.getJwt();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          // If we get a 401 Unauthorized, we might want to trigger a logout
          if (e.response?.statusCode == 401) {
            await _storage.logout();
            // I think we should add logic here to redirect to login screen, lets keep it work in progress for now
          }
          return handler.next(e);
        },
      ),
    );
  }

  // GET Request
  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      return await _dio.get(path, queryParameters: queryParameters);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // POST Request
  Future<Response> post(String path, {dynamic data}) async {
    try {
      return await _dio.post(path, data: data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Custom error handling to match backend's response.js utility
  String _handleError(DioException e) {
    if (e.response != null) {
      // Tries to pull the 'message' from backend's errorResponse
      return e.response?.data['message'] ?? "Server Error: ${e.response?.statusCode}";
    }
    return "Connection Error: Check your Fedora network settings.";
  }
}