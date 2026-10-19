/// In-memory cache for lead priorities so that leads from any source
/// retain their priority across screens, list reloads, and detail views.
class LeadPriorityCache {
  static final Map<String, String> _cache = {};

  static String _normalize(String? value) {
    if (value == null) return '';
    return value.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '');
  }

  /// Store priority for a given lead. Stores both source-independent by ID
  /// and source-qualified by (sourceType, sourceId).
  static void set({
    String? sourceType,
    required String? sourceId,
    required String? priority,
  }) {
    final p = priority?.trim().toLowerCase();
    final id = (sourceId ?? '').trim().toLowerCase();
    if (id.isEmpty || p == null || p.isEmpty) return;

    // 1. Source-independent cache by ID alone
    _cache[id] = p;

    // 2. Also cache with normalized source type if provided
    final type = _normalize(sourceType);
    if (type.isNotEmpty) {
      _cache['$type::$id'] = p;
    }
  }

  /// Retrieve cached priority. Checks source-qualified first, then ID-alone.
  static String? get({
    String? sourceType,
    required String? sourceId,
  }) {
    final id = (sourceId ?? '').trim().toLowerCase();
    if (id.isEmpty) return null;

    final type = _normalize(sourceType);
    if (type.isNotEmpty && _cache.containsKey('$type::$id')) {
      return _cache['$type::$id'];
    }

    // Fallback to source-independent lookup by ID alone
    return _cache[id];
  }

  /// Returns true if the cached priority is high.
  static bool isHigh({String? sourceType, required String? sourceId}) {
    final val = get(sourceType: sourceType, sourceId: sourceId);
    return val == 'high' || val == 'urgent' || val == 'critical' || val == '1';
  }

  /// Clears the priority cache.
  static void clear() => _cache.clear();
}
