import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/api_constants.dart';
import '../storage/secure_storage.dart';

// dio HTTP client з JWT Interceptor (автоматичне оновлення токена при 401)
class ApiService {
  ApiService._();
  static final ApiService instance = ApiService._();
  static final _storage = const FlutterSecureStorage(
    webOptions: WebOptions(dbName: 'medcare_auth', publicKey: 'medcare_key'),
  );

  late final Dio _dio;

  void init() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: ApiConstants.connectTimeout,
      receiveTimeout: ApiConstants.receiveTimeout,
      headers: {'Content-Type': 'application/json'},
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await SecureStorage.instance.getAccessToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        // 401 → автоматичне оновлення JWT через Refresh Token Rotation
        if (error.response?.statusCode == 401) {
          final refreshToken = await SecureStorage.instance.getRefreshToken();
          if (refreshToken != null) {
            try {
              final response = await _dio.post(
                ApiConstants.refresh,
                data: {'refreshToken': refreshToken},
                options: Options(headers: {'Authorization': ''}),
              );
              final newAccessToken = response.data['accessToken'];
              final newRefreshToken = response.data['refreshToken'];
              await SecureStorage.instance.saveTokens(
                accessToken: newAccessToken,
                refreshToken: newRefreshToken,
              );
              // Retry original request
              error.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
              final retried = await _dio.fetch(error.requestOptions);
              return handler.resolve(retried);
            } catch (_) {
              await SecureStorage.instance.clearAll();
            }
          }
        }
        return handler.next(error);
      },
    ));
  }

  Dio get dio => _dio;

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) =>
      _dio.get(path, queryParameters: queryParameters);

  Future<Response> post(String path, {dynamic data}) => _dio.post(path, data: data);

  Future<Response> patch(String path, {dynamic data}) => _dio.patch(path, data: data);

  Future<Response> delete(String path) => _dio.delete(path);
}
