import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/constants/api_constants.dart';
import '../models/login_response_model.dart';
import '../models/user_model.dart';
import 'storage_service.dart';

/// Thin wrapper around Dio so API calls share one base configuration.
class ApiService {
  ApiService._internal() {
    _dio.interceptors.add(
      LogInterceptor(
        request: true,
        requestHeader: true,
        requestBody: true,
        responseHeader: false,
        responseBody: true,
        error: true,
        logPrint: (object) => debugPrint(object.toString()),
      ),
    );
  }

  static final ApiService instance = ApiService._internal();

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(milliseconds: ApiConstants.connectTimeout),
      receiveTimeout: const Duration(milliseconds: ApiConstants.receiveTimeout),
      headers: const {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ),
  );

  final StorageService _storage = StorageService.instance;

  /// Basic GET helper for endpoints that only need query parameters.
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    await _restoreAuthToken();
    return await _dio.get(path, queryParameters: queryParameters);
  }

  /// Basic POST helper for endpoints that send a request body.
  Future<Response> post(String path, {dynamic data}) async {
    await _restoreAuthToken();
    return await _dio.post(path, data: data);
  }

  /// Authenticates the user against the login endpoint.
  Future<LoginResponseModel> login({
    required String email,
    required String password,
  }) async {
    // final request = LoginRequestModel(email: email, password: password);
    // final response = await post(ApiConstants.login, data: request.toJson());
    // final body = _normalizeMap(response.data);
    if (email != ApiConstants.dummyLoginEmail ||
        password != ApiConstants.dummyLoginPassword) {
      throw DioException(
        requestOptions: RequestOptions(path: ApiConstants.login),
        response: Response(
          requestOptions: RequestOptions(path: ApiConstants.login),
          statusCode: 401,
          data: <String, dynamic>{
            'message':
                'Use ${ApiConstants.dummyLoginEmail} / ${ApiConstants.dummyLoginPassword} to login.',
          },
        ),
        type: DioExceptionType.badResponse,
      );
    }

    final loginResponse = LoginResponseModel.fromJson(<String, dynamic>{
      'message': 'Logged in with local dummy credentials.',
      'token': 'dummy-auth-token',
      'user': <String, dynamic>{
        'id': '1',
        'name': 'Demo User',
        'email': ApiConstants.dummyLoginEmail,
        'role': 'admin',
      },
    });

    await _persistAuth(loginResponse);
    return loginResponse;
  }

  Future<void> _persistAuth(LoginResponseModel response) async {
    await _storage.ensureInitialized();

    if (response.token != null && response.token!.isNotEmpty) {
      await _storage.setString(StorageService.authTokenKey, response.token!);
      _dio.options.headers['Authorization'] = 'Bearer ${response.token!}';
    }

    await _storage.setString(
      StorageService.currentUserKey,
      response.user.toRawJson(),
    );
  }

  Future<void> _persistUser(UserModel user) async {
    await _storage.ensureInitialized();
    await _storage.setString(StorageService.currentUserKey, user.toRawJson());
  }

  Future<void> _restoreAuthToken() async {
    await _storage.ensureInitialized();
    final token = _storage.getString(StorageService.authTokenKey);
    if (token != null && token.isNotEmpty) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    }
  }

  Future<void> _clearAuthData() async {
    await _storage.ensureInitialized();
    await _storage.remove(StorageService.authTokenKey);
    await _storage.remove(StorageService.currentUserKey);
    _dio.options.headers.remove('Authorization');
  }

  Map<String, dynamic> _normalizeMap(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data;
    }

    if (data is Map) {
      return data.map(
        (key, value) => MapEntry(key.toString(), value),
      );
    }

    throw DioException(
      requestOptions: RequestOptions(path: ApiConstants.login),
      error: 'Unexpected API response format',
      type: DioExceptionType.unknown,
    );
  }

  /// Returns the persisted user if one is available locally.
  Future<UserModel?> getStoredUser() async {
    await _storage.ensureInitialized();
    final rawUser = _storage.getString(StorageService.currentUserKey);
    if (rawUser == null || rawUser.isEmpty) {
      return null;
    }

    return UserModel.fromRawJson(rawUser);
  }

  /// Loads the authenticated user from the API and refreshes local cache.
  Future<UserModel> getCurrentUser() async {
    final response = await get(ApiConstants.user);
    final body = _normalizeMap(response.data);
    final user = UserModel.fromJson(body);
    await _persistUser(user);
    return user;
  }

  /// Logs out the current user and clears the locally cached auth state.
  Future<void> logout() async {
    try {
      await post(ApiConstants.logout);
    } finally {
      await _clearAuthData();
    }
  }
}
