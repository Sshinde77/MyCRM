import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

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
import '../models/client_issue_model.dart';
import '../models/client_issue_task_model.dart';
import '../models/company_information_model.dart';
import '../models/department_setting_model.dart';
import '../models/email_settings_model.dart';
import '../models/renewal_settings_model.dart';
import '../models/renewal_model.dart';
import '../models/team_setting_model.dart';
import '../models/vendor_model.dart';
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
  });

  final List<Map<String, dynamic>> items;
  final int currentPage;
  final int lastPage;
  final int total;
  final int perPage;
  final bool hasNextPage;
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

class ClientRenewalFormOptionsResult {
  const ClientRenewalFormOptionsResult({
    required this.clients,
    required this.vendors,
  });

  final List<ClientModel> clients;
  final List<VendorModel> vendors;
}

class ApiService {
  ApiService._internal() {
    if (kDebugMode) {
      _dio.interceptors.add(_buildDebugLoggingInterceptor());
    }

    _dio.interceptors.add(
      InterceptorsWrapper(
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

          final token = await _storage.read(
            SecureStorageService.accessTokenKey,
          );
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
    return normalized.contains('/login') ||
        normalized.contains('/logout') ||
        normalized.contains('/refresh');
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
        options: Options(headers: const {'Authorization': null}),
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
    await _restoreAuthToken();
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
    await _restoreAuthToken();
    return await _dio.post(path, data: data);
  }

  /// Basic PUT helper for endpoints that update an existing record.
  Future<Response> put(String path, {dynamic data}) async {
    await _restoreAuthToken();
    return await _dio.put(path, data: data);
  }

  /// Basic DELETE helper for endpoints that remove a record.
  Future<Response> delete(String path, {dynamic data}) async {
    await _restoreAuthToken();
    return await _dio.delete(path, data: data);
  }

  /// Basic PATCH helper for endpoints that partially update a record.
  Future<Response> patch(String path, {dynamic data}) async {
    await _restoreAuthToken();
    return await _dio.patch(path, data: data);
  }

  /// Multipart POST helper for endpoints that accept form-data payloads.
  Future<Response> postForm(String path, {required FormData data}) async {
    await _restoreAuthToken();
    _debugLogFormData(path: path, data: data);
    return await _dio.post(
      path,
      data: data,
      options: Options(contentType: Headers.multipartFormDataContentType),
    );
  }

  /// Multipart PUT helper for endpoints that accept form-data payloads.
  Future<Response> putForm(String path, {required FormData data}) async {
    await _restoreAuthToken();
    return await _dio.put(
      path,
      data: data,
      options: Options(contentType: Headers.multipartFormDataContentType),
    );
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

    final response = await post(
      ApiConstants.testFcm,
      data: <String, dynamic>{
        'token': normalizedToken,
        'user_id': normalizedUserId,
        'event': event,
        'device': deviceInfo,
        'title': 'FCM Token Sync',
        'body': 'Device token sync event: $event',
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

    final response = await post(
      ApiConstants.testFcm,
      data: <String, dynamic>{
        'token': normalizedToken,
        'user_id': normalizedUserId,
        'event': 'logout',
        'device': deviceInfo,
        'title': 'FCM Token Unlink',
        'body': 'Device token unlink on logout',
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
  }) async {
    final normalizedPage = page < 1 ? 1 : page;
    final normalizedSearch = (search ?? '').trim();
    final query = <String, dynamic>{'page': normalizedPage};
    if (normalizedSearch.isNotEmpty) {
      query['search'] = normalizedSearch;
    }
    final response = await get(
      ApiConstants.liststaff,
      queryParameters: query,
    );
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
    final perPage = _readInt(pagePayload?['per_page']) ?? items.length;
    final hasNextPage =
        pagePayload?['next_page_url'] != null || currentPage < lastPage;

    return StaffListPageResult(
      items: items,
      currentPage: currentPage,
      lastPage: lastPage,
      total: total,
      perPage: perPage,
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
  }) async {
    final normalizedPage = page < 1 ? 1 : page;
    final normalizedSearch = (search ?? '').trim();
    final query = <String, dynamic>{'page': normalizedPage};
    if (normalizedSearch.isNotEmpty) {
      query['search'] = normalizedSearch;
    }
    final response = await get(
      ApiConstants.clients,
      queryParameters: query,
    );
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
    final perPage = _readInt(pagePayload?['per_page']) ?? items.length;
    final hasNextPage =
        pagePayload?['next_page_url'] != null || currentPage < lastPage;

    return ClientListPageResult(
      items: items,
      currentPage: currentPage,
      lastPage: lastPage,
      total: total,
      perPage: perPage,
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

    final response = await get(
      ApiConstants.vendors,
      queryParameters: query,
    );

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
  }) async {
    final normalizedPage = page < 1 ? 1 : page;
    final normalizedSearch = (search ?? '').trim();
    final query = <String, dynamic>{'page': normalizedPage};
    if (normalizedSearch.isNotEmpty) {
      query['search'] = normalizedSearch;
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
  }) async {
    final normalizedPage = page < 1 ? 1 : page;
    final normalizedSearch = (search ?? '').trim();
    final query = <String, dynamic>{'page': normalizedPage};
    if (normalizedSearch.isNotEmpty) {
      query['search'] = normalizedSearch;
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
        pagePayload = leads.map((key, value) => MapEntry(key.toString(), value));
      } else {
        pagePayload = rootData;
      }
    } else if (rootData is Map) {
      pagePayload = rootData.map((key, value) => MapEntry(key.toString(), value));
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
        pagePayload = projects.map((key, value) => MapEntry(key.toString(), value));
      } else {
        pagePayload = rootData;
      }
    } else if (rootData is Map) {
      pagePayload = rootData.map((key, value) => MapEntry(key.toString(), value));
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

  TaskListPageResult _parseTaskPageResponse(dynamic responseData, int fallbackPage) {
    final root = _normalizeMap(responseData);
    Map<String, dynamic>? pagePayload;
    final rootData = root['data'];
    if (rootData is Map<String, dynamic>) {
      final tasks = rootData['tasks'];
      if (tasks is Map<String, dynamic>) {
        pagePayload = tasks;
      } else if (tasks is Map) {
        pagePayload = tasks.map((key, value) => MapEntry(key.toString(), value));
      } else {
        pagePayload = rootData;
      }
    } else if (rootData is Map) {
      pagePayload = rootData.map((key, value) => MapEntry(key.toString(), value));
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

    return TaskListPageResult(
      items: records,
      currentPage: currentPage,
      lastPage: lastPage,
      total: total,
      perPage: perPage,
      hasNextPage: hasNextPage,
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
        pagePayload = nested.map((key, value) => MapEntry(key.toString(), value));
      } else {
        pagePayload = rootData;
      }
    } else if (rootData is Map) {
      pagePayload = rootData.map((key, value) => MapEntry(key.toString(), value));
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
  Future<ClientIssueIndexData> getClientIssuesIndexData() async {
    final query = await _resolveClientIssueQueryParameters();
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
      '{id}',
      normalizedIssueId,
    );

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
    required String title,
    String? description,
    String? status,
    String? priority,
    String? assignedTo,
  }) async {
    final normalizedIssueId = issueId.trim();
    final normalizedTaskId = taskId.trim();
    if (normalizedIssueId.isEmpty || normalizedTaskId.isEmpty) {
      throw Exception('Invalid issue/task id.');
    }

    final normalizedTitle = title.trim();
    if (normalizedTitle.isEmpty) {
      throw Exception('Task title is required.');
    }

    final path = ApiConstants.clientIssueTaskDetail
        .replaceFirst('{issueId}', normalizedIssueId)
        .replaceFirst('{taskId}', normalizedTaskId);

    final payload = <String, dynamic>{
      'title': normalizedTitle,
      'description': (description ?? '').trim(),
      'status': _normalizeClientIssueTaskStatus(status),
      'priority': _normalizeClientIssueTaskPriority(priority),
      'assigned_to': (assignedTo ?? '').trim(),
    };

    final response = await put(path, data: payload);
    final source = _extractClientIssueTaskSource(response.data);
    if (source is Map) {
      return ClientIssueTaskModel.fromJson(_normalizeMap(source));
    }
    throw Exception('Unexpected task update response format.');
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

    return ClientRenewalFormOptionsResult(clients: clients, vendors: vendors);
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
  Future<List<Map<String, dynamic>>> getTasksList() async {
    final response = await get(ApiConstants.tasks);
    return _normalizeList(response.data);
  }

  /// Loads a single paginated tasks page for the authenticated user.
  Future<TaskListPageResult> getTasksListPage({
    int page = 1,
    String? search,
  }) async {
    final normalizedPage = page < 1 ? 1 : page;
    final normalizedSearch = (search ?? '').trim();
    final query = <String, dynamic>{'page': normalizedPage};
    if (normalizedSearch.isNotEmpty) {
      query['search'] = normalizedSearch;
    }
    final response = await get(ApiConstants.tasks, queryParameters: query);
    return _parseTaskPageResponse(response.data, normalizedPage);
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
    final path = ApiConstants.deleteBookACall.replaceFirst('{id}', normalizedId);
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
    final response = await get(ApiConstants.webAppsLeads, queryParameters: query);
    return _parseMapListPageResponse(response.data, normalizedPage);
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
  Future<List<Map<String, dynamic>>> getStaffTasksList(String staffId) async {
    final id = staffId.trim();
    if (id.isEmpty) return const <Map<String, dynamic>>[];

    final path = ApiConstants.stafftasks.replaceFirst('{id}', id);
    final response = await get(path);
    return _normalizeList(response.data);
  }

  /// Loads a single paginated tasks page assigned to a specific staff member.
  Future<TaskListPageResult> getStaffTasksListPage({
    required String staffId,
    int page = 1,
    String? search,
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
      );
    }
    final normalizedPage = page < 1 ? 1 : page;
    final normalizedSearch = (search ?? '').trim();
    final query = <String, dynamic>{'page': normalizedPage};
    if (normalizedSearch.isNotEmpty) {
      query['search'] = normalizedSearch;
    }
    final path = ApiConstants.stafftasks.replaceFirst('{id}', id);
    final response = await get(path, queryParameters: query);
    return _parseTaskPageResponse(response.data, normalizedPage);
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
    final response = await post(ApiConstants.createTask, data: payload);
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
  }) async {
    final path = ApiConstants.updateTask.replaceFirst('{id}', id);
    await put(
      path,
      data: _buildUpdateTaskPayload(
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
      ),
    );
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
    TimeOfDay? reminderTime,
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
      reminderTime: reminderTime,
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
    TimeOfDay? reminderTime,
    required DateTime startsOn,
    required String endsType,
    DateTime? endsOn,
    int? endsAfter,
    List<String> attachmentPaths = const [],
    List<String> existingAttachmentUrls = const [],
  }) async {
    final path = ApiConstants.edittodo.replaceFirst('{id}', id);
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
    final normalizedExistingUrls = existingAttachmentUrls
        .map((url) => url.trim())
        .where((url) => url.isNotEmpty)
        .toList();
    final updatePayload = <String, dynamic>{...payload, '_method': 'PUT'};
    await postForm(
      path,
      data: await _buildTodoFormData(
        payload: updatePayload,
        attachmentPaths: attachmentPaths,
        existingAttachmentUrls: normalizedExistingUrls,
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
    };

    if (role != null && role.trim().isNotEmpty) {
      payload['role'] = role.trim();
    }

    if (profileImagePath != null && profileImagePath.isNotEmpty) {
      final fileName = profileImagePath.split(RegExp(r'[\\/]')).last;
      payload['profile_image'] = await MultipartFile.fromFile(
        profileImagePath,
        filename: fileName,
      );
    }

    if (profileImagePath != null && profileImagePath.isNotEmpty) {
      await postForm(ApiConstants.createstaff, data: FormData.fromMap(payload));
      _invalidateStaffCaches();
      return;
    }

    await post(ApiConstants.createstaff, data: payload);
    _invalidateStaffCaches();
  }

  /// Creates a new client.
  Future<void> createClient(CreateClientRequestModel request) async {
    final payload = request.toPayload();
    final profileImagePath = request.normalizedProfileImagePath;
    if (profileImagePath != null) {
      final fileName = profileImagePath.split(RegExp(r'[\\/]')).last;
      payload['profile_image'] = await MultipartFile.fromFile(
        profileImagePath,
        filename: fileName,
      );
    }

    await postForm(ApiConstants.clients, data: FormData.fromMap(payload));
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
    TimeOfDay? reminderTime,
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
    List<String>? existingAttachmentUrls,
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

    if (existingAttachmentUrls != null) {
      if (existingAttachmentUrls.isEmpty) {
        formData.fields.add(const MapEntry('existing_attachments', ''));
        formData.fields.add(const MapEntry('existing_attachment_urls', ''));
        formData.fields.add(const MapEntry('existing_attachments[]', ''));
        formData.fields.add(const MapEntry('existing_attachment_urls[]', ''));
      } else {
        for (final url in existingAttachmentUrls) {
          formData.fields.add(MapEntry('existing_attachments', url));
          formData.fields.add(MapEntry('existing_attachment_urls', url));
          formData.fields.add(MapEntry('existing_attachments[]', url));
          formData.fields.add(MapEntry('existing_attachment_urls[]', url));
        }
      }
    }

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
