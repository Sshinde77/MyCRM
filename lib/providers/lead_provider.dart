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
  int _currentPage = 1;
  int _lastPage = 1;
  int _totalLeads = 0;
  final Set<String> _deletingLeadIds = <String>{};

  List<LeadModel> get leads => _allLeads;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  int get totalLeads => _totalLeads;
  int get currentPage => _currentPage;
  int get lastPage => _lastPage;
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

  Future<void> loadLeads({
    bool forceRefresh = false,
    int page = 1,
    String? search,
  }) async {
    if (_isLoading) {
      return;
    }

    final normalizedPage = page < 1 ? 1 : page;
    final normalizedSearch = (search ?? _searchQuery).trim();

    if (!forceRefresh &&
        _allLeads.isNotEmpty &&
        _currentPage == normalizedPage &&
        _searchQuery == normalizedSearch) {
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _apiService.getLeadsListPage(
        page: normalizedPage,
        search: normalizedSearch,
      );
      _allLeads = result.items;
      _currentPage = result.currentPage < 1 ? normalizedPage : result.currentPage;
      _lastPage = result.lastPage < 1 ? 1 : result.lastPage;
      _totalLeads = result.total >= 0 ? result.total : _allLeads.length;
      _searchQuery = normalizedSearch;
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
          .where((lead) => (lead.id.trim()) != normalizedId)
          .toList(growable: false);
      if (_totalLeads > 0) {
        _totalLeads -= 1;
      }
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
