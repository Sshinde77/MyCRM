import 'package:flutter/foundation.dart';

import '../models/project_issue_model.dart';
import '../services/api_service.dart';

class ProjectIssueProvider extends ChangeNotifier {
  ProjectIssueProvider({required this.projectId, ApiService? apiService})
    : _apiService = apiService ?? ApiService.instance;

  final String projectId;
  final ApiService _apiService;

  List<ProjectIssueModel> _issues = const [];
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  final Set<String> _deletingIssueIds = <String>{};

  List<ProjectIssueModel> get issues => _issues;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  bool isDeletingIssue(String id) => _deletingIssueIds.contains(id.trim());

  Future<void> loadIssues({bool forceRefresh = false}) async {
    if (_isLoading) return;
    if (!forceRefresh && _issues.isNotEmpty) return;

    final normalizedProjectId = projectId.trim();
    if (normalizedProjectId.isEmpty) {
      _errorMessage = 'Project id is missing.';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _issues = await _apiService.getProjectIssues(normalizedProjectId);
    } catch (error) {
      _errorMessage = _toMessage(error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createIssue({
    required String issueDescription,
    required String priority,
    required String status,
  }) async {
    final normalizedProjectId = projectId.trim();
    if (normalizedProjectId.isEmpty) {
      throw Exception('Project id is missing.');
    }

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiService.createProjectIssue(
        projectId: normalizedProjectId,
        issueDescription: issueDescription,
        priority: priority,
        status: status,
      );
      _issues = await _apiService.getProjectIssues(normalizedProjectId);
    } catch (error) {
      _errorMessage = _toMessage(error);
      rethrow;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<void> updateIssue({
    required String issueId,
    required String issueDescription,
    required String priority,
    required String status,
  }) async {
    final normalizedProjectId = projectId.trim();
    final normalizedIssueId = issueId.trim();
    if (normalizedProjectId.isEmpty || normalizedIssueId.isEmpty) {
      throw Exception('Project id or issue id is missing.');
    }

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiService.updateProjectIssue(
        projectId: normalizedProjectId,
        issueId: normalizedIssueId,
        issueDescription: issueDescription,
        priority: priority,
        status: status,
      );
      _issues = await _apiService.getProjectIssues(normalizedProjectId);
    } catch (error) {
      _errorMessage = _toMessage(error);
      rethrow;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<void> deleteIssue(String issueId) async {
    final normalizedProjectId = projectId.trim();
    final normalizedIssueId = issueId.trim();
    if (normalizedProjectId.isEmpty || normalizedIssueId.isEmpty) {
      return;
    }

    if (_deletingIssueIds.contains(normalizedIssueId)) {
      return;
    }

    _deletingIssueIds.add(normalizedIssueId);
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiService.deleteProjectIssue(
        projectId: normalizedProjectId,
        issueId: normalizedIssueId,
      );
      _issues = _issues
          .where((entry) => entry.id.trim() != normalizedIssueId)
          .toList(growable: false);
    } catch (error) {
      _errorMessage = _toMessage(error);
      rethrow;
    } finally {
      _deletingIssueIds.remove(normalizedIssueId);
      notifyListeners();
    }
  }

  String _toMessage(Object error) {
    final message = error.toString().trim();
    if (message.isEmpty) {
      return 'Unable to process issue request right now.';
    }

    if (message.startsWith('Exception: ')) {
      return message.substring('Exception: '.length);
    }

    return message;
  }
}
