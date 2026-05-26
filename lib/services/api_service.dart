import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:convert';

import '../core/constants/api_constants.dart';
import '../models/login_request_model.dart';
import '../models/login_response_model.dart';
import '../models/client_model.dart';
import '../models/client_detail_model.dart';
import '../models/create_client_request_model.dart';
import '../models/lead_form_options_model.dart';
import '../models/lead_model.dart';
import '../models/project_form_options_model.dart';
import '../models/project_issue_model.dart';
import '../models/project_model.dart';
import '../models/project_detail_model.dart';
import '../models/project_usage_model.dart';
import '../models/project_comment_model.dart';
import '../models/project_milestone_model.dart';
import '../models/role_model.dart';
import '../models/update_client_request_model.dart';
import '../models/staff_member_model.dart';
import '../models/user_model.dart';
import '../models/calendar_event_model.dart';
import '../models/career_enquiry_model.dart';
import '../models/contact_enquiry_model.dart';
import '../models/client_issue_model.dart';
import '../models/client_issue_task_model.dart';
import '../models/company_information_model.dart';
import '../models/dashboard_data_model.dart';
import '../models/department_setting_model.dart';
import '../models/email_settings_model.dart';
import '../models/renewal_settings_model.dart';
import '../models/renewal_model.dart';
import '../models/team_setting_model.dart';
import '../models/vendor_model.dart';
import '../models/quick_stats_model.dart';
import '../core/services/secure_storage_service.dart';

/// Thin wrapper around Dio so API calls share one base configuration.
class StaffListPageResult {
  const StaffListPageResult({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.total,
    required this.perPage,
    required this.hasNextPage,
  });

  final List<StaffMemberModel> items;
  final int currentPage;
  final int lastPage;
  final int total;
  final int perPage;
  final bool hasNextPage;
}

class ClientListPageResult {
  const ClientListPageResult({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.total,
    required this.perPage,
    required this.hasNextPage,
  });

  final List<ClientModel> items;
  final int currentPage;
  final int lastPage;
  final int total;
  final int perPage;
  final bool hasNextPage;
}

class RenewalListPageResult {
  const RenewalListPageResult({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.total,
    required this.perPage,
    required this.hasNextPage,
  });

  final List<RenewalModel> items;
  final int currentPage;
  final int lastPage;
  final int total;
  final int perPage;
  final bool hasNextPage;
}

class VendorListPageResult {
  const VendorListPageResult({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.total,
    required this.perPage,
    required this.hasNextPage,
  });

  final List<VendorModel> items;
  final int currentPage;
  final int lastPage;
  final int total;
  final int perPage;
  final bool hasNextPage;
}

class LeadListPageResult {
  const LeadListPageResult({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.total,
    required this.perPage,
    required this.hasNextPage,
  });

  final List<LeadModel> items;
  final int currentPage;
  final int lastPage;
  final int total;
  final int perPage;
  final bool hasNextPage;
}

class ProjectListPageResult {
  const ProjectListPageResult({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.total,
    required this.perPage,
    required this.hasNextPage,
  });

  final List<ProjectModel> items;
  final int currentPage;
  final int lastPage;
  final int total;
  final int perPage;
  final bool hasNextPage;
}

class TaskListPageResult {
  const TaskListPageResult({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.total,
    required this.perPage,
    required this.hasNextPage,
    required this.statusCounts,
  });

  final List<Map<String, dynamic>> items;
  final int currentPage;
  final int lastPage;
  final int total;
  final int perPage;
  final bool hasNextPage;
  final Map<String, int> statusCounts;
}

class MapListPageResult {
  const MapListPageResult({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.total,
    required this.perPage,
    required this.hasNextPage,
  });

  final List<Map<String, dynamic>> items;
  final int currentPage;
  final int lastPage;
  final int total;
  final int perPage;
  final bool hasNextPage;
}

class NotificationListPageResult {
  const NotificationListPageResult({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.total,
    required this.perPage,
    required this.hasNextPage,
    required this.unreadCount,
  });

  final List<Map<String, dynamic>> items;
  final int currentPage;
  final int lastPage;
  final int total;
  final int perPage;
  final bool hasNextPage;
  final int unreadCount;
}

class CareerEnquiryListPageResult {
  const CareerEnquiryListPageResult({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.total,
    required this.perPage,
    required this.hasNextPage,
  });

  final List<CareerEnquiryModel> items;
  final int currentPage;
  final int lastPage;
  final int total;
  final int perPage;
  final bool hasNextPage;
}

class ContactEnquiryListPageResult {
  const ContactEnquiryListPageResult({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.total,
    required this.perPage,
    required this.hasNextPage,
  });

  final List<ContactEnquiryModel> items;
  final int currentPage;
  final int lastPage;
  final int total;
  final int perPage;
  final bool hasNextPage;
}

class LeadDashboardCount {
  const LeadDashboardCount({
    required this.todayCount,
    required this.totalCount,
  });

  final int todayCount;
  final int totalCount;
}

class LeadDashboardResult {
  const LeadDashboardResult({
    required this.recentLeads,
    required this.leadsCount,
    required this.bookCallsCount,
    required this.digitalMarketingLeadsCount,
    required this.webAppLeadsCount,
  });

  final List<LeadModel> recentLeads;
  final LeadDashboardCount leadsCount;
  final LeadDashboardCount bookCallsCount;
  final LeadDashboardCount digitalMarketingLeadsCount;
  final LeadDashboardCount webAppLeadsCount;
}

class ClientRenewalFormOptionsResult {
  const ClientRenewalFormOptionsResult({
    required this.clients,
    required this.vendors,
    required this.statuses,
  });

  final List<ClientModel> clients;
  final List<VendorModel> vendors;
  final List<String> statuses;
}

class ApiService {
  ApiService._internal() {
    _dio.interceptors.add(_buildAuthInterceptor());

    if (kDebugMode) {
      _dio.interceptors.add(_buildDebugLoggingInterceptor());
    }
  }

  static final ApiService instance = ApiService._internal();

