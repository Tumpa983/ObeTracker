import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late final Dio _dio;
  final _storage = const FlutterSecureStorage();

  ApiClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout: AppConstants.connectTimeout,
        receiveTimeout: AppConstants.receiveTimeout,
        headers: {'Content-Type': 'application/json'},
      ),
    );

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: AppConstants.tokenKey);
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onResponse: (response, handler) => handler.next(response),
      onError: (error, handler) {
        handler.next(error);
      },
    ));
  }

  Dio get dio => _dio;

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) =>
      _dio.get(path, queryParameters: queryParameters);

  Future<Response> post(String path, {dynamic data}) => _dio.post(
        path,
        data: data,
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

  Future<Response> put(String path, {dynamic data}) => _dio.put(
        path,
        data: data,
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

  Future<Response> delete(String path) => _dio.delete(path);

  Future<Response> uploadFile(String path, FormData formData) =>
      _dio.post(path, data: formData,
          options: Options(headers: {'Content-Type': 'multipart/form-data'}));

  Future<void> saveToken(String token) =>
      _storage.write(key: AppConstants.tokenKey, value: token);

  Future<void> clearToken() => _storage.delete(key: AppConstants.tokenKey);

  Future<String?> getToken() => _storage.read(key: AppConstants.tokenKey);
}
