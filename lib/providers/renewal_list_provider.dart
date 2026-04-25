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

  List<RenewalModel> get renewals => _renewals;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get perPage => _perPage;
  int get total => _total;

  Future<void> loadRenewals({bool forceRefresh = false}) async {
    if (_isLoading) return;
    if (!forceRefresh && _renewals.isNotEmpty) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final collected = <RenewalModel>[];
      var page = 1;
      var lastPage = 1;
      var perPage = 10;
      var total = 0;

      do {
        final result = type == RenewalType.vendor
            ? await _apiService.getVendorRenewalsPage(page: page)
            : await _apiService.getClientRenewalsPage(page: page);
        collected.addAll(result.items);
        lastPage = result.lastPage < 1 ? 1 : result.lastPage;
        perPage = result.perPage > 0 ? result.perPage : perPage;
        total = result.total > 0 ? result.total : total;
        page += 1;
      } while (page <= lastPage);

      _renewals = List<RenewalModel>.from(collected);
      _perPage = perPage;
      _total = total > 0 ? total : _renewals.length;
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
