import 'package:flutter/foundation.dart';

import '../models/lead_model.dart';
import '../services/api_service.dart';

class LeadDetailProvider extends ChangeNotifier {
  LeadDetailProvider({
    required this.leadId,
    ApiService? apiService,
  }) : _apiService = apiService ?? ApiService.instance;

  final String leadId;
  final ApiService _apiService;

  LeadModel? _lead;
  bool _isLoading = false;
  String? _errorMessage;

  LeadModel? get lead => _lead;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadLead({bool forceRefresh = false}) async {
    if (leadId.trim().isEmpty) {
      _errorMessage = 'Lead id is missing.';
      notifyListeners();
      return;
    }

    if (_isLoading) {
      return;
    }

    if (!forceRefresh && _lead != null) {
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _lead = await _apiService.getLeadDetail(leadId);
    } catch (error) {
      _errorMessage = _toMessage(error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String _toMessage(Object error) {
    final message = error.toString().trim();
    if (message.isEmpty) {
      return 'Unable to load lead details right now.';
    }

    if (message.startsWith('Exception: ')) {
      return message.substring('Exception: '.length);
    }

    return message;
  }
}
