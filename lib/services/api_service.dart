import 'package:dio/dio.dart';
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
import '../models/project_model.dart';
import '../models/project_detail_model.dart';
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

  /// Basic PATCH helper for endpoints that partially update a record.
  Future<Response> patch(String path, {dynamic data}) async {
    await _restoreAuthToken();
    return await _dio.patch(path, data: data);
  }

  /// Multipart POST helper for endpoints that accept form-data payloads.
  Future<Response> postForm(String path, {required FormData data}) async {
    await _restoreAuthToken();
    return await _dio.post(
      path,
      data: data,
      options: Options(headers: const {'Content-Type': 'multipart/form-data'}),
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

  /// Loads the project list for the authenticated user.
  Future<List<ProjectModel>> getProjectsList() async {
    final response = await get(ApiConstants.projects);
    final records = _normalizeList(response.data);
    return records.map(ProjectModel.fromJson).toList();
  }

  /// Loads a single project by id.
  Future<ProjectDetailModel> getProjectDetail(String id) async {
    final path = ApiConstants.projectDetail.replaceFirst('{id}', id);
    final response = await get(path);
    final body = _normalizeMap(response.data);
    final source = _normalizeMap(_extractProjectDetailSource(body));
    return ProjectDetailModel.fromJson(source);
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

  /// Loads a single task record by id.
  Future<Map<String, dynamic>> getTaskDetail(String id) async {
    final path = ApiConstants.taskDetail.replaceFirst('{id}', id);
    final response = await get(path);
    final body = _normalizeMap(response.data);
    final detail = _normalizeMap(_extractDetailSource(body));
    return <String, dynamic>{...body, ...detail};
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
    await put(path, data: payload);
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

    await postForm(ApiConstants.createstaff, data: FormData.fromMap(payload));
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
        'projects',
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
          for (final nestedKey in [
            'data',
            'items',
            'staff',
            'clients',
            'customers',
            'projects',
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
        'project',
        'client',
        'customer',
        'task',
        'todo',
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

    return payload;
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

  Map<String, dynamic> _buildTaskRecordPayload({
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
    final payload = <String, dynamic>{
      'title': normalizedTitle,
      'task_title': normalizedTitle,
    };

    final normalizedDescription = description?.trim() ?? '';
    if (normalizedDescription.isNotEmpty) {
      payload['description'] = normalizedDescription;
    }

    final normalizedStatus = _normalizeTaskStatus(status);
    if (normalizedStatus.isNotEmpty) {
      payload['status'] = normalizedStatus;
    }

    final normalizedPriority = _normalizeTaskPriority(priority);
    if (normalizedPriority.isNotEmpty) {
      payload['priority'] = normalizedPriority;
    }

    final normalizedProjectId = projectId?.trim() ?? '';
    if (normalizedProjectId.isNotEmpty) {
      payload['project_id'] = normalizedProjectId;
    }

    if (startDate != null) {
      payload['start_date'] = _formatApiDate(startDate);
    }

    if (deadline != null) {
      payload['deadline'] = _formatApiDate(deadline);
    }

    final normalizedAssigneeIds = assigneeIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toList();
    if (normalizedAssigneeIds.isNotEmpty) {
      payload['assignees'] = normalizedAssigneeIds;
    }

    final normalizedFollowerIds = followerIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toList();
    if (normalizedFollowerIds.isNotEmpty) {
      payload['followers'] = normalizedFollowerIds;
    }

    final normalizedTags = tags
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toList();
    if (normalizedTags.isNotEmpty) {
      payload['tags'] = normalizedTags;
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
