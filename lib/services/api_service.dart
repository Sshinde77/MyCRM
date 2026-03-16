import 'package:dio/dio.dart';
import '../core/constants/api_constants.dart';

/// Thin wrapper around Dio so API calls share one base configuration.
class ApiService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(milliseconds: ApiConstants.connectTimeout),
      receiveTimeout: const Duration(milliseconds: ApiConstants.receiveTimeout),
    ),
  );

  /// Basic GET helper for endpoints that only need query parameters.
  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    return await _dio.get(path, queryParameters: queryParameters);
  }

  /// Basic POST helper for endpoints that send a request body.
  Future<Response> post(String path, {dynamic data}) async {
    return await _dio.post(path, data: data);
  }
}
