import 'package:flutter/foundation.dart';

import '../models/lead_model.dart';
import '../services/api_service.dart';

class LeadProvider extends ChangeNotifier {
  LeadProvider({ApiService? apiService})
      : _apiService = apiService ?? ApiService.instance;

  final ApiService _apiService;

  List<LeadModel> _allLeads = const [];
  String _searchQuery = '';
  bool _isLoading = false;
  String? _errorMessage;
  final Set<String> _deletingLeadIds = <String>{};

  List<LeadModel> get leads {
    if (_searchQuery.trim().isEmpty) {
      return _allLeads;
    }
    return _allLeads.where((lead) => lead.matchesQuery(_searchQuery)).toList();
  }

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  int get totalLeads => _allLeads.length;
  bool isDeletingLead(String id) => _deletingLeadIds.contains(id);

  int get newLeadsCount {
    return _allLeads.where((lead) {
      final status = lead.status?.trim().toLowerCase() ?? '';
      if (status.contains('new') ||
          status.contains('initial') ||
          status.contains('fresh')) {
        return true;
      }

      final createdAt = lead.createdAt;
      if (createdAt == null) {
        return false;
      }

      final now = DateTime.now();
      return createdAt.year == now.year &&
          createdAt.month == now.month &&
          createdAt.day == now.day;
    }).length;
  }

  Future<void> loadLeads({bool forceRefresh = false}) async {
    if (_isLoading) {
      return;
    }

    if (!forceRefresh && _allLeads.isNotEmpty) {
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _allLeads = await _apiService.getLeadsList();
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

  Future<void> deleteLead(String id) async {
    final normalizedId = id.trim();
    if (normalizedId.isEmpty || _deletingLeadIds.contains(normalizedId)) {
      return;
    }

    _deletingLeadIds.add(normalizedId);
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiService.deleteLead(normalizedId);
      _allLeads = _allLeads
          .where((lead) => (lead.id?.trim() ?? '') != normalizedId)
          .toList(growable: false);
    } catch (error) {
      _errorMessage = _toMessage(error);
      rethrow;
    } finally {
      _deletingLeadIds.remove(normalizedId);
      notifyListeners();
    }
  }

  String _toMessage(Object error) {
    final message = error.toString().trim();
    if (message.isEmpty) {
      return 'Unable to load leads right now.';
    }

    if (message.startsWith('Exception: ')) {
      return message.substring('Exception: '.length);
    }

    return message;
  }
}