  Interceptor _buildAuthInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) async {
        if (options.extra['skip_auth'] == true ||
            _isAuthEndpoint(options.path)) {
          options.headers.remove('Authorization');
          handler.next(options);
          return;
        }

        await _restoreAuthToken();
        final token = await _currentAccessToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }

        handler.next(options);
      },
      onError: (error, handler) async {
        final statusCode = error.response?.statusCode;
        final requestOptions = error.requestOptions;

        if (statusCode != 401 ||
            requestOptions.extra['auth_retry'] == true ||
            _isAuthEndpoint(requestOptions.path)) {
          handler.next(error);
          return;
        }

        final refreshed = await _refreshTokensIfPossible();
        if (!refreshed) {
          handler.next(error);
          return;
        }

        final token = await _currentAccessToken();
        if (token == null || token.isEmpty) {
          handler.next(error);
          return;
        }

        requestOptions.extra['auth_retry'] = true;
        requestOptions.headers['Authorization'] = 'Bearer $token';

        try {
          final response = await _dio.fetch(requestOptions);
          handler.resolve(response);
        } catch (retryError) {
          handler.next(
            retryError is DioException
                ? retryError
                : DioException(
                    requestOptions: requestOptions,
                    error: retryError,
                    type: DioExceptionType.unknown,
                  ),
          );
        }
      },
    );
  }

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(milliseconds: ApiConstants.connectTimeout),
      receiveTimeout: const Duration(milliseconds: ApiConstants.receiveTimeout),
      headers: const {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'X-Requested-With': 'XMLHttpRequest',
      },
    ),
  );

  final SecureStorageService _storage = SecureStorageService.instance;
  final Map<String, Future<Response>> _inFlightGetRequests =
      <String, Future<Response>>{};
  String? _cachedAccessToken;
  bool _authTokenLoaded = false;
  final Duration _staffListCacheTtl = const Duration(seconds: 30);
  final Duration _staffOptionsCacheTtl = const Duration(minutes: 5);
  List<StaffMemberModel>? _staffListCache;
  DateTime? _staffListCacheAt;
  List<DepartmentSettingModel>? _staffDepartmentsCache;
  DateTime? _staffDepartmentsCacheAt;
  List<TeamSettingModel>? _staffTeamsCache;
  DateTime? _staffTeamsCacheAt;

  Interceptor _buildDebugLoggingInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) {
        debugPrint('*** API Calling ***');
        debugPrint('${options.method} ${options.uri}');
        final authorization = options.headers['Authorization']?.toString();
        final authState = authorization == null || authorization.trim().isEmpty
            ? 'missing'
            : _maskAuthorizationHeader(authorization);
        debugPrint('auth: $authState');
        if (options.queryParameters.isNotEmpty) {
          debugPrint('query: ${_summarizeForLog(options.queryParameters)}');
        }
        if (options.data != null) {
          debugPrint('request: ${_summarizeForLog(options.data)}');
        }
        handler.next(options);
      },
      onResponse: (response, handler) {
        debugPrint('*** API Response ***');
        debugPrint(
          '${response.requestOptions.method} ${response.requestOptions.uri}',
        );
        debugPrint('status: ${response.statusCode}');
        debugPrint('response: ${_summarizeForLog(response.data)}');
        handler.next(response);
      },
      onError: (error, handler) {
        debugPrint('*** API Error ***');
        debugPrint(
          '${error.requestOptions.method} ${error.requestOptions.uri}',
        );
        debugPrint('status: ${error.response?.statusCode ?? 'N/A'}');
        final redirectLocation = error.response?.headers.value('location');
        if (redirectLocation != null && redirectLocation.trim().isNotEmpty) {
          debugPrint('redirect: $redirectLocation');
        }
        debugPrint('message: ${error.message ?? error.error}');
        if (error.response?.data != null) {
          debugPrint('response: ${_summarizeForLog(error.response?.data)}');
        }
        handler.next(error);
      },
    );
  }

  String _summarizeForLog(dynamic value, {int maxChars = 1200}) {
    final text = _sanitizeForLog(value).toString();
    return _truncateForLogText(text, maxChars: maxChars);
  }

  String _truncateForLogText(String text, {int maxChars = 1200}) {
    if (text.length <= maxChars) return text;
    final omitted = text.length - maxChars;
    return '${text.substring(0, maxChars)}... (truncated +$omitted chars)';
  }

  dynamic _sanitizeForLog(dynamic value, {int depth = 0}) {
    if (depth > 4) return '...';

    if (value is FormData) {
      return {
        'fields': {
          for (final field in value.fields)
            field.key: _sanitizeForLogField(
              field.key,
              field.value,
              depth: depth,
            ),
        },
        'files': [
          for (final file in value.files)
            {'field': file.key, 'filename': file.value.filename},
        ],
      };
    }

    if (value is Map) {
      var count = 0;
      return value.map((key, entryValue) {
        count += 1;
        if (count > 30) {
          return MapEntry(key.toString(), '...truncated');
        }
        return MapEntry(
          key.toString(),
          _sanitizeForLogField(key.toString(), entryValue, depth: depth + 1),
        );
      });
    }

    if (value is Iterable) {
      var count = 0;
      return value
          .map((entry) {
            count += 1;
            if (count > 20) return '...truncated';
            return _sanitizeForLog(entry, depth: depth + 1);
          })
          .toList(growable: false);
    }

    return value;
  }

  dynamic _sanitizeForLogField(String key, dynamic value, {int depth = 0}) {
    final normalizedKey = key.toLowerCase();
    if (normalizedKey.contains('password') ||
        normalizedKey.contains('token') ||
        normalizedKey == 'authorization') {
      return '***';
    }
    return _sanitizeForLog(value, depth: depth + 1);
  }

  bool _isCacheFresh(DateTime? at, Duration ttl) {
    if (at == null) return false;
    return DateTime.now().difference(at) < ttl;
  }

  void _invalidateStaffCaches() {
    _staffListCache = null;
    _staffListCacheAt = null;
    _staffDepartmentsCache = null;
    _staffDepartmentsCacheAt = null;
    _staffTeamsCache = null;
    _staffTeamsCacheAt = null;
  }

  bool _isAuthEndpoint(String path) {
    final normalized = path.toLowerCase();
    return normalized.contains('/login') || normalized.contains('/refresh');
  }

  Future<bool> _refreshTokensIfPossible() async {
    try {
      final refreshToken = await _storage.read(
        SecureStorageService.refreshTokenKey,
      );
      if (refreshToken == null || refreshToken.trim().isEmpty) {
        await _clearAuthData();
        return false;
      }

      final response = await _dio.post(
        ApiConstants.refreshToken,
        data: {'refresh_token': refreshToken},
        options: Options(
          headers: const {'Authorization': null},
          extra: const {'skip_auth': true},
        ),
      );

      final body = _normalizeMap(response.data);
      final tokenSource = _extractTokenSource(body);
      final accessToken = _readNullableString(tokenSource, const [
        'access_token',
        'accessToken',
        'token',
        'jwt',
      ]);
      final newRefreshToken = _readNullableString(tokenSource, const [
        'refresh_token',
        'refreshToken',
      ]);

      if (accessToken == null || accessToken.trim().isEmpty) {
        await _clearAuthData();
        return false;
      }

      await _storage.write(SecureStorageService.accessTokenKey, accessToken);
      if (newRefreshToken != null && newRefreshToken.trim().isNotEmpty) {
        await _storage.write(
          SecureStorageService.refreshTokenKey,
          newRefreshToken.trim(),
        );
      }

      _dio.options.headers['Authorization'] = 'Bearer $accessToken';
      _cachedAccessToken = accessToken;
      _authTokenLoaded = true;
      _debugAuthState('Token refreshed', accessToken);
      return true;
    } on DioException {
      await _clearAuthData();
      return false;
    } catch (_) {
      await _clearAuthData();
      return false;
    }
  }

  String? _readNullableString(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }
    return null;
  }

  Map<String, dynamic> _extractTokenSource(Map<String, dynamic> json) {
    final nestedData = json['data'];
    if (nestedData is Map<String, dynamic>) {
      return nestedData;
    }
    if (nestedData is Map) {
      return nestedData.map((key, value) => MapEntry(key.toString(), value));
    }
    return json;
  }

  /// Basic GET helper for endpoints that only need query parameters.
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    await _prepareAuthForPath(path);
    final requestKey = _buildGetRequestKey(path, queryParameters);
    final inFlight = _inFlightGetRequests[requestKey];
    if (inFlight != null) {
      return await inFlight;
    }

    final future = _dio.get(path, queryParameters: queryParameters);
    _inFlightGetRequests[requestKey] = future;
    try {
      return await future;
    } finally {
      if (identical(_inFlightGetRequests[requestKey], future)) {
        _inFlightGetRequests.remove(requestKey);
      }
    }
  }

  /// Basic POST helper for endpoints that send a request body.
  Future<Response> post(String path, {dynamic data}) async {
    await _prepareAuthForPath(path);
    return await _dio.post(path, data: data);
  }

  /// Basic PUT helper for endpoints that update an existing record.
  Future<Response> put(String path, {dynamic data}) async {
    await _prepareAuthForPath(path);
    return await _dio.put(path, data: data);
  }

  /// Basic DELETE helper for endpoints that remove a record.
  Future<Response> delete(String path, {dynamic data}) async {
    await _prepareAuthForPath(path);
    return await _dio.delete(path, data: data);
  }

  /// Basic PATCH helper for endpoints that partially update a record.
  Future<Response> patch(String path, {dynamic data}) async {
    await _prepareAuthForPath(path);
    return await _dio.patch(path, data: data);
  }

  /// Multipart POST helper for endpoints that accept form-data payloads.
  Future<Response> postForm(String path, {required FormData data}) async {
    await _prepareAuthForPath(path);
    _debugLogFormData(path: path, data: data);
    return await _dio.post(
      path,
      data: data,
      options: Options(contentType: Headers.multipartFormDataContentType),
    );
  }

  /// Multipart PUT helper for endpoints that accept form-data payloads.
  Future<Response> putForm(String path, {required FormData data}) async {
    await _prepareAuthForPath(path);
    return await _dio.put(
      path,
      data: data,
      options: Options(contentType: Headers.multipartFormDataContentType),
    );
  }

  Future<Response> _requestSettingsJson({
    required String path,
    required String method,
    required Map<String, dynamic> payload,
  }) async {
    switch (method) {
      case 'put':
        return await put(path, data: payload);
      case 'patch':
        return await patch(path, data: payload);
      case 'post':
      default:
        return await post(path, data: payload);
    }
  }

  Future<Response> _requestSettingsMultipart({
    required String path,
    required String method,
    required FormData formData,
  }) async {
    await _prepareAuthForPath(path);
    switch (method) {
      case 'put':
        return await putForm(path, data: formData);
      case 'patch':
        return await _dio.patch(
          path,
          data: formData,
          options: Options(contentType: Headers.multipartFormDataContentType),
        );
      case 'post':
      default:
        return await postForm(path, data: formData);
    }
  }

  /// Authenticates the user against the login endpoint.
  Future<LoginResponseModel> login({
    required String email,
    required String password,
  }) async {
    final request = LoginRequestModel(email: email, password: password);
    final response = await post(ApiConstants.login, data: request.toJson());
    final body = _normalizeMap(response.data);
    final loginResponse = LoginResponseModel.fromJson(body);

    await _persistAuth(loginResponse);
    return loginResponse;
  }

  /// Syncs the current device FCM token to backend for the authenticated user.
  Future<dynamic> syncFcmToken({
    required String token,
    required String userId,
    required Map<String, dynamic> deviceInfo,
    String event = 'login',
  }) async {
    final normalizedToken = token.trim();
    if (normalizedToken.isEmpty) return;
    final normalizedUserId = userId.trim();
    if (normalizedUserId.isEmpty) return;
    final normalizedDeviceId =
        (deviceInfo['device_id']?.toString() ?? normalizedUserId).trim();
    final normalizedPlatform = (deviceInfo['platform']?.toString() ?? 'unknown')
        .trim();

    final response = await post(
      ApiConstants.testFcm,
      data: <String, dynamic>{
        'fcm_token': normalizedToken,
        'device_id': normalizedDeviceId,
        'platform': normalizedPlatform,
      },
    );
    return response.data;
  }

  /// Notifies backend to detach FCM token when user logs out from this device.
  Future<dynamic> unlinkFcmToken({
    required String token,
    required String userId,
    required Map<String, dynamic> deviceInfo,
  }) async {
    final normalizedToken = token.trim();
    final normalizedUserId = userId.trim();
    if (normalizedToken.isEmpty || normalizedUserId.isEmpty) return;
    final normalizedDeviceId =
        (deviceInfo['device_id']?.toString() ?? normalizedUserId).trim();
    final normalizedPlatform = (deviceInfo['platform']?.toString() ?? 'unknown')
        .trim();

    final response = await post(
      ApiConstants.testFcm,
      data: <String, dynamic>{
        'fcm_token': normalizedToken,
        'device_id': normalizedDeviceId,
        'platform': normalizedPlatform,
      },
    );
    return response.data;
  }

  Future<void> _persistAuth(LoginResponseModel response) async {
    await _storage.migrateLegacyPrefsIfNeeded();

    final accessToken = response.accessToken;
    if (accessToken != null && accessToken.trim().isNotEmpty) {
      final normalizedAccessToken = accessToken.trim();
      await _storage.write(
        SecureStorageService.accessTokenKey,
        normalizedAccessToken,
      );
      _dio.options.headers['Authorization'] = 'Bearer $normalizedAccessToken';
      _cachedAccessToken = normalizedAccessToken;
      _authTokenLoaded = true;
      _debugAuthState('Token saved after login', normalizedAccessToken);
    }

    final refreshToken = response.refreshToken;
    if (refreshToken != null && refreshToken.trim().isNotEmpty) {
      await _storage.write(
        SecureStorageService.refreshTokenKey,
        refreshToken.trim(),
      );
    }

    await _storage.write(
      SecureStorageService.currentUserKey,
      response.user.toRawJson(),
    );
  }

  Future<void> _persistUser(UserModel user) async {
    await _storage.write(SecureStorageService.currentUserKey, user.toRawJson());
  }

  Future<void> _prepareAuthForPath(String path) async {
    if (_isAuthEndpoint(path)) {
      _dio.options.headers.remove('Authorization');
      return;
    }

    await _restoreAuthToken();
  }

  Future<void> _restoreAuthToken() async {
    final headerToken = (_dio.options.headers['Authorization'] ?? '')
        .toString()
        .trim();
    if (headerToken.isNotEmpty) {
      return;
    }

    if (_authTokenLoaded) {
      if (_cachedAccessToken != null && _cachedAccessToken!.isNotEmpty) {
        _dio.options.headers['Authorization'] = 'Bearer $_cachedAccessToken';
      }
      return;
    }

    await _storage.migrateLegacyPrefsIfNeeded();
    final token = await _storage.read(SecureStorageService.accessTokenKey);
    _authTokenLoaded = true;
    _cachedAccessToken = token?.trim();
    if (token != null && token.isNotEmpty) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    }
  }

  Future<String?> _currentAccessToken() async {
    final cached = _cachedAccessToken?.trim();
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }

    await _storage.migrateLegacyPrefsIfNeeded();
    final stored = await _storage.read(SecureStorageService.accessTokenKey);
    final token = stored?.trim();
    if (token == null || token.isEmpty) {
      _cachedAccessToken = null;
      _authTokenLoaded = true;
      _dio.options.headers.remove('Authorization');
      return null;
    }

    _cachedAccessToken = token;
    _authTokenLoaded = true;
    _dio.options.headers['Authorization'] = 'Bearer $token';
    return token;
  }

  Future<void> _clearAuthData() async {
    await _storage.delete(SecureStorageService.accessTokenKey);
    await _storage.delete(SecureStorageService.refreshTokenKey);
    await _storage.delete(SecureStorageService.currentUserKey);
    _dio.options.headers.remove('Authorization');
    _cachedAccessToken = null;
    _authTokenLoaded = true;
  }

  String _buildGetRequestKey(
    String path,
    Map<String, dynamic>? queryParameters,
  ) {
    if (queryParameters == null || queryParameters.isEmpty) {
      return 'GET::$path';
    }

    final sortedEntries = queryParameters.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final query = sortedEntries
        .map((entry) => '${entry.key}=${entry.value}')
        .join('&');
    return 'GET::$path?$query';
  }

  int? _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value == null) return null;
    return int.tryParse(value.toString().trim());
  }

  /// Clears locally persisted auth data without calling the backend.
  Future<void> clearStoredAuth() async {
    await _clearAuthData();
  }

  Map<String, dynamic> _normalizeMap(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data;
    }

    if (data is Map) {
      return data.map((key, value) => MapEntry(key.toString(), value));
    }

    throw DioException(
      requestOptions: RequestOptions(path: ApiConstants.login),
      error: 'Unexpected API response format',
      type: DioExceptionType.unknown,
    );
  }

  /// Returns the persisted user if one is available locally.
  Future<UserModel?> getStoredUser() async {
    await _storage.migrateLegacyPrefsIfNeeded();
    final rawUser = await _storage.read(SecureStorageService.currentUserKey);
    if (rawUser == null || rawUser.isEmpty) {
      return null;
    }

    return UserModel.fromRawJson(rawUser);
  }

  /// Loads the authenticated user from the API and refreshes local cache.
  Future<UserModel> getCurrentUser() async {
    final response = await get(ApiConstants.user);
    final body = _normalizeMap(response.data);
    var user = UserModel.fromJson(body);
    final storedUser = await getStoredUser();
    if (user.permissions.isEmpty &&
        storedUser != null &&
        storedUser.id == user.id &&
        storedUser.permissions.isNotEmpty) {
      user = user.copyWith(permissions: storedUser.permissions);
    }
    await _persistUser(user);
    return user;
  }

  /// Loads all settings (merged response from settings module).
  Future<Map<String, dynamic>> getAllSettings() async {
    final response = await get(ApiConstants.settings);
    final body = _normalizeMap(response.data);
    final source = _extractDetailSource(body);
    return _normalizeMap(source);
  }

  /// Loads general settings from settings endpoint.
  Future<Map<String, dynamic>> getGeneralSettings() async {
    final response = await get(ApiConstants.generalSettings);
    final body = _normalizeMap(response.data);
    final source = _extractDetailSource(body);
    return _normalizeMap(source);
  }

  /// Updates general settings using JSON or multipart depending on payload.
  Future<Map<String, dynamic>> updateGeneralSettings({
    String? companyName,
    String? crmLogoPath,
    String? faviconPath,
    bool removeCrmLogo = false,
    bool removeFavicon = false,
    Map<String, dynamic> extra = const <String, dynamic>{},
  }) async {
    final normalizedCompanyName = (companyName ?? '').trim();
    final normalizedCrmLogoPath = (crmLogoPath ?? '').trim();
    final normalizedFaviconPath = (faviconPath ?? '').trim();

    if (normalizedCrmLogoPath.isNotEmpty || normalizedFaviconPath.isNotEmpty) {
      final formData = FormData();

      if (normalizedCompanyName.isNotEmpty) {
        formData.fields.add(MapEntry('company_name', normalizedCompanyName));
      }
      if (removeCrmLogo) {
        formData.fields.add(const MapEntry('remove_crm_logo', '1'));
      }
      if (removeFavicon) {
        formData.fields.add(const MapEntry('remove_favicon', '1'));
      }
      for (final entry in extra.entries) {
        final key = entry.key.trim();
        if (key.isEmpty || entry.value == null) continue;
        formData.fields.add(MapEntry(key, '${entry.value}'));
      }

      if (normalizedCrmLogoPath.isNotEmpty) {
        final logoName = normalizedCrmLogoPath.split(RegExp(r'[\\/]')).last;
        formData.files.add(
          MapEntry(
            'crm_logo',
            await MultipartFile.fromFile(
              normalizedCrmLogoPath,
              filename: logoName,
            ),
          ),
        );
      }
      if (normalizedFaviconPath.isNotEmpty) {
        final faviconName = normalizedFaviconPath.split(RegExp(r'[\\/]')).last;
        formData.files.add(
          MapEntry(
            'favicon',
            await MultipartFile.fromFile(
              normalizedFaviconPath,
              filename: faviconName,
            ),
          ),
        );
      }

      final response = await putForm(
        ApiConstants.generalSettings,
        data: formData,
      );
      final body = _normalizeMap(response.data);
      final source = _extractDetailSource(body);
      return _normalizeMap(source);
    }

    final payload = <String, dynamic>{...extra};
    if (normalizedCompanyName.isNotEmpty) {
      payload['company_name'] = normalizedCompanyName;
    }
    if (removeCrmLogo) {
      payload['remove_crm_logo'] = true;
    }
    if (removeFavicon) {
      payload['remove_favicon'] = true;
    }

    final response = await put(ApiConstants.generalSettings, data: payload);
    final body = _normalizeMap(response.data);
    final source = _extractDetailSource(body);
    return _normalizeMap(source);
  }

  /// Loads app logo URL from settings endpoint.
  Future<String> getAppLogoUrl() async {
    final response = await get(ApiConstants.appLogoSettings);
    final body = _normalizeMap(response.data);
    final source = _normalizeMap(_extractDetailSource(body));
    return _readNullableString(source, const ['app_logo', 'app_logo_url']) ??
        '';
  }

  /// Updates app logo using multipart upload or removal JSON payload.
  Future<String> updateAppLogo({
    String? appLogoPath,
    bool removeAppLogo = false,
    String method = 'post',
  }) async {
    final normalizedPath = (appLogoPath ?? '').trim();
    final normalizedMethod = method.trim().toLowerCase();

    Response response;
    if (normalizedPath.isNotEmpty) {
      final fileName = normalizedPath.split(RegExp(r'[\\/]')).last;
      final formData = FormData.fromMap({
        'app_logo': await MultipartFile.fromFile(
          normalizedPath,
          filename: fileName,
        ),
      });
      response = await _requestSettingsMultipart(
        path: ApiConstants.appLogoSettings,
        method: normalizedMethod,
        formData: formData,
      );
    } else {
      response = await _requestSettingsJson(
        path: ApiConstants.appLogoSettings,
        method: normalizedMethod,
        payload: {'remove_app_logo': removeAppLogo},
      );
    }

    final body = _normalizeMap(response.data);
    final source = _normalizeMap(_extractDetailSource(body));
    return _readNullableString(source, const ['app_logo', 'app_logo_url']) ??
        '';
  }

  /// Loads login logo URL from settings endpoint.
  Future<String> getLoginLogoUrl() async {
    final response = await get(ApiConstants.loginLogoSettings);
    final body = _normalizeMap(response.data);
    final source = _normalizeMap(_extractDetailSource(body));
    return _readNullableString(source, const [
          'login_logo',
          'login_logo_url',
        ]) ??
        '';
  }

  /// Updates login logo using multipart upload or removal JSON payload.
  Future<String> updateLoginLogo({
    String? loginLogoPath,
    bool removeLoginLogo = false,
    String method = 'post',
  }) async {
    final normalizedPath = (loginLogoPath ?? '').trim();
    final normalizedMethod = method.trim().toLowerCase();

    Response response;
    if (normalizedPath.isNotEmpty) {
      final fileName = normalizedPath.split(RegExp(r'[\\/]')).last;
      final formData = FormData.fromMap({
        'login_logo': await MultipartFile.fromFile(
          normalizedPath,
          filename: fileName,
        ),
      });
      response = await _requestSettingsMultipart(
        path: ApiConstants.loginLogoSettings,
        method: normalizedMethod,
        formData: formData,
      );
    } else {
      response = await _requestSettingsJson(
        path: ApiConstants.loginLogoSettings,
        method: normalizedMethod,
        payload: {'remove_login_logo': removeLoginLogo},
      );
    }

    final body = _normalizeMap(response.data);
    final source = _normalizeMap(_extractDetailSource(body));
    return _readNullableString(source, const [
          'login_logo',
          'login_logo_url',
        ]) ??
        '';
  }

  /// Loads company information from settings endpoint.
  Future<CompanyInformationModel> getCompanyInformation() async {
    final response = await get(ApiConstants.companyInformation);
    final body = _normalizeMap(response.data);
    final source = _extractDetailSource(body);
    final normalized = _normalizeMap(source);
    return CompanyInformationModel.fromJson(normalized);
  }

  /// Updates company information in settings endpoint.
  Future<CompanyInformationModel> updateCompanyInformation(
    CompanyInformationModel payload,
  ) async {
    final response = await put(
      ApiConstants.companyInformation,
      data: payload.toUpdateJson(),
    );
    final body = _normalizeMap(response.data);
    final source = _extractDetailSource(body);
    final normalized = _normalizeMap(source);
    return CompanyInformationModel.fromJson(normalized);
  }

  /// Loads email settings from settings endpoint.
  Future<EmailSettingsModel> getEmailSettings() async {
    final response = await get(ApiConstants.emailSettings);
    final body = _normalizeMap(response.data);
    final source = _extractDetailSource(body);
    final normalized = _normalizeMap(source);
    return EmailSettingsModel.fromJson(normalized);
  }

  /// Updates email settings in settings endpoint.
  Future<EmailSettingsModel> updateEmailSettings(
    EmailSettingsModel payload,
  ) async {
    final response = await put(
      ApiConstants.emailSettings,
      data: payload.toUpdateJson(),
    );
    final body = _normalizeMap(response.data);
    final source = _extractDetailSource(body);
    final normalized = _normalizeMap(source);
    return EmailSettingsModel.fromJson(normalized);
  }

  /// Loads renewal notification settings from settings endpoint.
  Future<RenewalSettingsModel> getRenewalSettings() async {
    final response = await get(ApiConstants.renewalSettings);
    final body = _normalizeMap(response.data);
    final source = _extractDetailSource(body);
    final normalized = _normalizeMap(source);
    return RenewalSettingsModel.fromJson(normalized);
  }

  /// Updates renewal notification settings in settings endpoint.
  Future<RenewalSettingsModel> updateRenewalSettings(
    RenewalSettingsModel payload,
  ) async {
    final response = await put(
      ApiConstants.renewalSettings,
      data: payload.toUpdateJson(),
    );
    final body = _normalizeMap(response.data);
    final source = _extractDetailSource(body);
    final normalized = _normalizeMap(source);
    return RenewalSettingsModel.fromJson(normalized);
  }

  /// Loads team settings list from settings endpoint.
  Future<List<TeamSettingModel>> getTeamSettings() async {
    final response = await get(ApiConstants.teamSettings);
    final source = _extractTeamSettingsListSource(response.data);
    if (source is! List) {
      throw DioException(
        requestOptions: response.requestOptions,
        error: 'Unexpected team settings response format',
        type: DioExceptionType.unknown,
      );
    }

    return source
        .map(_normalizeMap)
        .map(TeamSettingModel.fromJson)
        .toList(growable: false);
  }

  /// Updates team settings list in settings endpoint using multipart payload.
  Future<List<TeamSettingModel>> updateTeamSettings(
    List<TeamSettingModel> teams,
  ) async {
    final formData = FormData();

    for (var i = 0; i < teams.length; i++) {
      final team = teams[i];
      formData.fields.add(MapEntry('teams[$i][name]', team.name.trim()));
      formData.fields.add(
        MapEntry('teams[$i][description]', team.description.trim()),
      );

      final newIconPath = team.newIconPath.trim();
      final existingIconPath = team.existingIconPath.trim();

      if (newIconPath.isNotEmpty) {
        final fileName = newIconPath.split(RegExp(r'[\\/]')).last;
        formData.files.add(
          MapEntry(
            'teams[$i][icon]',
            await MultipartFile.fromFile(newIconPath, filename: fileName),
          ),
        );
      } else if (existingIconPath.isNotEmpty) {
        formData.fields.add(
          MapEntry('teams[$i][existing_icon_path]', existingIconPath),
        );
      }
    }

    final response = await putForm(ApiConstants.teamSettings, data: formData);
    final source = _extractTeamSettingsListSource(response.data);

    if (source is List) {
      return source
          .map(_normalizeMap)
          .map(TeamSettingModel.fromJson)
          .toList(growable: false);
    }

    return teams
        .map((entry) => entry.copyWith(newIconPath: ''))
        .toList(growable: false);
  }

  /// Loads department settings list from settings endpoint.
  Future<List<DepartmentSettingModel>> getDepartmentSettings() async {
    final response = await get(ApiConstants.departmentSettings);
    final source = _extractDepartmentSettingsListSource(response.data);
    if (source is! List) {
      throw DioException(
        requestOptions: response.requestOptions,
        error: 'Unexpected department settings response format',
        type: DioExceptionType.unknown,
      );
    }

    return source
        .map(_normalizeMap)
        .map(DepartmentSettingModel.fromJson)
        .toList(growable: false);
  }

  /// Updates department settings list in settings endpoint.
  Future<List<DepartmentSettingModel>> updateDepartmentSettings(
    List<DepartmentSettingModel> departments,
  ) async {
    final payload = <String, dynamic>{
      'departments': departments.map((item) => item.toJson()).toList(),
    };

    final response = await put(ApiConstants.departmentSettings, data: payload);
    final source = _extractDepartmentSettingsListSource(response.data);

    if (source is List) {
      return source
          .map(_normalizeMap)
          .map(DepartmentSettingModel.fromJson)
          .toList(growable: false);
    }

    return departments;
  }

  /// Sends a test email using current email settings.
  Future<void> sendSettingsTestEmail(String testEmail) async {
    final normalizedEmail = testEmail.trim();
    if (normalizedEmail.isEmpty) {
      throw Exception('Test email is required.');
    }
    await post(
      ApiConstants.settingsTestEmail,
      data: <String, dynamic>{'test_email': normalizedEmail},
    );
  }

  /// Searches tags from settings endpoint.
  Future<List<String>> searchSettingsTags(String query) async {
    final response = await get(
      ApiConstants.settingsSearchTags,
      queryParameters: <String, dynamic>{'q': query.trim()},
    );
    final source = _extractListSource(response.data);
    if (source is! List) return const <String>[];
    return source
        .map((entry) => entry?.toString().trim() ?? '')
        .where((entry) => entry.isNotEmpty)
        .toList(growable: false);
  }

  Future<CareerEnquiryListPageResult> getCareerEnquiriesPage({
    int page = 1,
    int perPage = 10,
    String? search,
    String applicantType = 'all',
    String sortBy = 'created_at',
    String sortOrder = 'desc',
  }) async {
    final normalizedPage = page < 1 ? 1 : page;
    final normalizedPerPage = perPage.clamp(1, 100).toInt();
    final normalizedSearch = (search ?? '').trim();
    final normalizedApplicantType = _normalizeCareerApplicantType(
      applicantType,
    );
    final normalizedSortBy = sortBy.trim().isEmpty
        ? 'created_at'
        : sortBy.trim();
    final normalizedSortOrder = sortOrder.toLowerCase() == 'asc'
        ? 'asc'
        : 'desc';

    final query = <String, dynamic>{
      'page': normalizedPage,
      'per_page': normalizedPerPage,
      'applicant_type': normalizedApplicantType,
      'sort_by': normalizedSortBy,
      'sort_order': normalizedSortOrder,
    };
    if (normalizedSearch.isNotEmpty) {
      query['search'] = normalizedSearch;
    }

    final response = await get(
      ApiConstants.webEnquiryCareers,
      queryParameters: query,
    );

    final root = _normalizeMap(response.data);
    final rawSource = root['data'] ?? response.data;
    final itemsSource = _extractListSource(rawSource);
    final records = itemsSource is List
        ? itemsSource
        : _normalizeList(rawSource);
    final items = records
        .map(_normalizeMap)
        .map(CareerEnquiryModel.fromJson)
        .toList(growable: false);

    final paginationSource = rawSource is Map ? _normalizeMap(rawSource) : root;
    final currentPage =
        _readInt(
          paginationSource['current_page'] ?? paginationSource['page'],
        ) ??
        normalizedPage;
    final lastPage =
        _readInt(
          paginationSource['last_page'] ??
              paginationSource['total_pages'] ??
              paginationSource['pages'],
        ) ??
        currentPage;
    final total =
        _readInt(
          paginationSource['total'] ?? paginationSource['total_count'],
        ) ??
        items.length;
    final effectivePerPage =
        _readInt(paginationSource['per_page'] ?? paginationSource['limit']) ??
        normalizedPerPage;

    return CareerEnquiryListPageResult(
      items: items,
      currentPage: currentPage,
      lastPage: lastPage < 1 ? 1 : lastPage,
      total: total,
      perPage: effectivePerPage,
      hasNextPage: currentPage < (lastPage < 1 ? 1 : lastPage),
    );
  }

  Future<CareerEnquiryModel> getCareerEnquiryDetail(String id) async {
    final normalizedId = id.trim();
    if (normalizedId.isEmpty) {
      throw Exception('Invalid career enquiry id.');
    }
    final path = ApiConstants.webEnquiryCareerDetail.replaceFirst(
      '{id}',
      normalizedId,
    );
    final response = await get(path);
    final body = _normalizeMap(response.data);
    final source = _normalizeMap(_extractDetailSource(body));
    return CareerEnquiryModel.fromJson(source);
  }

  Future<void> deleteCareerEnquiry(String id) async {
    final normalizedId = id.trim();
    if (normalizedId.isEmpty) {
      throw Exception('Invalid career enquiry id.');
    }
    final path = ApiConstants.webEnquiryCareerDelete.replaceFirst(
      '{id}',
      normalizedId,
    );
    await delete(path);
  }

  Future<Map<String, String>> getCareerResumeUrl(String id) async {
    final normalizedId = id.trim();
    if (normalizedId.isEmpty) {
      throw Exception('Invalid career enquiry id.');
    }
    final path = ApiConstants.webEnquiryCareerResumeUrl.replaceFirst(
      '{id}',
      normalizedId,
    );
    final response = await get(path);
    final body = _normalizeMap(response.data);
    final source = _normalizeMap(_extractDetailSource(body));
    return <String, String>{
      'resume_file':
          _readNullableString(source, const ['resume_file', 'resume']) ?? '',
      'resume_url': _readNullableString(source, const ['resume_url']) ?? '',
    };
  }

  Future<ContactEnquiryListPageResult> getContactEnquiriesPage({
    int page = 1,
    int perPage = 10,
    String? search,
    String sortBy = 'created_at',
    String sortOrder = 'desc',
  }) async {
    final normalizedPage = page < 1 ? 1 : page;
    final normalizedPerPage = perPage.clamp(1, 100).toInt();
    final normalizedSearch = (search ?? '').trim();
    final normalizedSortBy = sortBy.trim().isEmpty
        ? 'created_at'
        : sortBy.trim();
    final normalizedSortOrder = sortOrder.toLowerCase() == 'asc'
        ? 'asc'
        : 'desc';

    final query = <String, dynamic>{
      'page': normalizedPage,
      'per_page': normalizedPerPage,
      'sort_by': normalizedSortBy,
      'sort_order': normalizedSortOrder,
    };
    if (normalizedSearch.isNotEmpty) {
      query['search'] = normalizedSearch;
    }

    final response = await get(
      ApiConstants.webEnquiryContacts,
      queryParameters: query,
    );
    final root = _normalizeMap(response.data);
    final rawSource = root['data'] ?? response.data;
    final itemsSource = _extractListSource(rawSource);
    final records = itemsSource is List
        ? itemsSource
        : _normalizeList(rawSource);
    final items = records
        .map(_normalizeMap)
        .map(ContactEnquiryModel.fromJson)
        .toList(growable: false);

    final paginationSource = rawSource is Map ? _normalizeMap(rawSource) : root;
    final currentPage =
        _readInt(
          paginationSource['current_page'] ?? paginationSource['page'],
        ) ??
        normalizedPage;
    final lastPage =
        _readInt(
          paginationSource['last_page'] ??
              paginationSource['total_pages'] ??
              paginationSource['pages'],
        ) ??
        currentPage;
    final total =
        _readInt(
          paginationSource['total'] ?? paginationSource['total_count'],
        ) ??
        items.length;
    final effectivePerPage =
        _readInt(paginationSource['per_page'] ?? paginationSource['limit']) ??
        normalizedPerPage;

    return ContactEnquiryListPageResult(
      items: items,
      currentPage: currentPage,
      lastPage: lastPage < 1 ? 1 : lastPage,
      total: total,
      perPage: effectivePerPage,
      hasNextPage: currentPage < (lastPage < 1 ? 1 : lastPage),
    );
  }

  Future<void> deleteContactEnquiry(String id) async {
    final normalizedId = id.trim();
    if (normalizedId.isEmpty) {
      throw Exception('Invalid contact enquiry id.');
    }
    final path = ApiConstants.webEnquiryContactDelete.replaceFirst(
      '{id}',
      normalizedId,
    );
    await delete(path);
  }

  String _normalizeCareerApplicantType(String? value) {
    final normalized = (value ?? '').trim().toLowerCase();
    switch (normalized) {
      case 'fresher':
        return 'fresher';
      case 'experience':
        return 'experience';
      case 'all':
      default:
        return 'all';
    }
  }

  /// Loads the staff list for the authenticated user.
  Future<List<StaffMemberModel>> getStaffList({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh &&
        _staffListCache != null &&
        _isCacheFresh(_staffListCacheAt, _staffListCacheTtl)) {
      return List<StaffMemberModel>.from(_staffListCache!);
    }

    final response = await get(ApiConstants.liststaff);
    final records = _normalizeList(response.data);
    final parsed = records
        .map(StaffMemberModel.fromJson)
        .toList(growable: false);
    _staffListCache = parsed;
    _staffListCacheAt = DateTime.now();
    return List<StaffMemberModel>.from(parsed);
  }

  /// Loads a single paginated staff page from staff-v2 index endpoint.
  Future<StaffListPageResult> getStaffListPage({
    int page = 1,
    String? search,
    String? status,
  }) async {
    final normalizedPage = page < 1 ? 1 : page;
    final normalizedSearch = (search ?? '').trim();
    final normalizedStatus = (status ?? '').trim().toLowerCase();
    final query = <String, dynamic>{'page': normalizedPage};
    if (normalizedSearch.isNotEmpty) {
      query['search'] = normalizedSearch;
    }
    if (normalizedStatus == 'active' || normalizedStatus == 'inactive') {
      query['status'] = normalizedStatus;
    }
    final response = await get(ApiConstants.liststaff, queryParameters: query);
    final root = _normalizeMap(response.data);

    Map<String, dynamic>? pagePayload;
    final rootData = root['data'];
    if (rootData is Map<String, dynamic>) {
      final staffs = rootData['staffs'];
      if (staffs is Map<String, dynamic>) {
        pagePayload = staffs;
      } else if (staffs is Map) {
        pagePayload = staffs.map(
          (key, value) => MapEntry(key.toString(), value),
        );
      } else {
        pagePayload = rootData;
      }
    } else if (rootData is Map) {
      final normalizedData = rootData.map(
        (key, value) => MapEntry(key.toString(), value),
      );
      final staffs = normalizedData['staffs'];
      if (staffs is Map<String, dynamic>) {
        pagePayload = staffs;
      } else if (staffs is Map) {
        pagePayload = staffs.map(
          (key, value) => MapEntry(key.toString(), value),
        );
      } else {
        pagePayload = normalizedData;
      }
    } else {
      pagePayload = root;
    }

    final source = pagePayload?['data'];
    final records = source is List
        ? source.map(_normalizeMap).toList(growable: false)
        : _normalizeList(response.data);
    final items = records
        .map(StaffMemberModel.fromJson)
        .toList(growable: false);
    final currentPage =
        _readInt(pagePayload?['current_page']) ?? normalizedPage;
    final lastPage = _readInt(pagePayload?['last_page']) ?? currentPage;
    final total = _readInt(pagePayload?['total']) ?? items.length;
    final resolvedPerPage = _readInt(pagePayload?['per_page']) ?? items.length;
    final hasNextPage =
        pagePayload?['next_page_url'] != null || currentPage < lastPage;

    return StaffListPageResult(
      items: items,
      currentPage: currentPage,
      lastPage: lastPage,
      total: total,
      perPage: resolvedPerPage,
      hasNextPage: hasNextPage,
    );
  }

  /// Loads available department options for staff-v2 forms.
  Future<List<DepartmentSettingModel>> getStaffDepartments({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh &&
        _staffDepartmentsCache != null &&
        _isCacheFresh(_staffDepartmentsCacheAt, _staffOptionsCacheTtl)) {
      return List<DepartmentSettingModel>.from(_staffDepartmentsCache!);
    }

    final response = await get(ApiConstants.staffDepartments);
    final source = _extractDepartmentSettingsListSource(response.data);
    if (source is! List) {
      throw DioException(
        requestOptions: response.requestOptions,
        error: 'Unexpected staff departments response format',
        type: DioExceptionType.unknown,
      );
    }

    final parsed = source
        .map(_normalizeMap)
        .map(DepartmentSettingModel.fromJson)
        .toList(growable: false);
    _staffDepartmentsCache = parsed;
    _staffDepartmentsCacheAt = DateTime.now();
    return List<DepartmentSettingModel>.from(parsed);
  }

  /// Loads available team options for staff-v2 forms.
  Future<List<TeamSettingModel>> getStaffTeams({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh &&
        _staffTeamsCache != null &&
        _isCacheFresh(_staffTeamsCacheAt, _staffOptionsCacheTtl)) {
      return List<TeamSettingModel>.from(_staffTeamsCache!);
    }

    final response = await get(ApiConstants.staffTeams);
    final source = _extractTeamSettingsListSource(response.data);
    if (source is! List) {
      throw DioException(
        requestOptions: response.requestOptions,
        error: 'Unexpected staff teams response format',
        type: DioExceptionType.unknown,
      );
    }

    final parsed = source
        .map(_normalizeMap)
        .map(TeamSettingModel.fromJson)
        .toList(growable: false);
    _staffTeamsCache = parsed;
    _staffTeamsCacheAt = DateTime.now();
    return List<TeamSettingModel>.from(parsed);
  }

  /// Loads the client list for the authenticated user.
  Future<List<ClientModel>> getClientsList() async {
    final page = await getClientsListPage(page: 1);
    return page.items;
  }

  /// Loads a single paginated clients page from clients index endpoint.
  Future<ClientListPageResult> getClientsListPage({
    int page = 1,
    String? search,
    String? status,
    int perPage = 25,
  }) async {
    final normalizedPage = page < 1 ? 1 : page;
    final normalizedSearch = (search ?? '').trim();
    final normalizedStatus = (status ?? '').trim().toLowerCase();
    final normalizedPerPage = perPage < 1 ? 25 : perPage;
    final query = <String, dynamic>{
      'page': normalizedPage,
      'per_page': normalizedPerPage,
    };
    if (normalizedSearch.isNotEmpty) {
      query['search'] = normalizedSearch;
    }
    if (normalizedStatus == 'active' || normalizedStatus == 'inactive') {
      query['status'] = normalizedStatus;
    }
    final response = await get(ApiConstants.clients, queryParameters: query);
    final root = _normalizeMap(response.data);

    Map<String, dynamic>? pagePayload;
    final rootData = root['data'];
    if (rootData is Map<String, dynamic>) {
      final clients = rootData['clients'];
      if (clients is Map<String, dynamic>) {
        pagePayload = clients;
      } else if (clients is Map) {
        pagePayload = clients.map(
          (key, value) => MapEntry(key.toString(), value),
        );
      } else {
        pagePayload = rootData;
      }
    } else if (rootData is Map) {
      final normalizedData = rootData.map(
        (key, value) => MapEntry(key.toString(), value),
      );
      final clients = normalizedData['clients'];
      if (clients is Map<String, dynamic>) {
        pagePayload = clients;
      } else if (clients is Map) {
        pagePayload = clients.map(
          (key, value) => MapEntry(key.toString(), value),
        );
      } else {
        pagePayload = normalizedData;
      }
    } else {
      pagePayload = root;
    }

    final source = pagePayload?['data'];
    final records = source is List
        ? source.map(_normalizeMap).toList(growable: false)
        : _normalizeList(response.data);
    final items = records.map(ClientModel.fromJson).toList(growable: false);
    final currentPage =
        _readInt(pagePayload?['current_page']) ?? normalizedPage;
    final lastPage = _readInt(pagePayload?['last_page']) ?? currentPage;
    final total = _readInt(pagePayload?['total']) ?? items.length;
    final resolvedPerPage = _readInt(pagePayload?['per_page']) ?? items.length;
    final hasNextPage =
        pagePayload?['next_page_url'] != null || currentPage < lastPage;

    return ClientListPageResult(
      items: items,
      currentPage: currentPage,
      lastPage: lastPage,
      total: total,
      perPage: resolvedPerPage,
      hasNextPage: hasNextPage,
    );
  }

  /// Loads the roles list for the authenticated user.
  Future<List<RoleModel>> getRolesList() async {
    final response = await get(ApiConstants.roles);
    final records = _normalizeList(response.data);
    return records.map(RoleModel.fromJson).toList();
  }

  /// Loads the vendor list for the authenticated user.
  Future<List<VendorModel>> getVendorsList() async {
    final collected = <VendorModel>[];
    var page = 1;
    var lastPage = 1;
    do {
      final result = await getVendorsListPage(page: page);
      collected.addAll(result.items);
      lastPage = result.lastPage < 1 ? 1 : result.lastPage;
      page += 1;
    } while (page <= lastPage);
    return collected;
  }

  /// Loads a single paginated vendor list page.
  Future<VendorListPageResult> getVendorsListPage({
    int page = 1,
    int? perPage,
    String? search,
  }) async {
    final normalizedPage = page < 1 ? 1 : page;
    final normalizedSearch = (search ?? '').trim();
    final query = <String, dynamic>{'page': normalizedPage};
    if (perPage != null && perPage > 0) {
      query['per_page'] = perPage;
    }
    if (normalizedSearch.isNotEmpty) {
      query['search'] = normalizedSearch;
    }

    final response = await get(ApiConstants.vendors, queryParameters: query);

    final root = _normalizeMap(response.data);
    final nestedData = _normalizeMap(root['data']);

    Map<String, dynamic>? pagePayload;
    if (nestedData.isNotEmpty) {
      final inner = nestedData['data'];
      if (inner is List) {
        pagePayload = nestedData;
      } else {
        pagePayload = root;
      }
    } else {
      pagePayload = root;
    }

    final source = pagePayload?['data'];
    final records = source is List
        ? source.map(_normalizeMap).toList(growable: false)
        : _normalizeList(response.data);
    final items = records.map(VendorModel.fromJson).toList(growable: false);
    final currentPage =
        _readInt(pagePayload?['current_page']) ?? normalizedPage;
    final lastPage = _readInt(pagePayload?['last_page']) ?? currentPage;
    final total = _readInt(pagePayload?['total']) ?? items.length;
    final resolvedPerPage = _readInt(pagePayload?['per_page']) ?? items.length;
    final hasNextPage =
        pagePayload?['next_page_url'] != null || currentPage < lastPage;

    return VendorListPageResult(
      items: items,
      currentPage: currentPage,
      lastPage: lastPage,
      total: total,
      perPage: resolvedPerPage,
      hasNextPage: hasNextPage,
    );
  }

  /// Loads a single paginated vendor renewals page.
  Future<RenewalListPageResult> getVendorRenewalsPage({
    int page = 1,
    String? search,
    String? status,
    String? dateFrom,
    String? dateTo,
  }) async {
    final normalizedPage = page < 1 ? 1 : page;
    final normalizedSearch = (search ?? '').trim();
    final normalizedStatus = (status ?? '').trim();
    final normalizedDateFrom = (dateFrom ?? '').trim();
    final normalizedDateTo = (dateTo ?? '').trim();
    final query = <String, dynamic>{};
    if (normalizedStatus.isEmpty || normalizedPage > 1) {
      query['page'] = normalizedPage;
    }
    if (normalizedSearch.isNotEmpty) {
      query['search'] = normalizedSearch;
    }
    if (normalizedStatus == 'upcoming') {
      query['tab'] = normalizedStatus;
    } else if (normalizedStatus.isNotEmpty) {
      query['status'] = normalizedStatus;
    }
    if (normalizedDateFrom.isNotEmpty) {
      query['from_date'] = normalizedDateFrom;
    }
    if (normalizedDateTo.isNotEmpty) {
      query['to_date'] = normalizedDateTo;
    }
    final response = await get(
      ApiConstants.vendorRenewals,
      queryParameters: query,
    );
    return _parseRenewalPageResponse(response.data, normalizedPage);
  }

  /// Loads a single paginated client renewals page.
  Future<RenewalListPageResult> getClientRenewalsPage({
    int page = 1,
    String? search,
    String? status,
    String? dateFrom,
    String? dateTo,
  }) async {
    final normalizedPage = page < 1 ? 1 : page;
    final normalizedSearch = (search ?? '').trim();
    final normalizedStatus = (status ?? '').trim();
    final normalizedDateFrom = (dateFrom ?? '').trim();
    final normalizedDateTo = (dateTo ?? '').trim();
    final query = <String, dynamic>{};
    if (normalizedStatus.isEmpty || normalizedPage > 1) {
      query['page'] = normalizedPage;
    }
    if (normalizedSearch.isNotEmpty) {
      query['search'] = normalizedSearch;
    }
    if (normalizedStatus == 'upcoming') {
      query['tab'] = normalizedStatus;
    } else if (normalizedStatus.isNotEmpty) {
      query['status'] = normalizedStatus;
    }
    if (normalizedDateFrom.isNotEmpty) {
      query['from_date'] = normalizedDateFrom;
    }
    if (normalizedDateTo.isNotEmpty) {
      query['to_date'] = normalizedDateTo;
    }
    final response = await get(
      ApiConstants.clientRenewals,
      queryParameters: query,
    );
    return _parseRenewalPageResponse(response.data, normalizedPage);
  }

  /// Loads vendor renewals for the authenticated user.
  Future<List<RenewalModel>> getVendorRenewalsList() async {
    final collected = <RenewalModel>[];
    var page = 1;
    var lastPage = 1;
    do {
      final result = await getVendorRenewalsPage(page: page);
      collected.addAll(result.items);
      lastPage = result.lastPage < 1 ? 1 : result.lastPage;
      page += 1;
    } while (page <= lastPage);
    return collected;
  }

  /// Loads client renewals for the authenticated user.
  Future<List<RenewalModel>> getClientRenewalsList() async {
    final collected = <RenewalModel>[];
    var page = 1;
    var lastPage = 1;
    do {
      final result = await getClientRenewalsPage(page: page);
      collected.addAll(result.items);
      lastPage = result.lastPage < 1 ? 1 : result.lastPage;
      page += 1;
    } while (page <= lastPage);
    return collected;
  }

  RenewalListPageResult _parseRenewalPageResponse(
    dynamic responseData,
    int fallbackPage,
  ) {
    final root = _normalizeMap(responseData);
    Map<String, dynamic>? pagePayload;
    final rootData = root['data'];

    if (rootData is Map<String, dynamic>) {
      final nested = rootData['data'];
      if (nested is List) {
        pagePayload = rootData;
      } else {
        pagePayload = rootData;
      }
    } else if (rootData is Map) {
      pagePayload = rootData.map(
        (key, value) => MapEntry(key.toString(), value),
      );
    } else {
      pagePayload = root;
    }

    final source = pagePayload?['data'];
    final records = source is List
        ? source.map(_normalizeMap).toList(growable: false)
        : _normalizeList(responseData);
    final items = records.map(RenewalModel.fromJson).toList(growable: false);
    final currentPage = _readInt(pagePayload?['current_page']) ?? fallbackPage;
    final lastPage = _readInt(pagePayload?['last_page']) ?? currentPage;
    final total = _readInt(pagePayload?['total']) ?? items.length;
    final perPage = _readInt(pagePayload?['per_page']) ?? items.length;
    final hasNextPage =
        pagePayload?['next_page_url'] != null || currentPage < lastPage;

    return RenewalListPageResult(
      items: items,
      currentPage: currentPage,
      lastPage: lastPage,
      total: total,
      perPage: perPage,
      hasNextPage: hasNextPage,
    );
  }

  LeadListPageResult _parseLeadPageResponse(
    dynamic responseData,
    int fallbackPage,
  ) {
    final root = _normalizeMap(responseData);
    Map<String, dynamic>? pagePayload;
    final rootData = root['data'];
    if (rootData is Map<String, dynamic>) {
      final leads = rootData['leads'];
      if (leads is Map<String, dynamic>) {
        pagePayload = leads;
      } else if (leads is Map) {
        pagePayload = leads.map(
          (key, value) => MapEntry(key.toString(), value),
        );
      } else {
        pagePayload = rootData;
      }
    } else if (rootData is Map) {
      pagePayload = rootData.map(
        (key, value) => MapEntry(key.toString(), value),
      );
    } else {
      pagePayload = root;
    }

    final source = pagePayload?['data'];
    final records = source is List
        ? source.map(_normalizeMap).toList(growable: false)
        : _normalizeList(responseData);
    final items = records.map(LeadModel.fromJson).toList(growable: false);
    final currentPage = _readInt(pagePayload?['current_page']) ?? fallbackPage;
    final lastPage = _readInt(pagePayload?['last_page']) ?? currentPage;
    final total = _readInt(pagePayload?['total']) ?? items.length;
    final perPage = _readInt(pagePayload?['per_page']) ?? items.length;
    final hasNextPage =
        pagePayload?['next_page_url'] != null || currentPage < lastPage;

    return LeadListPageResult(
      items: items,
      currentPage: currentPage,
      lastPage: lastPage,
      total: total,
      perPage: perPage,
      hasNextPage: hasNextPage,
    );
  }

  ProjectListPageResult _parseProjectPageResponse(
    dynamic responseData,
    int fallbackPage,
  ) {
    final root = _normalizeMap(responseData);
    Map<String, dynamic>? pagePayload;
    final rootData = root['data'];
    if (rootData is Map<String, dynamic>) {
      final projects = rootData['projects'];
      if (projects is Map<String, dynamic>) {
        pagePayload = projects;
      } else if (projects is Map) {
        pagePayload = projects.map(
          (key, value) => MapEntry(key.toString(), value),
        );
      } else {
        pagePayload = rootData;
      }
    } else if (rootData is Map) {
      pagePayload = rootData.map(
        (key, value) => MapEntry(key.toString(), value),
      );
    } else {
      pagePayload = root;
    }

    final source = pagePayload?['data'];
    final records = source is List
        ? source.map(_normalizeMap).toList(growable: false)
        : _normalizeList(responseData);
    final items = records.map(ProjectModel.fromJson).toList(growable: false);
    final currentPage = _readInt(pagePayload?['current_page']) ?? fallbackPage;
    final lastPage = _readInt(pagePayload?['last_page']) ?? currentPage;
    final total = _readInt(pagePayload?['total']) ?? items.length;
    final perPage = _readInt(pagePayload?['per_page']) ?? items.length;
    final hasNextPage =
        pagePayload?['next_page_url'] != null || currentPage < lastPage;

    return ProjectListPageResult(
      items: items,
      currentPage: currentPage,
      lastPage: lastPage,
      total: total,
      perPage: perPage,
      hasNextPage: hasNextPage,
    );
  }

  TaskListPageResult _parseTaskPageResponse(
    dynamic responseData,
    int fallbackPage,
  ) {
    final root = _normalizeMap(responseData);
    final meta = _normalizeLooseMap(root['meta']);
    final metaPagination = _normalizeLooseMap(meta['pagination']);
    final pagination = _normalizeLooseMap(root['pagination']);
    final pageMeta = _normalizeLooseMap(root['page']);
    Map<String, dynamic>? pagePayload;
    final rootData = root['data'];
    if (rootData is Map<String, dynamic>) {
      final tasks = rootData['tasks'];
      if (tasks is Map<String, dynamic>) {
        pagePayload = tasks;
      } else if (tasks is Map) {
        pagePayload = tasks.map(
          (key, value) => MapEntry(key.toString(), value),
        );
      } else {
        pagePayload = rootData;
      }
    } else if (rootData is Map) {
      pagePayload = rootData.map(
        (key, value) => MapEntry(key.toString(), value),
      );
    } else {
      pagePayload = root;
    }

    final source = pagePayload?['data'];
    final records = source is List
        ? source.map(_normalizeMap).toList(growable: false)
        : _normalizeList(responseData);
    final currentPage =
        _readInt(pagePayload?['current_page']) ??
        _readInt(pagePayload?['page']) ??
        _readInt(pagePayload?['currentPage']) ??
        _readInt(meta['current_page']) ??
        _readInt(meta['page']) ??
        _readInt(meta['currentPage']) ??
        _readInt(metaPagination['current_page']) ??
        _readInt(metaPagination['page']) ??
        _readInt(metaPagination['currentPage']) ??
        _readInt(pagination['current_page']) ??
        _readInt(pagination['page']) ??
        _readInt(pagination['currentPage']) ??
        _readInt(pageMeta['current_page']) ??
        _readInt(pageMeta['page']) ??
        fallbackPage;
    final lastPage =
        _readInt(pagePayload?['last_page']) ??
        _readInt(pagePayload?['lastPage']) ??
        _readInt(pagePayload?['total_pages']) ??
        _readInt(pagePayload?['totalPages']) ??
        _readInt(meta['last_page']) ??
        _readInt(meta['lastPage']) ??
        _readInt(meta['total_pages']) ??
        _readInt(meta['totalPages']) ??
        _readInt(metaPagination['last_page']) ??
        _readInt(metaPagination['lastPage']) ??
        _readInt(metaPagination['total_pages']) ??
        _readInt(metaPagination['totalPages']) ??
        _readInt(pagination['last_page']) ??
        _readInt(pagination['lastPage']) ??
        _readInt(pagination['total_pages']) ??
        _readInt(pagination['totalPages']) ??
        _readInt(pageMeta['last_page']) ??
        _readInt(pageMeta['lastPage']) ??
        _readInt(pageMeta['total_pages']) ??
        _readInt(pageMeta['totalPages']) ??
        currentPage;
    final total =
        _readInt(pagePayload?['total']) ??
        _readInt(pagePayload?['total_records']) ??
        _readInt(pagePayload?['totalRecords']) ??
        _readInt(pagePayload?['count']) ??
        _readInt(meta['total']) ??
        _readInt(meta['total_records']) ??
        _readInt(meta['totalRecords']) ??
        _readInt(meta['count']) ??
        _readInt(metaPagination['total']) ??
        _readInt(metaPagination['total_records']) ??
        _readInt(metaPagination['totalRecords']) ??
        _readInt(metaPagination['count']) ??
        _readInt(pagination['total']) ??
        _readInt(pagination['total_records']) ??
        _readInt(pagination['totalRecords']) ??
        _readInt(pagination['count']) ??
        _readInt(pageMeta['total']) ??
        _readInt(pageMeta['total_records']) ??
        _readInt(pageMeta['totalRecords']) ??
        _readInt(pageMeta['count']) ??
        records.length;
    final perPage =
        _readInt(pagePayload?['per_page']) ??
        _readInt(pagePayload?['perPage']) ??
        _readInt(pagePayload?['page_size']) ??
        _readInt(pagePayload?['pageSize']) ??
        _readInt(pagePayload?['limit']) ??
        _readInt(meta['per_page']) ??
        _readInt(meta['perPage']) ??
        _readInt(meta['page_size']) ??
        _readInt(meta['pageSize']) ??
        _readInt(meta['limit']) ??
        _readInt(metaPagination['per_page']) ??
        _readInt(metaPagination['perPage']) ??
        _readInt(metaPagination['page_size']) ??
        _readInt(metaPagination['pageSize']) ??
        _readInt(metaPagination['limit']) ??
        _readInt(pagination['per_page']) ??
        _readInt(pagination['perPage']) ??
        _readInt(pagination['page_size']) ??
        _readInt(pagination['pageSize']) ??
        _readInt(pagination['limit']) ??
        _readInt(pageMeta['per_page']) ??
        _readInt(pageMeta['perPage']) ??
        _readInt(pageMeta['page_size']) ??
        _readInt(pageMeta['pageSize']) ??
        _readInt(pageMeta['limit']) ??
        records.length;
    final hasNextPage =
        pagePayload?['next_page_url'] != null ||
        pagePayload?['nextPageUrl'] != null ||
        metaPagination['next_page_url'] != null ||
        metaPagination['nextPageUrl'] != null ||
        metaPagination['has_more_pages'] == true ||
        pagination['next_page_url'] != null ||
        pagination['nextPageUrl'] != null ||
        currentPage < lastPage;
    final countsSource = _normalizeLooseMap(meta['counts']);
    final statusCounts = <String, int>{};
    countsSource.forEach((key, value) {
      final parsed = _readInt(value);
      if (parsed != null) {
        statusCounts[key.toString()] = parsed;
      }
    });

    return TaskListPageResult(
      items: records,
      currentPage: currentPage,
      lastPage: lastPage,
      total: total,
      perPage: perPage,
      hasNextPage: hasNextPage,
      statusCounts: statusCounts,
    );
  }

  MapListPageResult _parseMapListPageResponse(
    dynamic responseData,
    int fallbackPage, {
    String? nestedKey,
  }) {
    final root = _normalizeMap(responseData);
    Map<String, dynamic>? pagePayload;
    final rootData = root['data'];
    if (rootData is Map<String, dynamic>) {
      final nested = nestedKey == null ? null : rootData[nestedKey];
      if (nested is Map<String, dynamic>) {
        pagePayload = nested;
      } else if (nested is Map) {
        pagePayload = nested.map(
          (key, value) => MapEntry(key.toString(), value),
        );
      } else {
        pagePayload = rootData;
      }
    } else if (rootData is Map) {
      pagePayload = rootData.map(
        (key, value) => MapEntry(key.toString(), value),
      );
    } else {
      pagePayload = root;
    }

    final source = pagePayload?['data'];
    final records = source is List
        ? source.map(_normalizeMap).toList(growable: false)
        : _normalizeList(responseData);
    final currentPage = _readInt(pagePayload?['current_page']) ?? fallbackPage;
    final lastPage = _readInt(pagePayload?['last_page']) ?? currentPage;
    final total = _readInt(pagePayload?['total']) ?? records.length;
    final perPage = _readInt(pagePayload?['per_page']) ?? records.length;
    final hasNextPage =
        pagePayload?['next_page_url'] != null || currentPage < lastPage;

    return MapListPageResult(
      items: records,
      currentPage: currentPage,
      lastPage: lastPage,
      total: total,
      perPage: perPage,
      hasNextPage: hasNextPage,
    );
  }

  /// Loads client issues for the authenticated user.
  Future<List<ClientIssueModel>> getClientIssuesList() async {
    final data = await getClientIssuesIndexData();
    return data.issues;
  }

  /// Loads client issues and form option data from the index endpoint.
  Future<ClientIssueIndexData> getClientIssuesIndexData({
    String? search,
    String? status,
    int page = 1,
    int perPage = 10,
  }) async {
    final normalizedPage = page < 1 ? 1 : page;
    final normalizedPerPage = perPage.clamp(1, 100);
    final query = await _resolveClientIssueQueryParameters();
    final normalizedSearch = (search ?? '').trim();
    final normalizedStatus = (status ?? '').trim().toLowerCase();
    if (normalizedSearch.isNotEmpty) {
      query['search'] = normalizedSearch;
    }
    if (normalizedStatus.isNotEmpty) {
      query['status'] = normalizedStatus;
    }
    query['page'] = normalizedPage;
    query['per_page'] = normalizedPerPage;
    Response response;
    try {
      response = await get(
        ApiConstants.clientIssues,
        queryParameters: query.isEmpty ? null : query,
      );
    } on DioException catch (error) {
      // Some backends don't accept/need user scoping query parameters.
      // Retry once without query params before surfacing the auth error.
      if (error.response?.statusCode == 403 && query.isNotEmpty) {
        response = await get(ApiConstants.clientIssues);
      } else {
        rethrow;
      }
    }

    final source = _extractClientIssueListSource(response.data);
    if (source is! List) {
      throw DioException(
        requestOptions: response.requestOptions,
        error: 'Unexpected client issues response format',
        type: DioExceptionType.unknown,
      );
    }

    final records = source.map(_normalizeMap).toList();
    var projects = _extractClientIssueNamedList(response.data, const [
      'projects',
    ]);
    var customers = _extractClientIssueNamedList(response.data, const [
      'customers',
      'clients',
    ]);

    if (projects.isEmpty || customers.isEmpty) {
      try {
        final optionsResponse = await get(ApiConstants.clientissueformdata);
        if (projects.isEmpty) {
          projects = _extractClientIssueNamedList(optionsResponse.data, const [
            'projects',
          ]);
        }
        if (customers.isEmpty) {
          customers = _extractClientIssueNamedList(optionsResponse.data, const [
            'customers',
            'clients',
          ]);
        }
      } catch (_) {
        // The index endpoint already provides enough data for the list.
      }
    }

    final root = _normalizeMap(response.data);
    final nestedData = _normalizeLooseMap(root['data']);
    final paginationSource = nestedData.isNotEmpty ? nestedData : root;
    final currentPage =
        _readInt(paginationSource['current_page'] ?? paginationSource['page']) ??
        normalizedPage;
    final lastPage =
        _readInt(
          paginationSource['last_page'] ??
              paginationSource['total_pages'] ??
              paginationSource['pages'],
        ) ??
        currentPage;
    final total =
        _readInt(paginationSource['total'] ?? paginationSource['total_count']) ??
        records.length;
    final resolvedPerPage =
        _readInt(paginationSource['per_page'] ?? paginationSource['limit']) ??
        normalizedPerPage;

    return ClientIssueIndexData(
      issues: records.map(ClientIssueModel.fromJson).toList(),
      projects: projects
          .map(ClientIssueSelectOption.projectFromJson)
          .where((entry) => entry.id.trim().isNotEmpty)
          .toList(),
      customers: customers
          .map(ClientIssueSelectOption.customerFromJson)
          .where((entry) => entry.id.trim().isNotEmpty)
          .toList(),
      currentPage: currentPage,
      lastPage: lastPage,
      total: total,
      perPage: resolvedPerPage,
    );
  }

  /// Loads paginated client issues with API-side filters.
  Future<ClientIssueIndexData> getClientIssuesPageData({
    String? search,
    String? status,
    int page = 1,
    int perPage = 10,
  }) async {
    return getClientIssuesIndexData(
      search: search,
      status: status,
      page: page,
      perPage: perPage,
    );
  }

  /// Loads team options for client issue assignment.
  Future<List<ClientIssueTeamOption>> getClientIssueTeams() async {
    final response = await get(ApiConstants.clientissueformdata);
    final records = _extractClientIssueNamedList(response.data, const [
      'teams',
    ]);
    return records
        .map(ClientIssueTeamOption.fromJson)
        .where((entry) => entry.displayName.trim().isNotEmpty)
        .toList(growable: false);
  }

  /// Assigns a team to a client issue.
  Future<void> assignClientIssueTeam({
    required String issueId,
    required String teamName,
  }) async {
    final normalizedIssueId = issueId.trim();
    final normalizedTeamName = teamName.trim();
    if (normalizedIssueId.isEmpty) {
      throw Exception('Invalid client issue id.');
    }
    if (normalizedTeamName.isEmpty) {
      throw Exception('Team name is required.');
    }

    final path = ApiConstants.assignClientIssueTeam.replaceFirst(
      '{id}',
      normalizedIssueId,
    );

    await post(path, data: <String, dynamic>{'team_name': normalizedTeamName});
  }

  /// Loads a single client issue by id.
  Future<ClientIssueModel> getClientIssueDetail(String id) async {
    final normalizedId = id.trim();
    if (normalizedId.isEmpty) {
      throw Exception('Invalid client issue id.');
    }

    final path = ApiConstants.clientIssuesDetail.replaceFirst(
      '{id}',
      normalizedId,
    );
    final response = await get(path);
    final body = _normalizeMap(_extractDetailSource(response.data));
    return ClientIssueModel.fromJson(body);
  }

  /// Deletes an existing client issue.
  Future<void> deleteClientIssue(String id) async {
    final normalizedId = id.trim();
    if (normalizedId.isEmpty) {
      throw Exception('Invalid client issue id.');
    }

    final path = ApiConstants.deleteClientIssue.replaceFirst(
      '{id}',
      normalizedId,
    );
    await delete(path);
  }

  /// Creates a new client issue.
  Future<ClientIssueModel?> createClientIssue({
    required String projectId,
    required String customerId,
    required String issueDescription,
    required String priority,
    required String status,
  }) async {
    final payload = <String, dynamic>{
      'project_id': int.tryParse(projectId.trim()) ?? projectId.trim(),
      'customer_id': int.tryParse(customerId.trim()) ?? customerId.trim(),
      'issue_description': issueDescription.trim(),
      'priority': priority.trim().toLowerCase(),
      'status': status.trim().toLowerCase(),
    };

    final response = await post(ApiConstants.createClientIssues, data: payload);
    final source = _extractDetailSource(response.data);
    if (source is Map) {
      return ClientIssueModel.fromJson(_normalizeMap(source));
    }
    return null;
  }

  /// Creates a new task under a client issue.
  Future<ClientIssueTaskModel?> createClientIssueTask({
    required String issueId,
    required CreateClientIssueTaskRequest request,
  }) async {
    final normalizedIssueId = issueId.trim();
    if (normalizedIssueId.isEmpty) {
      throw Exception('Invalid client issue id.');
    }

    final normalizedTitle = request.title.trim();
    if (normalizedTitle.isEmpty) {
      throw Exception('Task title is required.');
    }

    final path = ApiConstants.createClientIssueTask.replaceFirst(
      '{clientIssue}',
      normalizedIssueId,
    );

    final formData = await _buildClientIssueTaskFormData(request);

    final response = await postForm(path, data: formData);
    final source = _extractClientIssueTaskSource(response.data);
    if (source is Map) {
      return ClientIssueTaskModel.fromJson(_normalizeMap(source));
    }
    return null;
  }

  /// Loads a task detail under a specific client issue.
  Future<ClientIssueTaskModel> getClientIssueTaskDetail({
    required String issueId,
    required String taskId,
  }) async {
    final normalizedIssueId = issueId.trim();
    final normalizedTaskId = taskId.trim();
    if (normalizedIssueId.isEmpty || normalizedTaskId.isEmpty) {
      throw Exception('Invalid issue/task id.');
    }

    final path = ApiConstants.clientIssueTaskDetail
        .replaceFirst('{issueId}', normalizedIssueId)
        .replaceFirst('{taskId}', normalizedTaskId);
    final response = await get(path);
    final source = _extractClientIssueTaskSource(response.data);
    if (source is Map) {
      return ClientIssueTaskModel.fromJson(_normalizeMap(source));
    }
    throw Exception('Unexpected task detail response format.');
  }

  /// Updates a task under a specific client issue.
  Future<ClientIssueTaskModel> updateClientIssueTask({
    required String issueId,
    required String taskId,
    required CreateClientIssueTaskRequest request,
  }) async {
    final normalizedIssueId = issueId.trim();
    final normalizedTaskId = taskId.trim();
    if (normalizedIssueId.isEmpty || normalizedTaskId.isEmpty) {
      throw Exception('Invalid issue/task id.');
    }

    final normalizedTitle = request.title.trim();
    if (normalizedTitle.isEmpty) {
      throw Exception('Task title is required.');
    }

    final path = ApiConstants.clientIssueTaskDetail
        .replaceFirst('{issueId}', normalizedIssueId)
        .replaceFirst('{taskId}', normalizedTaskId);

    final formData = await _buildClientIssueTaskFormData(request);
    formData.fields.add(const MapEntry('_method', 'PUT'));
    final response = await postForm(path, data: formData);
    final source = _extractClientIssueTaskSource(response.data);
    if (source is Map) {
      return ClientIssueTaskModel.fromJson(_normalizeMap(source));
    }
    throw Exception('Unexpected task update response format.');
  }

  Future<FormData> _buildClientIssueTaskFormData(
    CreateClientIssueTaskRequest request,
  ) async {
    final normalizedTitle = request.title.trim();
    if (normalizedTitle.isEmpty) {
      throw Exception('Task title is required.');
    }

    final formData = FormData();
    formData.fields.add(MapEntry('title', normalizedTitle));

    final normalizedDescription = request.description?.trim() ?? '';
    if (normalizedDescription.isNotEmpty) {
      formData.fields.add(MapEntry('description', normalizedDescription));
    }

    final normalizedStatus = _normalizeClientIssueTaskStatus(request.status);
    if (normalizedStatus.isNotEmpty) {
      formData.fields.add(MapEntry('status', normalizedStatus));
    }

    final normalizedPriority = _normalizeClientIssueTaskPriority(
      request.priority,
    );
    if (normalizedPriority.isNotEmpty) {
      formData.fields.add(MapEntry('priority', normalizedPriority));
    }

    final normalizedAssignedTo = request.assignedTo?.trim() ?? '';
    if (normalizedAssignedTo.isNotEmpty) {
      formData.fields.add(MapEntry('assigned_to', normalizedAssignedTo));
    }

    if (request.startDate != null) {
      formData.fields.add(
        MapEntry('start_date', _formatApiDate(request.startDate!)),
      );
    }

    if (request.dueDate != null) {
      formData.fields.add(
        MapEntry('due_date', _formatApiDate(request.dueDate!)),
      );
    }

    final normalizedDueTime = request.dueTime?.trim() ?? '';
    if (normalizedDueTime.isNotEmpty) {
      formData.fields.add(MapEntry('due_time', normalizedDueTime));
    }

    if (request.reminderDate != null) {
      formData.fields.add(
        MapEntry('reminder_date', _formatApiDate(request.reminderDate!)),
      );
    }

    final normalizedReminderTime = request.reminderTime?.trim() ?? '';
    if (normalizedReminderTime.isNotEmpty) {
      formData.fields.add(MapEntry('reminder_time', normalizedReminderTime));
    }

    if (request.checklistData.isNotEmpty) {
      final checklist = request.checklistData
          .map((entry) => entry.trim())
          .where((entry) => entry.isNotEmpty)
          .toList(growable: false);
      if (checklist.isNotEmpty) {
        formData.fields.add(MapEntry('checklist_data', jsonEncode(checklist)));
      }
    }

    if (request.labelsData.isNotEmpty) {
      final labels = request.labelsData
          .map((entry) => entry.trim())
          .where((entry) => entry.isNotEmpty)
          .toList(growable: false);
      if (labels.isNotEmpty) {
        formData.fields.add(MapEntry('labels_data', jsonEncode(labels)));
      }
    }

    for (final rawPath in request.attachmentPaths) {
      final filePath = rawPath.trim();
      if (filePath.isEmpty) continue;
      final fileName = filePath.split(RegExp(r'[\\/]')).last;
      formData.files.add(
        MapEntry(
          'attachments[]',
          await MultipartFile.fromFile(filePath, filename: fileName),
        ),
      );
    }

    return formData;
  }

  /// Deletes a task under a specific client issue.
  Future<void> deleteClientIssueTask({
    required String issueId,
    required String taskId,
  }) async {
    final normalizedIssueId = issueId.trim();
    final normalizedTaskId = taskId.trim();
    if (normalizedIssueId.isEmpty || normalizedTaskId.isEmpty) {
      throw Exception('Invalid issue/task id.');
    }

    final path = ApiConstants.clientIssueTaskDetail
        .replaceFirst('{issueId}', normalizedIssueId)
        .replaceFirst('{taskId}', normalizedTaskId);
    await delete(path);
  }

  /// Updates status of a task under a specific client issue.
  Future<void> updateClientIssueTaskStatus({
    required String issueId,
    required String taskId,
    required String status,
  }) async {
    final normalizedIssueId = issueId.trim();
    final normalizedTaskId = taskId.trim();
    if (normalizedIssueId.isEmpty || normalizedTaskId.isEmpty) {
      throw Exception('Invalid issue/task id.');
    }

    final path = ApiConstants.clientIssueTaskStatus
        .replaceFirst('{issueId}', normalizedIssueId)
        .replaceFirst('{taskId}', normalizedTaskId);

    await patch(
      path,
      data: <String, dynamic>{
        'status': _normalizeClientIssueTaskStatus(status),
      },
    );
  }

  /// Updates status of a client issue.
  Future<void> updateClientIssueStatus({
    required String issueId,
    required String status,
  }) async {
    final normalizedIssueId = issueId.trim();
    if (normalizedIssueId.isEmpty) {
      throw Exception('Invalid client issue id.');
    }

    final path = ApiConstants.clientIssueStatus.replaceFirst(
      '{id}',
      normalizedIssueId,
    );
    await patch(
      path,
      data: <String, dynamic>{'status': status.trim().toLowerCase()},
    );
  }

  /// Loads a single vendor renewal by id.
  Future<RenewalModel> getVendorRenewalDetail(String id) async {
    final normalizedId = id.trim();
    if (normalizedId.isEmpty) {
      throw Exception('Invalid vendor renewal id.');
    }

    final path = ApiConstants.vendorRenewalsDetail.replaceFirst(
      '{id}',
      normalizedId,
    );
    final response = await get(path);
    final body = _normalizeMap(_extractDetailSource(response.data));
    return RenewalModel.fromJson(body);
  }

  /// Loads a single client renewal by id.
  Future<RenewalModel> getClientRenewalDetail(String id) async {
    final normalizedId = id.trim();
    if (normalizedId.isEmpty) {
      throw Exception('Invalid client renewal id.');
    }

    final path = ApiConstants.clientRenewalsDetail.replaceFirst(
      '{id}',
      normalizedId,
    );
    final response = await get(path);
    final body = _normalizeMap(_extractDetailSource(response.data));
    return RenewalModel.fromJson(body);
  }

  /// Loads client renewal form options (clients + vendors).
  Future<ClientRenewalFormOptionsResult> getClientRenewalFormOptions() async {
    final response = await get(ApiConstants.clientRenewalsFormOptions);
    final root = _normalizeMap(response.data);
    final payload = _normalizeMap(root['data']);
    final source = payload.isNotEmpty ? payload : root;

    final rawClients = source['clients'];
    final rawVendors = source['vendors'];
    final rawStatuses =
        source['statuses'] ??
        source['status'] ??
        source['renewal_statuses'] ??
        source['renewalStatuses'];

    final clients = rawClients is List
        ? rawClients
              .map(_normalizeMap)
              .map(ClientModel.fromJson)
              .where((entry) => entry.id.trim().isNotEmpty)
              .toList(growable: false)
        : const <ClientModel>[];

    final vendors = rawVendors is List
        ? rawVendors
              .map(_normalizeMap)
              .map(VendorModel.fromJson)
              .where((entry) => entry.id.trim().isNotEmpty)
              .toList(growable: false)
        : const <VendorModel>[];

    final statuses = rawStatuses is List
        ? rawStatuses
              .map((entry) {
                if (entry is String) {
                  return entry.trim().toLowerCase();
                }
                if (entry is Map) {
                  final map = _normalizeMap(entry);
                  final value =
                      map['value'] ??
                      map['name'] ??
                      map['label'] ??
                      map['status'];
                  return value?.toString().trim().toLowerCase() ?? '';
                }
                return entry.toString().trim().toLowerCase();
              })
              .where((entry) => entry.isNotEmpty)
              .toSet()
              .toList(growable: false)
        : const <String>[];

    return ClientRenewalFormOptionsResult(
      clients: clients,
      vendors: vendors,
      statuses: statuses,
    );
  }

  /// Creates a vendor renewal/service record.
  Future<RenewalModel> createVendorRenewal({
    required String vendorId,
    required String serviceName,
    required String serviceDetails,
    required String planType,
    required DateTime startDate,
    required DateTime endDate,
    required DateTime billingDate,
    required String status,
  }) async {
    final payload = FormData.fromMap({
      'vendor_id': vendorId.trim(),
      'service_name': serviceName.trim(),
      'service_details': serviceDetails.trim(),
      'plan_type': planType.trim().toLowerCase(),
      'start_date': _formatApiDate(startDate),
      'end_date': _formatApiDate(endDate),
      'billing_date': _formatApiDate(billingDate),
      'status': status.trim().toLowerCase(),
    });

    final response = await postForm(
      ApiConstants.createvendorRenewals,
      data: payload,
    );
    final body = _normalizeMap(_extractDetailSource(response.data));
    return RenewalModel.fromJson(body);
  }

  /// Updates an existing vendor renewal/service record.
  Future<RenewalModel> updateVendorRenewal({
    required String id,
    required String vendorId,
    required String serviceName,
    required String serviceDetails,
    required String planType,
    required DateTime startDate,
    required DateTime endDate,
    required DateTime billingDate,
    required String status,
  }) async {
    final normalizedId = id.trim();
    if (normalizedId.isEmpty) {
      throw Exception('Invalid vendor renewal id.');
    }

    final path = ApiConstants.updateVendorRenewal.replaceFirst(
      '{id}',
      normalizedId,
    );
    final payload = FormData.fromMap({
      'vendor_id': vendorId.trim(),
      'service_name': serviceName.trim(),
      'service_details': serviceDetails.trim(),
      'plan_type': planType.trim().toLowerCase(),
      'start_date': _formatApiDate(startDate),
      'end_date': _formatApiDate(endDate),
      'billing_date': _formatApiDate(billingDate),
      'status': status.trim().toLowerCase(),
      '_method': 'put',
    });

    final response = await postForm(path, data: payload);
    final body = _normalizeMap(_extractDetailSource(response.data));
    return RenewalModel.fromJson(body);
  }

  /// Deletes an existing vendor renewal/service record.
  Future<void> deleteVendorRenewal(String id) async {
    final normalizedId = id.trim();
    if (normalizedId.isEmpty) {
      throw Exception('Invalid vendor renewal id.');
    }

    final path = '${ApiConstants.vendorRenewals}/$normalizedId';
    if (kDebugMode) {
      debugPrint('deleteVendorRenewal path: $path');
    }
    await delete(path);
  }

  /// Creates a client renewal/service record.
  Future<RenewalModel> createClientRenewal({
    required String clientId,
    String? clientBusinessDetailId,
    required String vendorId,
    required String serviceName,
    required String serviceDetails,
    required String remarkText,
    required String remarkColor,
    required DateTime startDate,
    required DateTime endDate,
    required DateTime billingDate,
    required String status,
  }) async {
    final payload = FormData.fromMap({
      'client_id': clientId.trim(),
      if (clientBusinessDetailId != null &&
          clientBusinessDetailId.trim().isNotEmpty)
        'client_business_detail_id': clientBusinessDetailId.trim(),
      'vendor_id': vendorId.trim(),
      'service_name': serviceName.trim(),
      'service_details': serviceDetails.trim(),
      'remark_text': remarkText.trim(),
      'remark_color': remarkColor.trim(),
      'start_date': _formatApiDate(startDate),
      'end_date': _formatApiDate(endDate),
      'billing_date': _formatApiDate(billingDate),
      'status': status.trim().toLowerCase(),
    });

    final response = await postForm(
      ApiConstants.createclientRenewals,
      data: payload,
    );
    final body = _normalizeMap(_extractDetailSource(response.data));
    return RenewalModel.fromJson(body);
  }

  /// Updates an existing client renewal/service record.
  Future<RenewalModel> updateClientRenewal({
    required String id,
    required String clientId,
    String? clientBusinessDetailId,
    required String vendorId,
    required String serviceName,
    required String serviceDetails,
    required String remarkText,
    required String remarkColor,
    required DateTime startDate,
    required DateTime endDate,
    required DateTime billingDate,
    required String status,
  }) async {
    final normalizedId = id.trim();
    if (normalizedId.isEmpty) {
      throw Exception('Invalid client renewal id.');
    }

    final path = ApiConstants.updateClientRenewal.replaceFirst(
      '{id}',
      normalizedId,
    );
    final payload = FormData.fromMap({
      'client_id': clientId.trim(),
      if (clientBusinessDetailId != null &&
          clientBusinessDetailId.trim().isNotEmpty)
        'client_business_detail_id': clientBusinessDetailId.trim(),
      'vendor_id': vendorId.trim(),
      'service_name': serviceName.trim(),
      'service_details': serviceDetails.trim(),
      'remark_text': remarkText.trim(),
      'remark_color': remarkColor.trim(),
      'start_date': _formatApiDate(startDate),
      'end_date': _formatApiDate(endDate),
      'billing_date': _formatApiDate(billingDate),
      'status': status.trim().toLowerCase(),
      '_method': 'put',
    });

    final response = await postForm(path, data: payload);
    final body = _normalizeMap(_extractDetailSource(response.data));
    return RenewalModel.fromJson(body);
  }

  /// Deletes an existing client renewal/service record.
  Future<void> deleteClientRenewal(String id) async {
    final normalizedId = id.trim();
    if (normalizedId.isEmpty) {
      throw Exception('Invalid client renewal id.');
    }

    final path = ApiConstants.deleteClientRenewal.replaceFirst(
      '{id}',
      normalizedId,
    );
    await delete(path);
  }

  /// Loads the project list for the authenticated user.
  Future<List<ProjectModel>> getProjectsList() async {
    final response = await get(ApiConstants.projects);
    final records = _normalizeList(response.data);
    return records.map(ProjectModel.fromJson).toList();
  }

  /// Loads a single paginated project page.
  Future<ProjectListPageResult> getProjectsListPage({
    int page = 1,
    String? search,
  }) async {
    final normalizedPage = page < 1 ? 1 : page;
    final normalizedSearch = (search ?? '').trim();
    final query = <String, dynamic>{'page': normalizedPage};
    if (normalizedSearch.isNotEmpty) {
      query['search'] = normalizedSearch;
    }
    final response = await get(ApiConstants.projects, queryParameters: query);
    return _parseProjectPageResponse(response.data, normalizedPage);
  }

  /// Loads projects assigned to a specific staff member.
  Future<List<ProjectModel>> getStaffProjectsList(String staffId) async {
    final id = staffId.trim();
    if (id.isEmpty) return const <ProjectModel>[];

    final path = ApiConstants.staffprojects.replaceFirst('{id}', id);
    final response = await get(path);
    final records = _normalizeList(response.data);
    return records.map(ProjectModel.fromJson).toList();
  }

  /// Loads a single paginated staff-projects page.
  Future<ProjectListPageResult> getStaffProjectsListPage({
    required String staffId,
    int page = 1,
    String? search,
  }) async {
    final id = staffId.trim();
    if (id.isEmpty) {
      return const ProjectListPageResult(
        items: <ProjectModel>[],
        currentPage: 1,
        lastPage: 1,
        total: 0,
        perPage: 10,
        hasNextPage: false,
      );
    }
    final normalizedPage = page < 1 ? 1 : page;
    final normalizedSearch = (search ?? '').trim();
    final query = <String, dynamic>{'page': normalizedPage};
    if (normalizedSearch.isNotEmpty) {
      query['search'] = normalizedSearch;
    }
    final path = ApiConstants.staffprojects.replaceFirst('{id}', id);
    final response = await get(path, queryParameters: query);
    return _parseProjectPageResponse(response.data, normalizedPage);
  }

  /// Loads calendar events for the authenticated user.
  Future<List<CalendarEventModel>> getCalendarEvents() async {
    final response = await get(ApiConstants.calendar);
    final records = _normalizeList(response.data);
    return records.map(CalendarEventModel.fromJson).toList();
  }

  /// Loads a single calendar event by id.
  Future<CalendarEventModel> getCalendarEventDetail(String id) async {
    final path = ApiConstants.calendarDetail.replaceFirst('{id}', id);
    final response = await get(path);
    final body = _normalizeMap(_extractDetailSource(response.data));
    return CalendarEventModel.fromJson(body);
  }

  /// Creates a new calendar event.
  Future<CalendarEventModel> createCalendarEvent({
    required String title,
    required String description,
    required DateTime eventDate,
    required String eventTime,
    required String emailRecipients,
    required String whatsappRecipients,
  }) async {
    final payload = {
      'title': title,
      'description': description,
      'event_date': _formatApiDate(eventDate),
      'event_time': eventTime,
      'email_recipients': emailRecipients,
      'whatsapp_recipients': whatsappRecipients,
    };

    final response = await post(ApiConstants.createcalendar, data: payload);
    final body = _normalizeMap(_extractDetailSource(response.data));
    return CalendarEventModel.fromJson(body);
  }

  /// Updates an existing calendar event.
  Future<CalendarEventModel> updateCalendarEvent({
    required String id,
    required String title,
    required String description,
    required DateTime eventDate,
    required String eventTime,
    required String emailRecipients,
    required String whatsappRecipients,
  }) async {
    final path = ApiConstants.updateCalendar.replaceFirst('{id}', id);
    final payload = {
      'title': title,
      'description': description,
      'event_date': _formatApiDate(eventDate),
      'event_time': eventTime,
      'email_recipients': emailRecipients,
      'whatsapp_recipients': whatsappRecipients,
    };

    final response = await put(path, data: payload);
    final body = _normalizeMap(_extractDetailSource(response.data));
    return CalendarEventModel.fromJson(body);
  }

  /// Deletes an existing calendar event.
  Future<void> deleteCalendarEvent(String id) async {
    final path = ApiConstants.deleteCalendar.replaceFirst('{id}', id);
    await delete(path);
  }

  /// Loads a single project by id.
  Future<ProjectDetailModel> getProjectDetail(String id) async {
    final path = ApiConstants.projectDetail.replaceFirst('{id}', id);
    final response = await get(path);
    final body = _normalizeMap(response.data);
    final source = _normalizeMap(_extractProjectDetailSource(body));
    return ProjectDetailModel.fromJson(source);
  }

  Future<ProjectUsageModel> getProjectUsage(String id) async {
    final path = ApiConstants.projectussage.replaceFirst('{id}', id);
    final response = await get(path);
    final body = _normalizeMap(response.data);
    final source = _normalizeMap(_extractProjectDetailSource(body));
    return ProjectUsageModel.fromJson(source);
  }

  /// Loads project files by project id.
  Future<List<ProjectFileRecord>> getProjectFiles(String id) async {
    final path = ApiConstants.projectfiles.replaceFirst('{id}', id);
    final response = await get(path);
    final source = _extractListSource(response.data);
    if (source is! List) {
      throw DioException(
        requestOptions: response.requestOptions,
        error: 'Unexpected project files response format',
        type: DioExceptionType.unknown,
      );
    }

    final records = source.map(_normalizeMap).toList();
    return records
        .map(ProjectFileRecord.fromJson)
        .where((entry) => entry.name.isNotEmpty || entry.url.isNotEmpty)
        .toList();
  }

  /// Loads comments for a project by id.
  Future<List<ProjectCommentModel>> getProjectComments(String id) async {
    final path = ApiConstants.projectcomments.replaceFirst('{id}', id);
    final response = await get(path);
    final source = _extractListSource(response.data);
    if (source is! List) {
      throw DioException(
        requestOptions: response.requestOptions,
        error: 'Unexpected project comments response format',
        type: DioExceptionType.unknown,
      );
    }

    final records = source.map(_normalizeMap).toList();
    return records
        .map(ProjectCommentModel.fromJson)
        .where((entry) => entry.comment.trim().isNotEmpty)
        .toList();
  }

  /// Creates a comment for a project.
  Future<ProjectCommentModel> createProjectComment({
    required String projectId,
    required String comment,
  }) async {
    final path = ApiConstants.createprojectcomments.replaceFirst(
      '{id}',
      projectId,
    );
    final response = await post(path, data: {'comment': comment.trim()});
    final source = _normalizeMap(_extractDetailSource(response.data));
    return ProjectCommentModel.fromJson(source);
  }

  /// Uploads a file for a project.
  Future<ProjectFileRecord> createProjectFile({
    required String projectId,
    required String filePath,
    String? description,
  }) async {
    final path = ApiConstants.projectfiles.replaceFirst('{id}', projectId);
    final fileName = filePath.split(RegExp(r'[\\/]')).last;
    final payload = <String, dynamic>{
      'file': await MultipartFile.fromFile(filePath, filename: fileName),
    };
    final normalizedDescription = (description ?? '').trim();
    if (normalizedDescription.isNotEmpty) {
      payload['description'] = normalizedDescription;
    }

    final response = await postForm(path, data: FormData.fromMap(payload));
    final source = _normalizeMap(_extractDetailSource(response.data));
    return ProjectFileRecord.fromJson(source);
  }

  /// Deletes an uploaded project file.
  Future<void> deleteProjectFile({
    required String projectId,
    required String fileId,
  }) async {
    final path = ApiConstants.deleteProjectFile
        .replaceFirst('{projectId}', projectId)
        .replaceFirst('{fileId}', fileId);
    await delete(path);
  }

  /// Loads milestones for a project by id.
  Future<List<ProjectMilestoneModel>> getProjectMilestones(String id) async {
    final path = ApiConstants.projectmilestones.replaceFirst('{id}', id);
    final response = await get(path);
    final source = _extractListSource(response.data);
    if (source is! List) {
      throw DioException(
        requestOptions: response.requestOptions,
        error: 'Unexpected project milestones response format',
        type: DioExceptionType.unknown,
      );
    }

    final records = source.map(_normalizeMap).toList();
    return records.map(ProjectMilestoneModel.fromJson).toList();
  }

  /// Creates a milestone for a project.
  Future<ProjectMilestoneModel> createProjectMilestone({
    required String projectId,
    required String title,
    String? description,
    String? status,
    String? dueDate,
  }) async {
    final path = ApiConstants.createprojectmilestones.replaceFirst(
      '{id}',
      projectId,
    );
    final payload = _buildProjectMilestonePayload(
      title: title,
      description: description,
      status: status,
      dueDate: dueDate,
    );
    final response = await post(path, data: payload);
    final source = _normalizeMap(_extractDetailSource(response.data));
    return ProjectMilestoneModel.fromJson(source);
  }

  /// Updates an existing project milestone.
  Future<ProjectMilestoneModel> updateProjectMilestone({
    required String projectId,
    required String milestoneId,
    required String title,
    String? description,
    String? status,
    String? dueDate,
  }) async {
    final path = ApiConstants.updateprojectmilestones
        .replaceFirst('{projectId}', projectId)
        .replaceFirst('{milestoneId}', milestoneId);
    final payload = _buildProjectMilestonePayload(
      title: title,
      description: description,
      status: status,
      dueDate: dueDate,
    );
    final response = await put(path, data: payload);
    final source = _normalizeMap(_extractDetailSource(response.data));
    return ProjectMilestoneModel.fromJson(source);
  }

  /// Deletes a project milestone by id.
  Future<void> deleteProjectMilestone({
    required String projectId,
    required String milestoneId,
  }) async {
    final path = ApiConstants.deleteProjectMilestone
        .replaceFirst('{projectId}', projectId)
        .replaceFirst('{milestoneId}', milestoneId);
    await delete(path);
  }

  /// Loads issues for a project by id.
  Future<List<ProjectIssueModel>> getProjectIssues(String id) async {
    final path = ApiConstants.projectissues.replaceFirst('{id}', id);
    final response = await get(path);
    final source = _extractListSource(response.data);
    if (source is! List) {
      throw DioException(
        requestOptions: response.requestOptions,
        error: 'Unexpected project issues response format',
        type: DioExceptionType.unknown,
      );
    }

    final records = source.map(_normalizeMap).toList();
    return records.map(ProjectIssueModel.fromJson).toList();
  }

  /// Creates an issue for a project.
  Future<ProjectIssueModel> createProjectIssue({
    required String projectId,
    required String issueDescription,
    required String priority,
    required String status,
  }) async {
    final path = ApiConstants.createprojectissues.replaceFirst(
      '{id}',
      projectId,
    );
    final payload = _buildProjectIssuePayload(
      issueDescription: issueDescription,
      priority: priority,
      status: status,
    );
    final response = await post(path, data: payload);
    final source = _normalizeMap(_extractDetailSource(response.data));
    return ProjectIssueModel.fromJson(source);
  }

  /// Updates an existing project issue.
  Future<ProjectIssueModel> updateProjectIssue({
    required String projectId,
    required String issueId,
    required String issueDescription,
    required String priority,
    required String status,
  }) async {
    final path = ApiConstants.updateprojectissues
        .replaceFirst('{projectId}', projectId)
        .replaceFirst('{issueId}', issueId);
    final payload = _buildProjectIssuePayload(
      issueDescription: issueDescription,
      priority: priority,
      status: status,
    );
    final response = await put(path, data: payload);
    final source = _normalizeMap(_extractDetailSource(response.data));
    return ProjectIssueModel.fromJson(source);
  }

  /// Deletes a project issue by id.
  Future<void> deleteProjectIssue({
    required String projectId,
    required String issueId,
  }) async {
    final path = ApiConstants.deleteProjectIssue
        .replaceFirst('{projectId}', projectId)
        .replaceFirst('{issueId}', issueId);
    await delete(path);
  }

  /// Loads the lead list for the authenticated user.
  Future<List<LeadModel>> getLeadsList({String? userId, String? roleId}) async {
    final query = await _resolveLeadQueryParameters(
      userId: userId,
      roleId: roleId,
    );
    final response = await get(ApiConstants.leads, queryParameters: query);
    final records = _normalizeList(response.data);
    return records.map(LeadModel.fromJson).toList();
  }

  /// Loads dashboard lead metrics and recent leads.
  Future<LeadDashboardResult> getLeadsDashboard() async {
    final response = await get(ApiConstants.leadsDashboard);
    final body = _normalizeMap(response.data);

    LeadDashboardCount parseCount(
      dynamic source,
      String todayKey,
      String totalKey,
    ) {
      final map = (source is Map<String, dynamic>)
          ? source
          : (source is Map)
          ? source.map((key, value) => MapEntry(key.toString(), value))
          : const <String, dynamic>{};
      return LeadDashboardCount(
        todayCount: _readInt(map[todayKey]) ?? 0,
        totalCount: _readInt(map[totalKey]) ?? 0,
      );
    }

    final leads = _normalizeList(body['data']).map(LeadModel.fromJson).toList();
    return LeadDashboardResult(
      recentLeads: leads,
      leadsCount: parseCount(
        body['leadsCount'],
        'todaysLeadsCount',
        'allLeadsCount',
      ),
      bookCallsCount: parseCount(
        body['bookCallsCount'],
        'todaysBookCallsCount',
        'allBookCallsCount',
      ),
      digitalMarketingLeadsCount: parseCount(
        body['digitalMarketingLeadsCount'],
        'todaysDigitalMarketingLeadsCount',
        'allDigitalMarketingLeadsCount',
      ),
      webAppLeadsCount: parseCount(
        body['webAppLeadsCount'],
        'todaysWebAppLeadsCount',
        'allWebAppLeadsCount',
      ),
    );
  }

  /// Loads quick stats for profile/dashboard summary section.
  Future<QuickStatsModel> getQuickStats() async {
    final response = await get(ApiConstants.quickStats);
    final root = _normalizeMap(response.data);

    final nestedData = root['data'];
    final payload = nestedData is Map
        ? nestedData.map((key, value) => MapEntry(key.toString(), value))
        : root;

    int readCount(List<String> keys) {
      for (final key in keys) {
        final value = payload[key];
        final parsed = _readInt(value);
        if (parsed != null) {
          return parsed;
        }
      }
      return 0;
    }

    return QuickStatsModel(
      projectsCount: readCount(const [
        'projects',
        'project_count',
        'projects_count',
        'total_projects',
      ]),
      leadsCount: readCount(const [
        'leads',
        'lead_count',
        'leads_count',
        'total_leads',
      ]),
      tasksCount: readCount(const [
        'tasks',
        'task_count',
        'tasks_count',
        'total_tasks',
      ]),
      issuesCount: readCount(const [
        'issues',
        'issue_count',
        'issues_count',
        'client_issues',
        'total_issues',
      ]),
    );
  }

  /// Loads non-calendar dashboard data in a single request.
  Future<DashboardDataModel> getDashboardData() async {
    final response = await get(ApiConstants.dashboard);
    final root = _normalizeMap(response.data);

    final projectSummary = _normalizeMap(root['project_summary'] ?? const {});
    final tasksSummary = _normalizeMap(root['tasks_summary'] ?? const {});
    final monthlyPoints = _extractDashboardNamedList(projectSummary, const [
      'projects_tasks_monthly',
      'projectsTasksMonthly',
      'monthly',
      'months',
    ]);

    final recentMonthly = monthlyPoints.length > 6
        ? monthlyPoints.sublist(monthlyPoints.length - 6)
        : monthlyPoints;
    final monthLabels = recentMonthly
        .map(
          (item) => _toShortMonthLabel(
            item['month_label']?.toString(),
            item['month_key']?.toString(),
          ),
        )
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
    final projectMonthlySeries = recentMonthly
        .map((item) => _readInt(item['project_count']) ?? 0)
        .toList(growable: false);
    final taskMonthlySeries = recentMonthly
        .map((item) => _readInt(item['task_count']) ?? 0)
        .toList(growable: false);

    final renewals = _extractDashboardNamedList(root, const [
      'renewals',
      'all_renewals',
      'allRenewals',
    ]);
    final clientRenewals = renewals
        .where((entry) {
          final type = (entry['type'] ?? '').toString().toLowerCase();
          return type.contains('client');
        })
        .map(RenewalModel.fromJson)
        .toList(growable: false);
    final vendorRenewals = renewals
        .where((entry) {
          final type = (entry['type'] ?? '').toString().toLowerCase();
          return type.contains('vendor');
        })
        .map(RenewalModel.fromJson)
        .toList(growable: false);

    final clientIssues = _extractDashboardNamedList(root, const [
      'client_issues',
      'clientIssues',
      'issues',
      'recent_issues',
      'recentIssues',
    ]).map(ClientIssueModel.fromJson).toList(growable: false);

    final statusCounts = <String, int>{
      'notStarted': _readInt(tasksSummary['not_started']) ?? 0,
      'inProgress': _readInt(tasksSummary['in_progress']) ?? 0,
      'onHold': _readInt(tasksSummary['on_hold']) ?? 0,
      'completed': _readInt(tasksSummary['completed']) ?? 0,
      'cancelled': _readInt(tasksSummary['cancelled']) ?? 0,
    };

    return DashboardDataModel(
      totalProjects: _readInt(projectSummary['total_projects']) ?? 0,
      totalTasks: _readInt(projectSummary['total_tasks']) ?? 0,
      projectMonthlySeries: projectMonthlySeries,
      taskMonthlySeries: taskMonthlySeries,
      monthLabels: monthLabels,
      taskStatusCounts: statusCounts,
      clientRenewals: clientRenewals,
      vendorRenewals: vendorRenewals,
      clientIssues: clientIssues,
    );
  }

  /// Loads a single paginated leads page.
  Future<LeadListPageResult> getLeadsListPage({
    int page = 1,
    String? search,
    String? userId,
    String? roleId,
  }) async {
    final query = await _resolveLeadQueryParameters(
      userId: userId,
      roleId: roleId,
    );
    final normalizedPage = page < 1 ? 1 : page;
    final normalizedSearch = (search ?? '').trim();
    query['page'] = normalizedPage;
    if (normalizedSearch.isNotEmpty) {
      query['search'] = normalizedSearch;
    }
    final response = await get(ApiConstants.leads, queryParameters: query);
    return _parseLeadPageResponse(response.data, normalizedPage);
  }

  /// Loads a single lead by id.
  Future<LeadModel> getLeadDetail(String id) async {
    final path = ApiConstants.leadDetail.replaceFirst('{id}', id);
    final response = await get(path);
    final body = _normalizeMap(_extractDetailSource(response.data));
    return LeadModel.fromJson(body);
  }

  /// Loads form option data required by the add lead screen.
  Future<LeadFormOptionsModel> getLeadFormOptions() async {
    final response = await get(ApiConstants.leadformdata);
    final body = _normalizeMap(response.data);
    return LeadFormOptionsModel.fromJson(body);
  }

  /// Loads form option data required by the add project screen.
  Future<ProjectFormOptionsModel> getProjectFormOptions() async {
    final response = await get(ApiConstants.formdataProject);
    final body = _normalizeMap(response.data);
    return ProjectFormOptionsModel.fromJson(body);
  }

  /// Creates a new project.
  Future<void> createProject({
    required String projectName,
    required dynamic customer,
    required String status,
    String? startDate,
    String? deadline,
    String? billingType,
    double? totalRate,
    double? estimatedHours,
    List<String> tags = const [],
    List<dynamic> members = const [],
    String? description,
    String? priority,
    List<String> technologies = const [],
  }) async {
    final payload = _buildProjectPayload(
      projectName: projectName,
      customer: customer,
      status: status,
      startDate: startDate,
      deadline: deadline,
      billingType: billingType,
      totalRate: totalRate,
      estimatedHours: estimatedHours,
      tags: tags,
      members: members,
      description: description,
      priority: priority,
      technologies: technologies,
    );
    await post(ApiConstants.createprojects, data: payload);
  }

  /// Updates an existing project.
  Future<void> updateProject({
    required String id,
    required String projectName,
    required dynamic customer,
    required String status,
    String? startDate,
    String? deadline,
    String? billingType,
    double? totalRate,
    double? estimatedHours,
    List<String> tags = const [],
    List<dynamic> members = const [],
    String? description,
    String? priority,
    List<String> technologies = const [],
  }) async {
    final path = ApiConstants.updateProject.replaceFirst('{id}', id);
    final payload = _buildProjectPayload(
      projectName: projectName,
      customer: customer,
      status: status,
      startDate: startDate,
      deadline: deadline,
      billingType: billingType,
      totalRate: totalRate,
      estimatedHours: estimatedHours,
      tags: tags,
      members: members,
      description: description,
      priority: priority,
      technologies: technologies,
    );
    await put(path, data: payload);
  }

  /// Deletes a single project by id.
  Future<void> deleteProject(String id, {dynamic data}) async {
    final path = ApiConstants.deleteProject.replaceFirst('{id}', id);
    await delete(path, data: data);
  }

  Map<String, dynamic> _buildProjectPayload({
    required String projectName,
    required dynamic customer,
    required String status,
    String? startDate,
    String? deadline,
    String? billingType,
    double? totalRate,
    double? estimatedHours,
    List<String> tags = const [],
    List<dynamic> members = const [],
    String? description,
    String? priority,
    List<String> technologies = const [],
  }) {
    final payload = <String, dynamic>{
      'project_name': projectName.trim(),
      'customer': customer,
      'status': status.trim(),
      'tags': tags,
      'members': members,
      'technologies': technologies,
    };

    if (startDate != null && startDate.trim().isNotEmpty) {
      payload['start_date'] = startDate.trim();
    }
    if (deadline != null && deadline.trim().isNotEmpty) {
      payload['deadline'] = deadline.trim();
    }
    if (billingType != null && billingType.trim().isNotEmpty) {
      payload['billing_type'] = billingType.trim();
    }
    if (totalRate != null) {
      payload['total_rate'] = totalRate;
    }
    if (estimatedHours != null) {
      payload['estimated_hours'] = estimatedHours;
    }
    if (description != null && description.trim().isNotEmpty) {
      payload['description'] = description.trim();
    }
    if (priority != null && priority.trim().isNotEmpty) {
      payload['priority'] = priority.trim();
    }

    return payload;
  }

  /// Deletes a single lead by id.
  Future<void> deleteLead(String id) async {
    final path = ApiConstants.leadDelete.replaceFirst('{id}', id);
    await delete(path);
  }

  /// Creates a new lead.
  Future<void> createLead({
    required String name,
    required String source,
    required String status,
    String? email,
    String? phone,
    String? company,
    String? position,
    String? website,
    String? address,
    String? city,
    String? state,
    String? country,
    String? zipCode,
    double? leadValue,
    List<dynamic> assigned = const [],
    List<String> tags = const [],
    String? description,
  }) async {
    final payload = _buildLeadPayload(
      name: name,
      source: source,
      status: status,
      email: email,
      phone: phone,
      company: company,
      position: position,
      website: website,
      address: address,
      city: city,
      state: state,
      country: country,
      zipCode: zipCode,
      leadValue: leadValue,
      assigned: assigned,
      tags: tags,
      description: description,
    );
    await post(ApiConstants.createleads, data: payload);
  }

  /// Updates an existing lead.
  Future<void> updateLead({
    required String id,
    required String name,
    required String source,
    required String status,
    String? email,
    String? phone,
    String? company,
    String? position,
    String? website,
    String? address,
    String? city,
    String? state,
    String? country,
    String? zipCode,
    double? leadValue,
    List<dynamic> assigned = const [],
    List<String> tags = const [],
    String? description,
  }) async {
    final path = ApiConstants.editleads.replaceFirst('{id}', id);
    final payload = _buildLeadPayload(
      name: name,
      source: source,
      status: status,
      email: email,
      phone: phone,
      company: company,
      position: position,
      website: website,
      address: address,
      city: city,
      state: state,
      country: country,
      zipCode: zipCode,
      leadValue: leadValue,
      assigned: assigned,
      tags: tags,
      description: description,
    );
    await put(path, data: payload);
  }

  /// Creates a new todo for the authenticated user.
  Future<List<Map<String, dynamic>>> getTodoList() async {
    final response = await get(ApiConstants.listtodo);
    return _normalizeList(response.data);
  }

  /// Loads task-list records for the authenticated user.
  Future<List<Map<String, dynamic>>> getTasksList({String? status}) async {
    final normalizedStatus = _normalizeTaskStatus(status);
    final query = <String, dynamic>{};
    if (normalizedStatus.isNotEmpty) {
      query['status'] = normalizedStatus;
    }
    final response = await get(
      ApiConstants.tasks,
      queryParameters: query.isEmpty ? null : query,
    );
    return _normalizeList(response.data);
  }

  /// Loads a single paginated tasks page for the authenticated user.
  Future<TaskListPageResult> getTasksListPage({
    int page = 1,
    String? search,
    String? status,
  }) async {
    final normalizedPage = page < 1 ? 1 : page;
    final normalizedSearch = (search ?? '').trim();
    final normalizedStatus = _normalizeTaskStatus(status);
    final query = <String, dynamic>{'page': normalizedPage, 'per_page': 10};
    if (normalizedSearch.isNotEmpty) {
      query['search'] = normalizedSearch;
    }
    if (normalizedStatus.isNotEmpty) {
      query['status'] = normalizedStatus;
    }
    final response = await get(ApiConstants.tasks, queryParameters: query);
    final parsed = _parseTaskPageResponse(response.data, normalizedPage);
    return _resolveTaskPageResultFromMeta(
      parsed: parsed,
      responseData: response.data,
      fallbackPage: normalizedPage,
    );
  }

  /// Loads book-a-call records for the authenticated user.
  Future<List<Map<String, dynamic>>> getBookACallList() async {
    final response = await get(ApiConstants.bookACall);
    return _normalizeList(response.data);
  }

  /// Loads a single paginated book-a-call page.
  Future<MapListPageResult> getBookACallListPage({
    int page = 1,
    int? perPage,
    String? search,
  }) async {
    final normalizedPage = page < 1 ? 1 : page;
    final normalizedSearch = (search ?? '').trim();
    final query = <String, dynamic>{'page': normalizedPage};
    if (perPage != null && perPage > 0) {
      query['per_page'] = perPage;
    }
    if (normalizedSearch.isNotEmpty) {
      query['search'] = normalizedSearch;
    }
    final response = await get(ApiConstants.bookACall, queryParameters: query);
    return _parseMapListPageResponse(response.data, normalizedPage);
  }

  /// Deletes a single book-a-call record by id.
  Future<void> deleteBookACall(String id) async {
    final normalizedId = id.trim();
    if (normalizedId.isEmpty) {
      throw Exception('Book-a-call id is required.');
    }
    final path = ApiConstants.deleteBookACall.replaceFirst(
      '{id}',
      normalizedId,
    );
    await delete(path);
  }

  /// Loads digital marketing leads for the authenticated user.
  Future<List<Map<String, dynamic>>> getDigitalMarketingLeads() async {
    final response = await get(ApiConstants.digitalMarketingLeads);
    return _normalizeList(response.data);
  }

  /// Loads a single paginated digital marketing leads page.
  Future<MapListPageResult> getDigitalMarketingLeadsPage({
    int page = 1,
    int? perPage,
    String? search,
  }) async {
    final normalizedPage = page < 1 ? 1 : page;
    final normalizedSearch = (search ?? '').trim();
    final query = <String, dynamic>{'page': normalizedPage};
    if (perPage != null && perPage > 0) {
      query['per_page'] = perPage;
    }
    if (normalizedSearch.isNotEmpty) {
      query['search'] = normalizedSearch;
    }
    final response = await get(
      ApiConstants.digitalMarketingLeads,
      queryParameters: query,
    );
    return _parseMapListPageResponse(response.data, normalizedPage);
  }

  /// Loads a single paginated Google Ads leads page.
  Future<MapListPageResult> getGoogleAdsLeadsPage({
    int page = 1,
    int? perPage,
    String? search,
    String? type,
    String? campaignId,
    String? leadStage,
  }) async {
    final normalizedPage = page < 1 ? 1 : page;
    final normalizedSearch = (search ?? '').trim();
    final normalizedType = (type ?? '').trim();
    final normalizedCampaignId = (campaignId ?? '').trim();
    final normalizedLeadStage = (leadStage ?? '').trim();

    final query = <String, dynamic>{'page': normalizedPage};
    if (perPage != null && perPage > 0) {
      query['per_page'] = perPage;
    }
    if (normalizedSearch.isNotEmpty) {
      query['search'] = normalizedSearch;
    }
    if (normalizedType.isNotEmpty) {
      query['type'] = normalizedType;
    }
    if (normalizedCampaignId.isNotEmpty) {
      query['campaign_id'] = normalizedCampaignId;
    }
    if (normalizedLeadStage.isNotEmpty) {
      query['lead_stage'] = normalizedLeadStage;
    }

    final response = await get(
      ApiConstants.googleAdsLeads,
      queryParameters: query,
    );
    return _parseMapListPageResponse(response.data, normalizedPage);
  }

  /// Loads a single Google Ads lead detail by id.
  Future<Map<String, dynamic>> getGoogleAdsLeadDetail(String id) async {
    final normalizedId = id.trim();
    if (normalizedId.isEmpty) {
      throw Exception('Google Ads lead id is required.');
    }
    final path = ApiConstants.googleAdsLeadDetail.replaceFirst(
      '{id}',
      normalizedId,
    );
    final response = await get(path);
    final source = _extractDetailSource(response.data);
    return _normalizeMap(source);
  }

  /// Deletes a single digital marketing lead by id.
  Future<void> deleteDigitalMarketingLead(String id) async {
    final normalizedId = id.trim();
    if (normalizedId.isEmpty) {
      throw Exception('Digital marketing lead id is required.');
    }
    final path = ApiConstants.deleteDigitalMarketingLead.replaceFirst(
      '{id}',
      normalizedId,
    );
    await delete(path);
  }

  /// Loads web apps leads for the authenticated user.
  Future<List<Map<String, dynamic>>> getWebAppsLeads() async {
    final response = await get(ApiConstants.webAppsLeads);
    return _normalizeList(response.data);
  }

  /// Loads a single paginated web-apps leads page.
  Future<MapListPageResult> getWebAppsLeadsPage({
    int page = 1,
    int? perPage,
    String? search,
  }) async {
    final normalizedPage = page < 1 ? 1 : page;
    final normalizedSearch = (search ?? '').trim();
    final query = <String, dynamic>{'page': normalizedPage};
    if (perPage != null && perPage > 0) {
      query['per_page'] = perPage;
    }
    if (normalizedSearch.isNotEmpty) {
      query['search'] = normalizedSearch;
    }
    final response = await get(
      ApiConstants.webAppsLeads,
      queryParameters: query,
    );
    return _parseMapListPageResponse(response.data, normalizedPage);
  }

  /// Loads a single paginated Meta leads page.
  Future<MapListPageResult> getMetaLeadsPage({
    int page = 1,
    int? perPage,
    String? search,
    String? dateFrom,
    String? dateTo,
    String? formId,
  }) async {
    final normalizedPage = page < 1 ? 1 : page;
    final normalizedSearch = (search ?? '').trim();
    final normalizedDateFrom = (dateFrom ?? '').trim();
    final normalizedDateTo = (dateTo ?? '').trim();
    final normalizedFormId = (formId ?? '').trim();

    final query = <String, dynamic>{'page': normalizedPage};
    if (perPage != null && perPage > 0) {
      final clampedPerPage = perPage > 100 ? 100 : perPage;
      query['per_page'] = clampedPerPage;
    }
    if (normalizedSearch.isNotEmpty) {
      query['search'] = normalizedSearch;
    }
    if (normalizedDateFrom.isNotEmpty) {
      query['date_from'] = normalizedDateFrom;
    }
    if (normalizedDateTo.isNotEmpty) {
      query['date_to'] = normalizedDateTo;
    }
    if (normalizedFormId.isNotEmpty) {
      query['form_id'] = normalizedFormId;
    }

    final response = await get(ApiConstants.metaLeads, queryParameters: query);
    return _parseMapListPageResponse(response.data, normalizedPage);
  }

  /// Loads a single Meta lead by id.
  Future<Map<String, dynamic>> getMetaLeadDetail(String id) async {
    final normalizedId = id.trim();
    if (normalizedId.isEmpty) {
      throw Exception('Meta lead id is required.');
    }
    final path = ApiConstants.metaLeadDetail.replaceFirst('{id}', normalizedId);
    final response = await get(path);
    final body = _normalizeMap(response.data);
    final detail = _normalizeMap(_extractDetailSource(body));
    return detail.isNotEmpty ? detail : body;
  }

  /// Deletes a single Meta lead by id.
  Future<void> deleteMetaLead(String id) async {
    final normalizedId = id.trim();
    if (normalizedId.isEmpty) {
      throw Exception('Meta lead id is required.');
    }
    final path = ApiConstants.deleteMetaLead.replaceFirst('{id}', normalizedId);
    await delete(path);
  }

  Future<NotificationListPageResult> getNotificationsPage({
    int page = 1,
    int perPage = 20,
  }) async {
    final normalizedPage = page < 1 ? 1 : page;
    final normalizedPerPage = perPage < 1 ? 20 : perPage;
    final response = await get(
      ApiConstants.notifications,
      queryParameters: <String, dynamic>{
        'page': normalizedPage,
        'per_page': normalizedPerPage,
      },
    );

    final root = _normalizeMap(response.data);
    final source = _extractListSource(root['data']);
    final records = source is List
        ? source.map(_normalizeMap).toList(growable: false)
        : const <Map<String, dynamic>>[];
    final meta = _normalizeMap(root['meta']);

    final currentPage = _readInt(meta['current_page']) ?? normalizedPage;
    final lastPage = _readInt(meta['last_page']) ?? currentPage;
    final total = _readInt(meta['total']) ?? records.length;
    final resolvedPerPage = _readInt(meta['per_page']) ?? normalizedPerPage;
    final unreadCount = _readInt(meta['unread_count']) ?? 0;
    final hasNextPage = currentPage < lastPage;

    return NotificationListPageResult(
      items: records,
      currentPage: currentPage,
      lastPage: lastPage,
      total: total,
      perPage: resolvedPerPage,
      hasNextPage: hasNextPage,
      unreadCount: unreadCount,
    );
  }

  Future<void> markNotificationAsRead(String id) async {
    final normalizedId = id.trim();
    if (normalizedId.isEmpty) return;

    final path = ApiConstants.notificationRead.replaceFirst(
      '{id}',
      normalizedId,
    );
    await patch(path);
  }

  Future<void> markAllNotificationsAsRead() async {
    await patch(ApiConstants.notificationReadAll);
  }

  /// Deletes a single web apps lead by id.
  Future<void> deleteWebAppsLead(String id) async {
    final normalizedId = id.trim();
    if (normalizedId.isEmpty) {
      throw Exception('Web apps lead id is required.');
    }
    final path = ApiConstants.deleteWebAppsLead.replaceFirst(
      '{id}',
      normalizedId,
    );
    await delete(path);
  }

  /// Loads tasks assigned to a specific staff member.
  Future<List<Map<String, dynamic>>> getStaffTasksList(
    String staffId, {
    String? status,
  }) async {
    final id = staffId.trim();
    if (id.isEmpty) return const <Map<String, dynamic>>[];

    final normalizedStatus = _normalizeTaskStatus(status);
    final query = <String, dynamic>{};
    if (normalizedStatus.isNotEmpty) {
      query['status'] = normalizedStatus;
    }
    final path = ApiConstants.stafftasks.replaceFirst('{id}', id);
    final response = await get(
      path,
      queryParameters: query.isEmpty ? null : query,
    );
    return _normalizeList(response.data);
  }

  /// Loads a single paginated tasks page assigned to a specific staff member.
  Future<TaskListPageResult> getStaffTasksListPage({
    required String staffId,
    int page = 1,
    String? search,
    String? status,
  }) async {
    final id = staffId.trim();
    if (id.isEmpty) {
      return const TaskListPageResult(
        items: <Map<String, dynamic>>[],
        currentPage: 1,
        lastPage: 1,
        total: 0,
        perPage: 10,
        hasNextPage: false,
        statusCounts: <String, int>{},
      );
    }
    final normalizedPage = page < 1 ? 1 : page;
    final normalizedSearch = (search ?? '').trim();
    final normalizedStatus = _normalizeTaskStatus(status);
    final query = <String, dynamic>{'page': normalizedPage, 'per_page': 10};
    if (normalizedSearch.isNotEmpty) {
      query['search'] = normalizedSearch;
    }
    if (normalizedStatus.isNotEmpty) {
      query['status'] = normalizedStatus;
    }
    final path = ApiConstants.stafftasks.replaceFirst('{id}', id);
    final response = await get(path, queryParameters: query);
    final parsed = _parseTaskPageResponse(response.data, normalizedPage);
    return _resolveTaskPageResultFromMeta(
      parsed: parsed,
      responseData: response.data,
      fallbackPage: normalizedPage,
    );
  }

  TaskListPageResult _resolveTaskPageResultFromMeta({
    required TaskListPageResult parsed,
    required dynamic responseData,
    required int fallbackPage,
  }) {
    final root = _normalizeMap(responseData);
    final meta = _normalizeLooseMap(root['meta']);
    final metaPagination = _normalizeLooseMap(meta['pagination']);

    final metaCurrentPage =
        _readInt(metaPagination['current_page']) ??
        _readInt(meta['current_page']) ??
        fallbackPage;
    final metaLastPage =
        _readInt(metaPagination['last_page']) ??
        _readInt(meta['last_page']) ??
        parsed.lastPage;
    final metaTotal =
        _readInt(metaPagination['total']) ??
        _readInt(meta['total']) ??
        parsed.total;
    final metaPerPage =
        _readInt(metaPagination['per_page']) ??
        _readInt(meta['per_page']) ??
        parsed.perPage;
    final metaHasMorePages =
        metaPagination['has_more_pages'] == true ||
        metaPagination['hasMorePages'] == true ||
        (metaCurrentPage < metaLastPage);

    if (metaLastPage <= parsed.lastPage &&
        metaTotal <= parsed.total &&
        metaPerPage <= 0) {
      return parsed;
    }

    return TaskListPageResult(
      items: parsed.items,
      currentPage: metaCurrentPage < 1 ? parsed.currentPage : metaCurrentPage,
      lastPage: metaLastPage < 1 ? parsed.lastPage : metaLastPage,
      total: metaTotal < 0 ? parsed.total : metaTotal,
      perPage: metaPerPage < 1 ? parsed.perPage : metaPerPage,
      hasNextPage: parsed.hasNextPage || metaHasMorePages,
      statusCounts: parsed.statusCounts,
    );
  }

  Map<String, dynamic> _normalizeLooseMap(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is Map) {
      return data.map((key, value) => MapEntry(key.toString(), value));
    }
    return const <String, dynamic>{};
  }

  /// Loads a single task record by id.
  Future<Map<String, dynamic>> getTaskDetail(String id) async {
    final path = ApiConstants.taskDetail.replaceFirst('{id}', id);
    final response = await get(path);
    final body = _normalizeMap(response.data);
    final detail = _normalizeMap(_extractDetailSource(body));
    return <String, dynamic>{...body, ...detail};
  }

  /// Loads comments for a task by id.
  Future<List<ProjectCommentModel>> getTaskComments(String id) async {
    final path = ApiConstants.taskcomments.replaceFirst('{id}', id);
    final response = await get(path);
    final source = _extractListSource(response.data);
    if (source is! List) {
      throw DioException(
        requestOptions: response.requestOptions,
        error: 'Unexpected task comments response format',
        type: DioExceptionType.unknown,
      );
    }

    final records = source.map(_normalizeMap).toList();
    return records
        .map(ProjectCommentModel.fromJson)
        .where((entry) => entry.comment.trim().isNotEmpty)
        .toList();
  }

  /// Creates a comment for a task.
  Future<ProjectCommentModel> createTaskComment({
    required String taskId,
    required String comment,
  }) async {
    final path = ApiConstants.createtaskcomments.replaceFirst('{id}', taskId);
    final response = await post(path, data: {'comment': comment.trim()});
    final source = _normalizeMap(_extractDetailSource(response.data));
    return ProjectCommentModel.fromJson(source);
  }

  /// Creates a task-list record with one or more nested tasks.
  Future<Map<String, dynamic>> createTaskList({
    required String title,
    String? description,
    required List<Map<String, dynamic>> tasks,
  }) async {
    final payload = _buildTaskListPayload(
      title: title,
      description: description,
      tasks: tasks,
    );
    final response = await post(ApiConstants.createTask, data: payload);
    final data = response.data;

    if (data == null) {
      return payload;
    }

    return _normalizeMap(_extractDetailSource(data));
  }

  /// Creates a single task record.
  Future<Map<String, dynamic>> createTaskRecord({
    required String title,
    String? description,
    String? status,
    String? priority,
    String? projectId,
    DateTime? startDate,
    DateTime? deadline,
    List<String> assigneeIds = const [],
    List<String> followerIds = const [],
    List<String> tags = const [],
    List<String> attachmentPaths = const [],
  }) async {
    final payload = _buildCreateTaskPayload(
      title: title,
      description: description,
      status: status,
      priority: priority,
      projectId: projectId,
      startDate: startDate,
      deadline: deadline,
      assigneeIds: assigneeIds,
      followerIds: followerIds,
      tags: tags,
    );
    final formData = await _buildTaskFormData(
      payload: payload,
      attachmentPaths: attachmentPaths,
    );
    final response = await postForm(ApiConstants.createTask, data: formData);
    final data = response.data;

    if (data == null) {
      return payload;
    }

    return _normalizeMap(_extractDetailSource(data));
  }

  /// Updates a task record by id.
  Future<void> updateTaskRecord({
    required String id,
    required String title,
    String? description,
    String? status,
    String? priority,
    String? projectId,
    DateTime? startDate,
    DateTime? deadline,
    List<String> assigneeIds = const [],
    List<String> followerIds = const [],
    List<String> tags = const [],
    List<String> attachmentPaths = const [],
  }) async {
    final path = ApiConstants.updateTask.replaceFirst('{id}', id);
    final payload = _buildUpdateTaskPayload(
      title: title,
      description: description,
      status: status,
      priority: priority,
      projectId: projectId,
      startDate: startDate,
      deadline: deadline,
      assigneeIds: assigneeIds,
      followerIds: followerIds,
      tags: tags,
    );
    final updatePayload = <String, dynamic>{...payload, '_method': 'PUT'};
    final formData = await _buildTaskFormData(
      payload: updatePayload,
      attachmentPaths: attachmentPaths,
    );
    await postForm(path, data: formData);
  }

  /// Deletes a task record by id.
  Future<void> deleteTaskRecord(String id) async {
    final path = ApiConstants.deleteTask.replaceFirst('{id}', id);
    await delete(path);
  }

  /// Creates a new todo for the authenticated user.
  Future<void> createTodo({
    required String title,
    String? description,
    required DateTime taskDate,
    TimeOfDay? taskTime,
    required int repeatInterval,
    required String repeatUnit,
    List<String> repeatDays = const [],
    TimeOfDay? reminderTime,
    bool reminderEmail = false,
    bool reminderWhatsapp = false,
    required DateTime startsOn,
    required String endsType,
    DateTime? endsOn,
    int? endsAfter,
    List<String> attachmentPaths = const [],
  }) async {
    final payload = _buildTodoPayload(
      title: title,
      description: description,
      taskDate: taskDate,
      taskTime: taskTime,
      repeatInterval: repeatInterval,
      repeatUnit: repeatUnit,
      repeatDays: repeatDays,
      reminderTime: reminderTime,
      reminderEmail: reminderEmail,
      reminderWhatsapp: reminderWhatsapp,
      startsOn: startsOn,
      endsType: endsType,
      endsOn: endsOn,
      endsAfter: endsAfter,
    );
    if (attachmentPaths.isNotEmpty) {
      await postForm(
        ApiConstants.createtodo,
        data: await _buildTodoFormData(
          payload: payload,
          attachmentPaths: attachmentPaths,
        ),
      );
      return;
    }

    await post(ApiConstants.createtodo, data: payload);
  }

  Future<void> updateTodo({
    required String id,
    required String title,
    String? description,
    required DateTime taskDate,
    TimeOfDay? taskTime,
    required int repeatInterval,
    required String repeatUnit,
    List<String> repeatDays = const [],
    TimeOfDay? reminderTime,
    bool reminderEmail = false,
    bool reminderWhatsapp = false,
    required DateTime startsOn,
    required String endsType,
    DateTime? endsOn,
    int? endsAfter,
    List<String> attachmentPaths = const [],
  }) async {
    final path = ApiConstants.edittodo.replaceFirst('{id}', id);
    final payload = _buildTodoPayload(
      title: title,
      description: description,
      taskDate: taskDate,
      taskTime: taskTime,
      repeatInterval: repeatInterval,
      repeatUnit: repeatUnit,
      repeatDays: repeatDays,
      reminderTime: reminderTime,
      reminderEmail: reminderEmail,
      reminderWhatsapp: reminderWhatsapp,
      startsOn: startsOn,
      endsType: endsType,
      endsOn: endsOn,
      endsAfter: endsAfter,
    );
    final updatePayload = <String, dynamic>{...payload, '_method': 'PUT'};
    await postForm(
      path,
      data: await _buildTodoFormData(
        payload: updatePayload,
        attachmentPaths: attachmentPaths,
      ),
    );
  }

  Future<void> deleteTodo({
    required String id,
    required String title,
    String? description,
    required DateTime taskDate,
    TimeOfDay? taskTime,
    required int repeatInterval,
    required String repeatUnit,
    TimeOfDay? reminderTime,
    required DateTime startsOn,
    required String endsType,
    DateTime? endsOn,
    int? endsAfter,
  }) async {
    final path = ApiConstants.deletetodo.replaceFirst('{id}', id);
    final payload = _buildTodoPayload(
      title: title,
      description: description,
      taskDate: taskDate,
      taskTime: taskTime,
      repeatInterval: repeatInterval,
      repeatUnit: repeatUnit,
      reminderTime: reminderTime,
      startsOn: startsOn,
      endsType: endsType,
      endsOn: endsOn,
      endsAfter: endsAfter,
    );
    await delete(path, data: payload);
  }

  Future<void> toggleTodoStatus({
    required String id,
    required bool isCompleted,
  }) async {
    final path = ApiConstants.statustodo.replaceFirst('{id}', id);
    await patch(path, data: <String, dynamic>{'is_completed': isCompleted});
  }

  Map<String, dynamic> _buildLeadPayload({
    required String name,
    required String source,
    required String status,
    String? email,
    String? phone,
    String? company,
    String? position,
    String? website,
    String? address,
    String? city,
    String? state,
    String? country,
    String? zipCode,
    double? leadValue,
    List<dynamic> assigned = const [],
    List<String> tags = const [],
    String? description,
  }) {
    final payload = <String, dynamic>{
      'name': name,
      'source': source,
      'status': status,
    };

    void addIfNotEmpty(String key, String? value) {
      final normalized = value?.trim() ?? '';
      if (normalized.isNotEmpty) {
        payload[key] = normalized;
      }
    }

    addIfNotEmpty('email', email);
    addIfNotEmpty('phone', phone);
    addIfNotEmpty('company', company);
    addIfNotEmpty('position', position);
    addIfNotEmpty('website', website);
    addIfNotEmpty('address', address);
    addIfNotEmpty('city', city);
    addIfNotEmpty('state', state);
    addIfNotEmpty('country', country);
    addIfNotEmpty('zipCode', zipCode);
    addIfNotEmpty('description', description);

    if (leadValue != null) {
      payload['lead_value'] = leadValue;
    }

    if (assigned.isNotEmpty) {
      payload['assigned'] = assigned;
    }

    if (tags.isNotEmpty) {
      payload['tags'] = tags;
    }

    return payload;
  }

  /// Loads a single client by id.
  Future<ClientDetailModel> getClientDetail(String id) async {
    final path = ApiConstants.clientDetail.replaceFirst('{id}', id);
    try {
      final response = await get(path);
      final body = _normalizeMap(_extractDetailSource(response.data));
      return ClientDetailModel.fromJson(body);
    } on DioException {
      final fallback = await _tryClientDetailFromList(id);
      if (fallback != null) {
        return fallback;
      }
      rethrow;
    }
  }

  /// Loads a single vendor by id.
  Future<VendorModel> getVendorDetail(String id) async {
    final path = ApiConstants.vendorDetail.replaceFirst('{id}', id);
    try {
      final response = await get(path);
      final body = _normalizeMap(response.data);
      return VendorModel.fromJson(body);
    } on DioException {
      final fallback = await _tryVendorDetailFromList(id);
      if (fallback != null) {
        return fallback;
      }
      rethrow;
    }
  }

  /// Loads projects linked to a single client.
  Future<List<ProjectModel>> getClientProjectsList(String clientId) async {
    final id = clientId.trim();
    if (id.isEmpty) return const <ProjectModel>[];

    final path = ApiConstants.clientsprojects.replaceFirst('{id}', id);
    final response = await get(path);
    final records = _normalizeList(response.data);
    return records.map(ProjectModel.fromJson).toList();
  }

  /// Loads tasks linked to a single client.
  Future<List<Map<String, dynamic>>> getClientTasksList(String clientId) async {
    final id = clientId.trim();
    if (id.isEmpty) return const <Map<String, dynamic>>[];

    final path = ApiConstants.clientstasks.replaceFirst('{id}', id);
    final response = await get(path);
    return _normalizeList(response.data);
  }

  /// Loads a single staff member by id.
  Future<StaffMemberModel> getStaffDetail(String id) async {
    final path = ApiConstants.staffdetail.replaceFirst('{id}', id);
    final response = await get(path);
    final body = _normalizeMap(_extractDetailSource(response.data));
    return StaffMemberModel.fromJson(body);
  }

  /// Deletes a single staff member by id.
  Future<void> deleteStaff(String id) async {
    final path = ApiConstants.deletestaff.replaceFirst('{id}', id);
    await delete(path);
    _invalidateStaffCaches();
  }

  /// Updates a single staff member by id.
  Future<void> editStaff({
    required String id,
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String status,
    required dynamic team,
    required List<dynamic> departments,
    String? role,
    String? password,
  }) async {
    dynamic normalizeIdOrValue(dynamic value) {
      if (value is num) return value;
      final text = value?.toString().trim() ?? '';
      final parsed = int.tryParse(text);
      return parsed ?? text;
    }

    final normalizedTeam = normalizeIdOrValue(team);
    final normalizedDepartments = departments
        .map<dynamic>(normalizeIdOrValue)
        .where((value) => value.toString().trim().isNotEmpty)
        .toList(growable: false);

    final path = ApiConstants.editstaff.replaceFirst('{id}', id);
    final payload = <String, dynamic>{
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'phone': phone,
      'status': status,
      'team': normalizedTeam,
      'departments': normalizedDepartments,
    };

    if (role != null && role.trim().isNotEmpty) {
      payload['role'] = role.trim();
    }

    if (password != null && password.trim().isNotEmpty) {
      payload['password'] = password.trim();
    }

    await put(path, data: payload);
    _invalidateStaffCaches();
  }

  /// Creates a new staff member.
  Future<void> createStaff({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String status,
    required dynamic team,
    required List<dynamic> departments,
    required String password,
    bool sendWelcomeEmail = true,
    String? role,
    String? profileImagePath,
  }) async {
    dynamic normalizeIdOrValue(dynamic value) {
      if (value is num) return value;
      final text = value?.toString().trim() ?? '';
      final parsed = int.tryParse(text);
      return parsed ?? text;
    }

    final normalizedTeam = normalizeIdOrValue(team);
    final normalizedDepartments = departments
        .map<dynamic>(normalizeIdOrValue)
        .where((value) => value.toString().trim().isNotEmpty)
        .toList(growable: false);

    final payload = <String, dynamic>{
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'phone': phone,
      'status': status,
      'team': normalizedTeam,
      'departments': normalizedDepartments,
      'password': password,
      'sendWelcomeEmail': sendWelcomeEmail,
      'send_welcome_email': sendWelcomeEmail,
    };

    if (role != null && role.trim().isNotEmpty) {
      payload['role'] = role.trim();
    }

    if (profileImagePath != null && profileImagePath.isNotEmpty) {
      final formData = FormData();
      formData.fields.addAll(<MapEntry<String, String>>[
        MapEntry('first_name', firstName),
        MapEntry('last_name', lastName),
        MapEntry('email', email),
        MapEntry('phone', phone),
        MapEntry('status', status),
        MapEntry('team', normalizedTeam.toString()),
        MapEntry('password', password),
        MapEntry('sendWelcomeEmail', sendWelcomeEmail ? 'true' : 'false'),
        MapEntry('send_welcome_email', sendWelcomeEmail ? '1' : '0'),
      ]);
      for (final department in normalizedDepartments) {
        final value = department.toString().trim();
        if (value.isNotEmpty) {
          formData.fields.add(MapEntry('departments[]', value));
        }
      }
      if (role != null && role.trim().isNotEmpty) {
        formData.fields.add(MapEntry('role', role.trim()));
      }

      final fileName = profileImagePath.split(RegExp(r'[\\/]')).last;
      formData.files.add(
        MapEntry(
          'profile_image',
          await MultipartFile.fromFile(profileImagePath, filename: fileName),
        ),
      );

      await postForm(ApiConstants.createstaff, data: formData);
      _invalidateStaffCaches();
      return;
    }

    await post(ApiConstants.createstaff, data: payload);
    _invalidateStaffCaches();
  }

  /// Creates a new client.
  Future<void> createClient(CreateClientRequestModel request) async {
    final payload = request.toPayload();
    final formData = FormData();

    payload.forEach((key, value) {
      if (value == null || key == 'companies') return;
      if (key == 'send_invite_mail') {
        final invite = value is bool
            ? value
            : value.toString().trim().toLowerCase() == 'true';
        formData.fields.add(MapEntry('send_invite_mail', invite ? '1' : '0'));
        return;
      }
      formData.fields.add(MapEntry(key, value.toString()));
    });

    final companies = payload['companies'];
    if (companies is List) {
      for (var index = 0; index < companies.length; index++) {
        final company = companies[index];
        if (company is! Map) continue;
        for (final entry in company.entries) {
          final companyValue = entry.value?.toString().trim() ?? '';
          if (companyValue.isEmpty) continue;
          formData.fields.add(
            MapEntry('companies[$index][${entry.key}]', companyValue),
          );
        }
      }
    }

    final profileImagePath = request.normalizedProfileImagePath;
    if (profileImagePath != null) {
      final fileName = profileImagePath.split(RegExp(r'[\\/]')).last;
      formData.files.add(
        MapEntry(
          'profile_image',
          await MultipartFile.fromFile(profileImagePath, filename: fileName),
        ),
      );
    }

    await postForm(ApiConstants.clients, data: formData);
  }

  String _maskAuthorizationHeader(String header) {
    const prefix = 'Bearer ';
    if (!header.startsWith(prefix)) return 'present';
    final token = header.substring(prefix.length).trim();
    if (token.isEmpty) return 'missing';
    if (token.length <= 10) return 'Bearer ***';
    final start = token.substring(0, 6);
    final end = token.substring(token.length - 4);
    return 'Bearer $start...$end';
  }

  void _debugAuthState(String label, String? token) {
    if (!kDebugMode) return;
    final normalized = token?.trim();
    final authState = normalized == null || normalized.isEmpty
        ? 'missing'
        : _maskAuthorizationHeader('Bearer $normalized');
    debugPrint('$label: $authState');
  }

  bool _isRedirectResponse(int? statusCode) {
    return statusCode == 301 ||
        statusCode == 302 ||
        statusCode == 307 ||
        statusCode == 308;
  }

  /// Updates an existing client.
  Future<void> updateClient({
    required String id,
    required UpdateClientRequestModel request,
    bool usePatch = false,
  }) async {
    final path = ApiConstants.updateClient.replaceFirst('{id}', id);
    final payload = request.toPayload();
    final profileImagePath = request.normalizedProfileImagePath;
    if (profileImagePath != null) {
      final fileName = profileImagePath.split(RegExp(r'[\\/]')).last;
      payload['profile_image'] = await MultipartFile.fromFile(
        profileImagePath,
        filename: fileName,
      );
    }

    if (usePatch) {
      await patch(path, data: payload);
      return;
    }

    if (profileImagePath != null) {
      await putForm(path, data: FormData.fromMap(payload));
      return;
    }

    await put(path, data: payload);
  }

  /// Creates a new vendor.
  Future<void> createVendor({
    required String name,
    required String email,
    required String phone,
    required String address,
    required String status,
  }) async {
    await post(
      ApiConstants.createvendors,
      data: {
        'name': name,
        'email': email,
        'phone': phone,
        'address': address,
        'status': _normalizeVendorStatus(status),
      },
    );
  }

  /// Updates an existing vendor.
  Future<void> updateVendor({
    required String id,
    required String name,
    required String email,
    required String phone,
    required String address,
    required String status,
  }) async {
    final path = ApiConstants.updateVendor.replaceFirst('{id}', id);
    await put(
      path,
      data: {
        'name': name,
        'email': email,
        'phone': phone,
        'address': address,
        'status': _normalizeVendorStatus(status),
      },
    );
  }

  String _normalizeVendorStatus(String status) {
    final normalized = status.trim().toLowerCase();
    if (normalized == '1' ||
        normalized == 'true' ||
        normalized == 'active' ||
        normalized == 'enabled') {
      return 'active';
    }
    if (normalized == '0' ||
        normalized == 'false' ||
        normalized == 'inactive' ||
        normalized == 'disabled') {
      return 'inactive';
    }
    return normalized;
  }

  /// Deletes an existing vendor.
  Future<void> deleteVendor(String id) async {
    final path = ApiConstants.deleteVendor.replaceFirst('{id}', id);
    await delete(path);
  }

  /// Deletes an existing client.
  Future<void> deleteClient(String id) async {
    final path = ApiConstants.deleteClient.replaceFirst('{id}', id);
    await delete(path);
  }

  /// Logs out the current user and clears the locally cached auth state.
  Future<void> logout() async {
    try {
      await post(ApiConstants.logout);
    } finally {
      await _clearAuthData();
    }
  }

  List<Map<String, dynamic>> _normalizeList(dynamic data) {
    final source = _extractListSource(data);
    if (source is List) {
      return source.map(_normalizeMap).toList();
    }

    throw DioException(
      requestOptions: RequestOptions(path: ApiConstants.liststaff),
      error: 'Unexpected staff list response format',
      type: DioExceptionType.unknown,
    );
  }

  List<Map<String, dynamic>> _extractDashboardNamedList(
    dynamic data,
    List<String> keys,
  ) {
    dynamic source;

    if (data is Map<String, dynamic>) {
      for (final key in keys) {
        final value = data[key];
        if (value is List) {
          source = value;
          break;
        }
        if (value is Map<String, dynamic>) {
          final nestedData = value['data'];
          if (nestedData is List) {
            source = nestedData;
            break;
          }
        }
        if (value is Map) {
          final nestedMap = value.map(
            (nestedKey, nestedValue) =>
                MapEntry(nestedKey.toString(), nestedValue),
          );
          final nestedData = nestedMap['data'];
          if (nestedData is List) {
            source = nestedData;
            break;
          }
        }
      }

      if (source == null) {
        final nested = data['data'];
        if (nested is Map<String, dynamic>) {
          return _extractDashboardNamedList(nested, keys);
        }
        if (nested is Map) {
          final normalizedNested = nested.map(
            (key, value) => MapEntry(key.toString(), value),
          );
          return _extractDashboardNamedList(normalizedNested, keys);
        }
      }
    } else if (data is Map) {
      final normalized = data.map(
        (key, value) => MapEntry(key.toString(), value),
      );
      return _extractDashboardNamedList(normalized, keys);
    }

    if (source is List) {
      return source.map(_normalizeMap).toList(growable: false);
    }
    return const <Map<String, dynamic>>[];
  }

  String _toShortMonthLabel(String? monthLabel, String? monthKey) {
    const months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    final normalizedLabel = (monthLabel ?? '').trim();
    if (normalizedLabel.isNotEmpty) {
      final parts = normalizedLabel.split(RegExp(r'\s+'));
      if (parts.isNotEmpty && parts.first.trim().isNotEmpty) {
        return parts.first.trim();
      }
    }

    final normalizedKey = (monthKey ?? '').trim();
    final match = RegExp(r'^(\d{4})-(\d{1,2})').firstMatch(normalizedKey);
    if (match != null) {
      final monthNumber = int.tryParse(match.group(2) ?? '');
      if (monthNumber != null && monthNumber >= 1 && monthNumber <= 12) {
        return months[monthNumber - 1];
      }
    }

    return '';
  }

  dynamic _extractListSource(dynamic data) {
    if (data is List) {
      return data;
    }

    if (data is Map<String, dynamic>) {
      for (final key in [
        'data',
        'items',
        'events',
        'calendar_events',
        'calendarEvents',
        'roles',
        'staff',
        'staffs',
        'clients',
        'customers',
        'vendors',
        'renewals',
        'vendor_renewals',
        'vendorRenewals',
        'client_renewals',
        'clientRenewals',
        'client_issues',
        'clientIssues',
        'clientissues',
        'book_a_call',
        'book_a_calls',
        'bookacall',
        'bookacalls',
        'projects',
        'milestones',
        'project_milestones',
        'projectMilestones',
        'issues',
        'project_issues',
        'projectIssues',
        'comments',
        'project_comments',
        'projectComments',
        'files',
        'attachments',
        'documents',
        'tasks',
        'task_lists',
        'todos',
        'results',
        'rows',
      ]) {
        final candidate = data[key];
        if (candidate is List) {
          return candidate;
        }

        if (candidate is Map<String, dynamic>) {
          final nestedSource = _extractListSource(candidate);
          if (nestedSource is List) {
            return nestedSource;
          }

          for (final nestedKey in [
            'data',
            'items',
            'events',
            'calendar_events',
            'calendarEvents',
            'roles',
            'staff',
            'staffs',
            'clients',
            'customers',
            'vendors',
            'renewals',
            'vendor_renewals',
            'vendorRenewals',
            'client_renewals',
            'clientRenewals',
            'client_issues',
            'clientIssues',
            'clientissues',
            'projects',
            'milestones',
            'project_milestones',
            'projectMilestones',
            'issues',
            'project_issues',
            'projectIssues',
            'comments',
            'project_comments',
            'projectComments',
            'files',
            'attachments',
            'documents',
            'tasks',
            'task_lists',
            'todos',
            'results',
            'rows',
          ]) {
            final nestedCandidate = candidate[nestedKey];
            if (nestedCandidate is List) {
              return nestedCandidate;
            }
            if (nestedCandidate is Map<String, dynamic>) {
              final deeperSource = _extractListSource(nestedCandidate);
              if (deeperSource is List) {
                return deeperSource;
              }
            }
          }
        }
      }
    }

    if (data is Map) {
      return _extractListSource(
        data.map((key, value) => MapEntry(key.toString(), value)),
      );
    }

    return data;
  }

  dynamic _extractTeamSettingsListSource(dynamic data) {
    if (data is List) {
      return data;
    }

    if (data is Map<String, dynamic>) {
      final directTeams =
          data['teams'] ?? data['team_settings'] ?? data['teamSettings'];
      if (directTeams is List) {
        return directTeams;
      }

      final nested = data['data'];
      if (nested is List) {
        return nested;
      }
      if (nested is Map<String, dynamic>) {
        final nestedTeams =
            nested['teams'] ??
            nested['team_settings'] ??
            nested['teamSettings'];
        if (nestedTeams is List) {
          return nestedTeams;
        }
      }
      if (nested is Map) {
        return _extractTeamSettingsListSource(
          nested.map((key, value) => MapEntry(key.toString(), value)),
        );
      }
    }

    if (data is Map) {
      return _extractTeamSettingsListSource(
        data.map((key, value) => MapEntry(key.toString(), value)),
      );
    }

    return _extractListSource(data);
  }

  dynamic _extractDepartmentSettingsListSource(dynamic data) {
    if (data is List) {
      return data;
    }

    if (data is Map<String, dynamic>) {
      final directDepartments =
          data['departments'] ??
          data['department_settings'] ??
          data['departmentSettings'];
      if (directDepartments is List) {
        return directDepartments;
      }

      final nested = data['data'];
      if (nested is List) {
        return nested;
      }
      if (nested is Map<String, dynamic>) {
        final nestedDepartments =
            nested['departments'] ??
            nested['department_settings'] ??
            nested['departmentSettings'];
        if (nestedDepartments is List) {
          return nestedDepartments;
        }
      }
      if (nested is Map) {
        return _extractDepartmentSettingsListSource(
          nested.map((key, value) => MapEntry(key.toString(), value)),
        );
      }
    }

    if (data is Map) {
      return _extractDepartmentSettingsListSource(
        data.map((key, value) => MapEntry(key.toString(), value)),
      );
    }

    return _extractListSource(data);
  }

  dynamic _extractClientIssueListSource(dynamic data) {
    if (data is List) {
      return data;
    }

    if (data is Map<String, dynamic>) {
      final directIssues =
          data['issues'] ?? data['client_issues'] ?? data['clientIssues'];
      if (directIssues is List) {
        return directIssues;
      }

      final nested = data['data'];
      if (nested is Map<String, dynamic>) {
        final nestedIssues =
            nested['issues'] ??
            nested['client_issues'] ??
            nested['clientIssues'];
        if (nestedIssues is List) {
          return nestedIssues;
        }
      }
      if (nested is Map) {
        return _extractClientIssueListSource(
          nested.map((key, value) => MapEntry(key.toString(), value)),
        );
      }
    }

    if (data is Map) {
      return _extractClientIssueListSource(
        data.map((key, value) => MapEntry(key.toString(), value)),
      );
    }

    return data;
  }

  List<Map<String, dynamic>> _extractClientIssueNamedList(
    dynamic data,
    List<String> keys,
  ) {
    dynamic source;

    if (data is Map<String, dynamic>) {
      for (final key in keys) {
        final value = data[key];
        if (value is List) {
          source = value;
          break;
        }
      }

      if (source == null) {
        final nested = data['data'];
        if (nested is Map<String, dynamic>) {
          for (final key in keys) {
            final value = nested[key];
            if (value is List) {
              source = value;
              break;
            }
          }
        } else if (nested is Map) {
          return _extractClientIssueNamedList(
            nested.map((key, value) => MapEntry(key.toString(), value)),
            keys,
          );
        }
      }
    } else if (data is Map) {
      return _extractClientIssueNamedList(
        data.map((key, value) => MapEntry(key.toString(), value)),
        keys,
      );
    }

    if (source is! List) {
      return const <Map<String, dynamic>>[];
    }

    return source.map(_normalizeMap).toList();
  }

  dynamic _extractDetailSource(dynamic data) {
    if (data is Map<String, dynamic>) {
      for (final key in [
        'data',
        'staff',
        'event',
        'calendar',
        'calendar_event',
        'calendarEvent',
        'project',
        'comment',
        'project_comment',
        'projectComment',
        'milestone',
        'project_milestone',
        'projectMilestone',
        'issue',
        'client_issue',
        'clientIssue',
        'project_issue',
        'projectIssue',
        'client',
        'customer',
        'vendor',
        'renewal',
        'vendor_renewal',
        'vendorRenewal',
        'client_renewal',
        'clientRenewal',
        'service',
        'task',
        'todo',
        'file',
        'project_file',
        'projectFile',
        'item',
        'result',
        'lead',
      ]) {
        final candidate = data[key];
        if (candidate is Map<String, dynamic>) {
          return candidate;
        }
      }
    }

    if (data is Map) {
      return _extractDetailSource(
        data.map((key, value) => MapEntry(key.toString(), value)),
      );
    }

    return data;
  }

  dynamic _extractClientIssueTaskSource(dynamic data) {
    if (data is Map<String, dynamic>) {
      final directTask = data['task'];
      if (directTask is Map<String, dynamic>) {
        return directTask;
      }
      if (directTask is Map) {
        return directTask.map((key, value) => MapEntry(key.toString(), value));
      }

      final nestedData = data['data'];
      if (nestedData is Map<String, dynamic>) {
        final nestedTask = nestedData['task'];
        if (nestedTask is Map<String, dynamic>) {
          return nestedTask;
        }
        if (nestedTask is Map) {
          return nestedTask.map(
            (key, value) => MapEntry(key.toString(), value),
          );
        }
      }
      if (nestedData is Map) {
        return _extractClientIssueTaskSource(
          nestedData.map((key, value) => MapEntry(key.toString(), value)),
        );
      }

      if (data.containsKey('id') && data.containsKey('title')) {
        return data;
      }
    }

    if (data is Map) {
      return _extractClientIssueTaskSource(
        data.map((key, value) => MapEntry(key.toString(), value)),
      );
    }

    return data;
  }

  dynamic _extractProjectDetailSource(dynamic data) {
    if (data is Map<String, dynamic>) {
      for (final key in ['data', 'item', 'result']) {
        final candidate = data[key];
        if (candidate is Map<String, dynamic>) {
          return candidate;
        }
      }
    }

    if (data is Map) {
      return _extractProjectDetailSource(
        data.map((key, value) => MapEntry(key.toString(), value)),
      );
    }

    return data;
  }

  Future<ClientDetailModel?> _tryClientDetailFromList(String id) async {
    final response = await get(ApiConstants.clients);
    final source = _extractListSource(response.data);
    if (source is! List) return null;

    for (final entry in source) {
      final normalized = _normalizeMap(entry);
      final entryId = normalized['id']?.toString();
      if (entryId == id) {
        return ClientDetailModel.fromJson(normalized);
      }
    }

    return null;
  }

  Future<VendorModel?> _tryVendorDetailFromList(String id) async {
    final response = await get(ApiConstants.vendors);
    final source = _extractListSource(response.data);
    if (source is! List) return null;

    for (final entry in source) {
      final normalized = _normalizeMap(entry);
      final entryId = normalized['id']?.toString();
      if (entryId == id) {
        return VendorModel.fromJson(normalized);
      }
    }

    return null;
  }

  Future<Map<String, dynamic>> _resolveLeadQueryParameters({
    String? userId,
    String? roleId,
  }) async {
    UserModel? user = await getStoredUser();
    user ??= await _tryGetCurrentUser();

    final resolvedUserId = (userId ?? user?.id ?? '').trim();
    final resolvedRoleId = (roleId ?? _extractRoleId(user)).trim();

    if (resolvedUserId.isEmpty) {
      throw Exception('Unable to resolve the current user for the leads API.');
    }

    final query = <String, dynamic>{'user_id': resolvedUserId};

    if (resolvedRoleId.isNotEmpty) {
      query['role_id'] = resolvedRoleId;
    }

    return query;
  }

  Future<Map<String, dynamic>> _resolveClientIssueQueryParameters({
    String? userId,
    String? roleId,
  }) async {
    UserModel? user = await getStoredUser();
    user ??= await _tryGetCurrentUser();

    final resolvedUserId = (userId ?? user?.id ?? '').trim();
    final resolvedRoleId = (roleId ?? _extractRoleId(user)).trim();

    // Keep request backwards-compatible if session user is not available.
    if (resolvedUserId.isEmpty) {
      return <String, dynamic>{};
    }

    final query = <String, dynamic>{'user_id': resolvedUserId};
    if (resolvedRoleId.isNotEmpty) {
      query['role_id'] = resolvedRoleId;
    }

    return query;
  }

  String _extractRoleId(UserModel? user) {
    if (user == null) {
      return '';
    }

    final directRoleId = user.roleId?.trim() ?? '';
    if (directRoleId.isNotEmpty) {
      return directRoleId;
    }

    final role = user.role?.trim() ?? '';
    if (_looksNumeric(role)) {
      return role;
    }

    return '';
  }

  bool _looksNumeric(String value) {
    if (value.isEmpty) {
      return false;
    }
    return num.tryParse(value) != null;
  }

  Future<UserModel?> _tryGetCurrentUser() async {
    try {
      return await getCurrentUser();
    } catch (_) {
      return null;
    }
  }

  String _formatApiDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  String _formatApiTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Map<String, dynamic> _buildProjectMilestonePayload({
    required String title,
    String? description,
    String? status,
    String? dueDate,
  }) {
    final normalizedTitle = title.trim();
    final normalizedDescription = (description ?? '').trim();
    final normalizedStatus = _normalizeMilestoneStatus(status);
    final normalizedDueDate = _normalizeDateForApi(dueDate);

    // Keep payload keys aligned with backend contract for both create and update.
    return <String, dynamic>{
      'title': normalizedTitle,
      'description': normalizedDescription,
      'status': normalizedStatus,
      'due_date': normalizedDueDate,
    };
  }

  Map<String, dynamic> _buildProjectIssuePayload({
    required String issueDescription,
    required String priority,
    required String status,
  }) {
    return <String, dynamic>{
      'issue_description': issueDescription.trim(),
      'priority': _normalizeProjectIssuePriority(priority),
      'status': _normalizeProjectIssueStatus(status),
    };
  }

  String _normalizeDateForApi(String? rawDate) {
    final value = (rawDate ?? '').trim();
    if (value.isEmpty) {
      return '';
    }

    final ddMmYyyyMatch = RegExp(
      r'^(\d{2})-(\d{2})-(\d{4})$',
    ).firstMatch(value);
    if (ddMmYyyyMatch != null) {
      return '${ddMmYyyyMatch.group(3)}-${ddMmYyyyMatch.group(2)}-${ddMmYyyyMatch.group(1)}';
    }

    return value;
  }

  String _normalizeMilestoneStatus(String? rawStatus) {
    final value = (rawStatus ?? '').trim().toLowerCase();
    if (value.isEmpty) {
      return 'pending';
    }

    switch (value) {
      case 'in progress':
      case 'in_progress':
        return 'in_progress';
      case 'at risk':
      case 'at_risk':
        return 'at_risk';
      case 'completed':
      case 'complete':
        return 'completed';
      case 'planned':
        return 'planned';
      case 'pending':
        return 'pending';
      default:
        return value.replaceAll(' ', '_');
    }
  }

  String _normalizeProjectIssueStatus(String? status) {
    final value = (status ?? '').trim().toLowerCase();
    if (value.isEmpty) {
      return 'open';
    }

    switch (value) {
      case 'in progress':
      case 'in_progress':
        return 'in_progress';
      case 'resolved':
      case 'closed':
      case 'open':
        return value;
      default:
        return value.replaceAll(' ', '_');
    }
  }

  String _normalizeProjectIssuePriority(String? priority) {
    final value = (priority ?? '').trim().toLowerCase();
    if (value.isEmpty) {
      return 'medium';
    }

    switch (value) {
      case 'low':
      case 'medium':
      case 'high':
        return value;
      default:
        return value.replaceAll(' ', '_');
    }
  }

  Map<String, dynamic> _buildTodoPayload({
    required String title,
    String? description,
    required DateTime taskDate,
    TimeOfDay? taskTime,
    required int repeatInterval,
    required String repeatUnit,
    List<String> repeatDays = const [],
    TimeOfDay? reminderTime,
    bool reminderEmail = false,
    bool reminderWhatsapp = false,
    required DateTime startsOn,
    required String endsType,
    DateTime? endsOn,
    int? endsAfter,
  }) {
    final normalizedEndsType = endsType.trim().toLowerCase();
    final payload = <String, dynamic>{
      'title': title.trim(),
      'task_date': _formatApiDate(taskDate),
      'repeat_interval': repeatInterval,
      'repeat_unit': repeatUnit.trim().toLowerCase(),
      'repeat_days': repeatDays
          .map((day) => day.trim().toLowerCase())
          .where((day) => day.isNotEmpty)
          .toList(growable: false),
      'reminder_email': reminderEmail ? 1 : 0,
      'reminder_whatsapp': reminderWhatsapp ? 1 : 0,
      'starts_on': _formatApiDate(startsOn),
      'ends_type': normalizedEndsType,
    };

    final normalizedDescription = description?.trim() ?? '';
    if (normalizedDescription.isNotEmpty) {
      payload['description'] = normalizedDescription;
    }

    if (taskTime != null) {
      payload['task_time'] = _formatApiTime(taskTime);
    }

    if (reminderTime != null) {
      payload['reminder_time'] = _formatApiTime(reminderTime);
    }

    if (endsOn != null) {
      payload['ends_on'] = _formatApiDate(endsOn);
    }

    if (normalizedEndsType == 'after' && endsAfter != null && endsAfter > 0) {
      payload['ends_after'] = endsAfter;
      payload['ends_after_occurrences'] = endsAfter;
    }

    return payload;
  }

  Future<FormData> _buildTodoFormData({
    required Map<String, dynamic> payload,
    required List<String> attachmentPaths,
  }) async {
    final formData = FormData();

    payload.forEach((key, value) {
      if (value == null) {
        return;
      }

      if (value is Iterable) {
        for (final item in value) {
          if (item != null) {
            formData.fields.add(MapEntry('$key[]', item.toString()));
          }
        }
        return;
      }

      formData.fields.add(MapEntry(key, value.toString()));
    });

    for (final path in attachmentPaths) {
      final fileName = path.split(RegExp(r'[\\/]')).last;
      formData.files.add(
        MapEntry(
          'attachments[]',
          await MultipartFile.fromFile(path, filename: fileName),
        ),
      );
    }

    return formData;
  }

  void _debugLogFormData({required String path, required FormData data}) {
    if (!kDebugMode) return;

    final fields = data.fields
        .map((entry) => '${entry.key}=${entry.value}')
        .join(', ');
    final files = data.files
        .map((entry) => '${entry.key}=${entry.value.filename}')
        .join(', ');

    debugPrint('*** Multipart Debug ***');
    debugPrint('path: $path');
    debugPrint(
      'fields: ${fields.isEmpty ? '(none)' : _truncateForLogText(fields)}',
    );
    debugPrint(
      'files: ${files.isEmpty ? '(none)' : _truncateForLogText(files)}',
    );
  }

  Map<String, dynamic> _buildTaskListPayload({
    required String title,
    String? description,
    required List<Map<String, dynamic>> tasks,
  }) {
    final normalizedTasks = tasks
        .map(
          (task) => <String, dynamic>{
            'title': (task['title'] ?? '').toString().trim(),
            'completed': task['completed'] == true,
          },
        )
        .where((task) => (task['title'] as String).isNotEmpty)
        .toList();

    if (normalizedTasks.isEmpty) {
      throw Exception('At least one task title is required.');
    }

    final payload = <String, dynamic>{
      'task_title': title.trim(),
      'title': title.trim(),
      'tasks': normalizedTasks,
    };

    final normalizedDescription = description?.trim() ?? '';
    if (normalizedDescription.isNotEmpty) {
      payload['description'] = normalizedDescription;
    }

    return payload;
  }

  Map<String, dynamic> _buildCreateTaskPayload({
    required String title,
    String? description,
    String? status,
    String? priority,
    String? projectId,
    DateTime? startDate,
    DateTime? deadline,
    List<String> assigneeIds = const [],
    List<String> followerIds = const [],
    List<String> tags = const [],
  }) {
    final normalizedTitle = title.trim();
    final normalizedDescription = description?.trim() ?? '';
    final normalizedStatus = _normalizeTaskStatus(status);
    final normalizedPriority = _normalizeTaskPriority(priority);
    final normalizedProjectId = projectId?.trim() ?? '';
    final normalizedAssigneeIds = _normalizeTaskRelationIds(assigneeIds);
    final normalizedFollowerIds = _normalizeTaskRelationIds(followerIds);
    final normalizedTags = tags
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toList();

    final payload = <String, dynamic>{
      'task_title': normalizedTitle,
      'project_related': normalizedProjectId,
      'priority': normalizedPriority,
      'status': normalizedStatus,
      'assignees': normalizedAssigneeIds,
      'followers': normalizedFollowerIds,
      'tags': normalizedTags,
      'task_description': normalizedDescription,
    };

    if (startDate != null) {
      payload['start_date'] = _formatApiDate(startDate);
    }

    if (deadline != null) {
      payload['due_date'] = _formatApiDate(deadline);
    }

    return payload;
  }

  Map<String, dynamic> _buildUpdateTaskPayload({
    required String title,
    String? description,
    String? status,
    String? priority,
    String? projectId,
    DateTime? startDate,
    DateTime? deadline,
    List<String> assigneeIds = const [],
    List<String> followerIds = const [],
    List<String> tags = const [],
  }) {
    return _buildCreateTaskPayload(
      title: title,
      description: description,
      status: status,
      priority: priority,
      projectId: projectId,
      startDate: startDate,
      deadline: deadline,
      assigneeIds: assigneeIds,
      followerIds: followerIds,
      tags: tags,
    );
  }

  Future<FormData> _buildTaskFormData({
    required Map<String, dynamic> payload,
    required List<String> attachmentPaths,
  }) async {
    final formData = FormData();

    payload.forEach((key, value) {
      if (value == null) {
        return;
      }

      if (value is Iterable) {
        for (final item in value) {
          if (item != null) {
            formData.fields.add(MapEntry('$key[]', item.toString()));
          }
        }
        return;
      }

      formData.fields.add(MapEntry(key, value.toString()));
    });

    for (final path in attachmentPaths) {
      final normalizedPath = path.trim();
      if (normalizedPath.isEmpty) {
        continue;
      }
      final fileName = normalizedPath.split(RegExp(r'[\\/]')).last;
      formData.files.add(
        MapEntry(
          'attach_files[]',
          await MultipartFile.fromFile(normalizedPath, filename: fileName),
        ),
      );
    }

    return formData;
  }

  String _normalizeTaskStatus(String? status) {
    final normalizedStatus = status?.trim() ?? '';
    if (normalizedStatus.isEmpty) return '';

    switch (normalizedStatus.toLowerCase()) {
      case 'not started':
      case 'not_started':
        return 'not_started';
      case 'in progress':
      case 'in_progress':
        return 'in_progress';
      case 'on hold':
      case 'on_hold':
        return 'on_hold';
      case 'completed':
        return 'completed';
      case 'cancelled':
      case 'canceled':
        return 'cancelled';
      default:
        return normalizedStatus.toLowerCase().replaceAll(' ', '_');
    }
  }

  String _normalizeClientIssueTaskStatus(String? status) {
    final value = (status ?? '').trim().toLowerCase();
    if (value.isEmpty) {
      return 'todo';
    }

    switch (value) {
      case 'to do':
      case 'todo':
        return 'todo';
      case 'in progress':
      case 'in_progress':
        return 'in_progress';
      case 'review':
        return 'review';
      case 'done':
      case 'completed':
      case 'complete':
        return 'done';
      default:
        return value.replaceAll(' ', '_');
    }
  }

  String _normalizeClientIssueTaskPriority(String? priority) {
    final value = (priority ?? '').trim().toLowerCase();
    if (value.isEmpty) {
      return 'medium';
    }

    switch (value) {
      case 'low':
      case 'medium':
      case 'high':
      case 'critical':
        return value;
      default:
        return value.replaceAll(' ', '_');
    }
  }

  String _normalizeTaskPriority(String? priority) {
    final normalizedPriority = priority?.trim() ?? '';
    if (normalizedPriority.isEmpty) return '';

    switch (normalizedPriority.toLowerCase()) {
      case 'low':
      case 'medium':
      case 'high':
      case 'urgent':
        return normalizedPriority.toLowerCase();
      default:
        return normalizedPriority.toLowerCase().replaceAll(' ', '_');
    }
  }

  List<dynamic> _normalizeTaskRelationIds(List<String> ids) {
    return ids
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .map<dynamic>((id) => int.tryParse(id) ?? id)
        .toList();
  }
}
