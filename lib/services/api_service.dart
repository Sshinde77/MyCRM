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
import '../models/update_client_request_model.dart';
import '../models/staff_member_model.dart';
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

  /// Multipart POST helper for endpoints that accept form-data payloads.
  Future<Response> postForm(String path, {required FormData data}) async {
    await _restoreAuthToken();
    return await _dio.post(
      path,
      data: data,
      options: Options(
        headers: const {
          'Content-Type': 'multipart/form-data',
        },
      ),
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

  /// Loads the staff list for the authenticated user.
  Future<List<StaffMemberModel>> getStaffList() async {
    final response = await get(ApiConstants.liststaff);
    final records = _normalizeList(response.data);
    return records.map(StaffMemberModel.fromJson).toList();
  }

  /// Loads the client list for the authenticated user.
  Future<List<ClientModel>> getClientsList() async {
    final response = await get(ApiConstants.clients);
    final records = _normalizeList(response.data);
    return records.map(ClientModel.fromJson).toList();
  }

  /// Loads the lead list for the authenticated user.
  Future<List<LeadModel>> getLeadsList({
    String? userId,
    String? roleId,
  }) async {
    final query = await _resolveLeadQueryParameters(
      userId: userId,
      roleId: roleId,
    );
    final response = await get(
      ApiConstants.leads,
      queryParameters: query,
    );
    final records = _normalizeList(response.data);
    return records.map(LeadModel.fromJson).toList();
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
  }) async {
    final payload = <String, dynamic>{
      'title': title.trim(),
      'task_date': _formatApiDate(taskDate),
      'repeat_interval': repeatInterval,
      'repeat_unit': repeatUnit.trim().toLowerCase(),
      'starts_on': _formatApiDate(startsOn),
      'ends_type': endsType.trim().toLowerCase(),
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

    if (endsAfter != null && endsAfter > 0) {
      payload['ends_after'] = endsAfter;
    }

    await post(ApiConstants.createtodo, data: payload);
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
  }

  /// Updates a single staff member by id.
  Future<void> editStaff({
    required String id,
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String role,
    required String status,
    required String team,
    required List<String> departments,
    String? password,
    bool sendWelcomeEmail = true,
  }) async {
    final path = ApiConstants.editstaff.replaceFirst('{id}', id);
    final payload = <String, dynamic>{
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'phone': phone,
      'role': role,
      'status': status,
      'team': team,
      'departments': departments,
      'send_welcome_email': sendWelcomeEmail,
    };

    if (password != null && password.trim().isNotEmpty) {
      payload['password'] = password.trim();
    }

    await put(path, data: payload);
  }

  /// Creates a new staff member.
  Future<void> createStaff({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String role,
    required String status,
    required String team,
    required List<String> departments,
    required String password,
    String? profileImagePath,
  }) async {
    final payload = <String, dynamic>{
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phone': phone,
      'role': role,
      'status': status,
      'team': team,
      'departments[]': departments,
      'password': password,
    };

    if (profileImagePath != null && profileImagePath.isNotEmpty) {
      final fileName = profileImagePath.split(RegExp(r'[\\/]')).last;
      payload['profileImage'] = await MultipartFile.fromFile(
        profileImagePath,
        filename: fileName,
      );
    }

    await postForm(
      ApiConstants.createstaff,
      data: FormData.fromMap(payload),
    );
  }

  /// Creates a new client.
  Future<void> createClient(CreateClientRequestModel request) async {
    await post(ApiConstants.clients, data: request.toJson());
  }

  /// Updates an existing client.
  Future<void> updateClient({
    required String id,
    required UpdateClientRequestModel request,
  }) async {
    final path = ApiConstants.updateClient.replaceFirst('{id}', id);
    await put(path, data: request.toJson());
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
        'staff',
        'clients',
        'customers',
        'results',
        'rows',
      ]) {
        final candidate = data[key];
        if (candidate is List) {
          return candidate;
        }

        if (candidate is Map<String, dynamic>) {
          for (final nestedKey in [
            'data',
            'items',
            'staff',
            'clients',
            'customers',
            'results',
            'rows',
          ]) {
            final nestedCandidate = candidate[nestedKey];
            if (nestedCandidate is List) {
              return nestedCandidate;
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

  dynamic _extractDetailSource(dynamic data) {
    if (data is Map<String, dynamic>) {
      for (final key in [
        'data',
        'staff',
        'client',
        'customer',
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

    final query = <String, dynamic>{
      'user_id': resolvedUserId,
    };

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
}
