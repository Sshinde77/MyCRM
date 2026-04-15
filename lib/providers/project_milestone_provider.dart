import 'package:flutter/foundation.dart';

import '../models/project_milestone_model.dart';
import '../services/api_service.dart';

class ProjectMilestoneProvider extends ChangeNotifier {
  ProjectMilestoneProvider({required this.projectId, ApiService? apiService})
    : _apiService = apiService ?? ApiService.instance;

  final String projectId;
  final ApiService _apiService;

  List<ProjectMilestoneModel> _milestones = const [];
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  final Set<String> _deletingMilestoneIds = <String>{};

  List<ProjectMilestoneModel> get milestones => _milestones;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  bool isDeletingMilestone(String id) =>
      _deletingMilestoneIds.contains(id.trim());

  Future<void> loadMilestones({bool forceRefresh = false}) async {
    if (_isLoading) return;
    if (!forceRefresh && _milestones.isNotEmpty) return;

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
      _milestones = await _apiService.getProjectMilestones(normalizedProjectId);
    } catch (error) {
      _errorMessage = _toMessage(error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createMilestone({
    required String title,
    required String description,
    required String status,
    required String dueDate,
  }) async {
    final normalizedProjectId = projectId.trim();
    if (normalizedProjectId.isEmpty) {
      throw Exception('Project id is missing.');
    }

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiService.createProjectMilestone(
        projectId: normalizedProjectId,
        title: title,
        description: description,
        status: status,
        dueDate: dueDate,
      );
      _milestones = await _apiService.getProjectMilestones(normalizedProjectId);
    } catch (error) {
      _errorMessage = _toMessage(error);
      rethrow;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<void> updateMilestone({
    required String milestoneId,
    required String title,
    required String description,
    required String status,
    required String dueDate,
  }) async {
    final normalizedProjectId = projectId.trim();
    final normalizedMilestoneId = milestoneId.trim();
    if (normalizedProjectId.isEmpty || normalizedMilestoneId.isEmpty) {
      throw Exception('Project id or milestone id is missing.');
    }

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiService.updateProjectMilestone(
        projectId: normalizedProjectId,
        milestoneId: normalizedMilestoneId,
        title: title,
        description: description,
        status: status,
        dueDate: dueDate,
      );
      _milestones = await _apiService.getProjectMilestones(normalizedProjectId);
    } catch (error) {
      _errorMessage = _toMessage(error);
      rethrow;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<void> deleteMilestone(String milestoneId) async {
    final normalizedProjectId = projectId.trim();
    final normalizedMilestoneId = milestoneId.trim();
    if (normalizedProjectId.isEmpty || normalizedMilestoneId.isEmpty) {
      return;
    }

    if (_deletingMilestoneIds.contains(normalizedMilestoneId)) {
      return;
    }

    _deletingMilestoneIds.add(normalizedMilestoneId);
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiService.deleteProjectMilestone(
        projectId: normalizedProjectId,
        milestoneId: normalizedMilestoneId,
      );
      _milestones = _milestones
          .where((m) => m.id.trim() != normalizedMilestoneId)
          .toList(growable: false);
    } catch (error) {
      _errorMessage = _toMessage(error);
      rethrow;
    } finally {
      _deletingMilestoneIds.remove(normalizedMilestoneId);
      notifyListeners();
    }
  }

  String _toMessage(Object error) {
    final message = error.toString().trim();
    if (message.isEmpty) {
      return 'Unable to process milestone request right now.';
    }

    if (message.startsWith('Exception: ')) {
      return message.substring('Exception: '.length);
    }

    return message;
  }
}
