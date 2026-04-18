import 'package:flutter/foundation.dart';

import '../models/renewal_model.dart';
import '../services/api_service.dart';

enum RenewalType { client, vendor }

class RenewalListProvider extends ChangeNotifier {
  RenewalListProvider({required this.type, ApiService? apiService})
    : _apiService = apiService ?? ApiService.instance;

  final RenewalType type;
  final ApiService _apiService;

  List<RenewalModel> _renewals = const <RenewalModel>[];
  bool _isLoading = false;
  String? _errorMessage;

  List<RenewalModel> get renewals => _renewals;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadRenewals({bool forceRefresh = false}) async {
    if (_isLoading) return;
    if (!forceRefresh && _renewals.isNotEmpty) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _renewals = type == RenewalType.vendor
          ? await _apiService.getVendorRenewalsList()
          : await _apiService.getClientRenewalsList();
    } catch (error) {
      _errorMessage = _toMessage(error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String _toMessage(Object error) {
    final message = error.toString().trim();
    if (message.startsWith('Exception: ')) {
      return message.substring('Exception: '.length);
    }
    return message.isEmpty ? 'Unable to load renewals right now.' : message;
  }
}
