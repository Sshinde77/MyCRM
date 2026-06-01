import 'package:flutter/foundation.dart';

import '../models/role_model.dart';
import '../services/api_service.dart';

class RoleProvider extends ChangeNotifier {
  RoleProvider({ApiService? apiService})
    : _apiService = apiService ?? ApiService.instance;

  final ApiService _apiService;

  List<RoleModel> _allRoles = const <RoleModel>[];
  int _totalRolesCount = 0;
  int _activeRolesCount = 0;
  int _inactiveRolesCount = 0;
  int _permissionsCount = 0;
  String _searchQuery = '';
  bool _isLoading = false;
  String? _errorMessage;

  List<RoleModel> get roles {
    if (_searchQuery.trim().isEmpty) {
      return _allRoles;
    }
    return _allRoles.where((role) => role.matchesQuery(_searchQuery)).toList();
  }

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  int get totalRoles =>
      _totalRolesCount > 0 ? _totalRolesCount : _allRoles.length;
  int get activeRoles => _activeRolesCount > 0
      ? _activeRolesCount
      : _allRoles.where((role) => role.isActive).length;
  int get inactiveRoles => _inactiveRolesCount > 0
      ? _inactiveRolesCount
      : (totalRoles - activeRoles).clamp(0, totalRoles);
  int get permissionsCount => _permissionsCount > 0
      ? _permissionsCount
      : _allRoles.fold(0, (total, role) => total + role.permissionsCount);

  Future<void> loadRoles({bool forceRefresh = false}) async {
    if (_isLoading) {
      return;
    }

    if (!forceRefresh && _allRoles.isNotEmpty) {
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _apiService.getRolesSummary();
      _allRoles = result.items;
      _totalRolesCount = result.totalRolesCount;
      _activeRolesCount = result.activeRolesCount;
      _inactiveRolesCount = result.inactiveRolesCount;
      _permissionsCount = result.permissionsCount;
    } catch (error) {
      _errorMessage = _toMessage(error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void updateSearchQuery(String value) {
    if (_searchQuery == value) {
      return;
    }

    _searchQuery = value;
    notifyListeners();
  }

  String _toMessage(Object error) {
    final message = error.toString().trim();
    if (message.startsWith('Exception: ')) {
      return message.substring('Exception: '.length);
    }
    return message.isEmpty ? 'Unable to load roles right now.' : message;
  }
}
