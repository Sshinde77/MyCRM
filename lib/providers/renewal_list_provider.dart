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
  int _perPage = 10;
  int _total = 0;
  int _currentPage = 1;
  int _lastPage = 1;
  String _currentSearch = '';

  List<RenewalModel> get renewals => _renewals;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get perPage => _perPage;
  int get total => _total;
  int get currentPage => _currentPage;
  int get lastPage => _lastPage;
  String get currentSearch => _currentSearch;

  Future<void> loadRenewals({
    bool forceRefresh = false,
    int page = 1,
    String? search,
  }) async {
    if (_isLoading) return;
    final normalizedPage = page < 1 ? 1 : page;
    final normalizedSearch = (search ?? '').trim();
    if (!forceRefresh &&
        _renewals.isNotEmpty &&
        _currentPage == normalizedPage &&
        _currentSearch == normalizedSearch) {
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = type == RenewalType.vendor
          ? await _apiService.getVendorRenewalsPage(
              page: normalizedPage,
              search: normalizedSearch,
            )
          : await _apiService.getClientRenewalsPage(
              page: normalizedPage,
              search: normalizedSearch,
            );

      _renewals = List<RenewalModel>.from(result.items);
      _currentPage = result.currentPage < 1
          ? normalizedPage
          : result.currentPage;
      _lastPage = result.lastPage < 1 ? 1 : result.lastPage;
      _perPage = result.perPage > 0 ? result.perPage : 10;
      _total = result.total >= 0 ? result.total : _renewals.length;
      _currentSearch = normalizedSearch;
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
