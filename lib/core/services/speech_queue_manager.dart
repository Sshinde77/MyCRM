import 'dart:async';
import 'dart:collection';
import 'dart:developer';

enum SpeechPriority { low, medium, high }

class SpeechQueueEntry {
  const SpeechQueueEntry({
    required this.text,
    required this.priority,
    required this.dedupeKey,
    required this.createdAt,
    required this.timeout,
  });

  final String text;
  final SpeechPriority priority;
  final String dedupeKey;
  final DateTime createdAt;
  final Duration timeout;
}

class SpeechQueueManager {
  SpeechQueueManager({
    required Future<void> Function(SpeechQueueEntry entry) speak,
    required Future<void> Function() stopCurrent,
    void Function(String message)? logger,
    DateTime Function()? clock,
    this.maxQueueSize = 20,
    this.duplicateExpiry = const Duration(minutes: 2),
    this.defaultTimeout = const Duration(seconds: 30),
  })  : _speak = speak,
        _stopCurrent = stopCurrent,
        _logger = logger,
        _clock = clock ?? DateTime.now;

  final Future<void> Function(SpeechQueueEntry entry) _speak;
  final Future<void> Function() _stopCurrent;
  final void Function(String message)? _logger;
  final DateTime Function() _clock;

  final int maxQueueSize;
  final Duration duplicateExpiry;
  final Duration defaultTimeout;

  final ListQueue<SpeechQueueEntry> _queue = ListQueue<SpeechQueueEntry>();
  final Map<String, DateTime> _recentDedupes = <String, DateTime>{};

  bool _isProcessing = false;
  bool _isDisposed = false;
  SpeechQueueEntry? _currentEntry;

  int get queueLength => _queue.length;

  bool get isProcessing => _isProcessing;

  Future<bool> enqueue(SpeechQueueEntry entry) async {
    if (_isDisposed) {
      _log('[TTS] Queue ignored after dispose');
      return false;
    }

    _cleanupDedupes();

    if (_isDuplicate(entry.dedupeKey)) {
      _log('[TTS] Duplicate ignored: ${entry.dedupeKey}');
      return false;
    }

    if (_queue.length >= maxQueueSize) {
      _log('[TTS] Queue full, dropping: ${entry.dedupeKey}');
      return false;
    }

    _recentDedupes[entry.dedupeKey] = _clock();
    _insertOrdered(entry);
    _log('[TTS] Queue Add: ${entry.priority.name} :: ${entry.text}');

    if (_currentEntry != null &&
        entry.priority == SpeechPriority.high &&
        _currentEntry!.priority == SpeechPriority.low) {
      _log('[TTS] Interrupted: ${_currentEntry!.text}');
      unawaited(_stopCurrent());
    }

    unawaited(_processQueue());
    return true;
  }

  Future<void> cancelAll() async {
    _queue.clear();
    await _stopCurrent();
  }

  Future<void> dispose() async {
    _isDisposed = true;
    await cancelAll();
    _recentDedupes.clear();
  }

  void _insertOrdered(SpeechQueueEntry entry) {
    if (_queue.isEmpty) {
      _queue.add(entry);
      return;
    }

    final items = _queue.toList();
    var insertIndex = items.length;

    for (var index = 0; index < items.length; index++) {
      final current = items[index];
      final shouldInsertBefore = _priorityWeight(entry.priority) >
              _priorityWeight(current.priority) ||
          (_priorityWeight(entry.priority) == _priorityWeight(current.priority) &&
              entry.createdAt.isBefore(current.createdAt));
      if (shouldInsertBefore) {
        insertIndex = index;
        break;
      }
    }

    items.insert(insertIndex, entry);
    _queue
      ..clear()
      ..addAll(items);
  }

  Future<void> _processQueue() async {
    if (_isProcessing || _isDisposed) {
      return;
    }

    _isProcessing = true;
    try {
      while (_queue.isNotEmpty && !_isDisposed) {
        final entry = _queue.removeFirst();
        _currentEntry = entry;
        _log('[TTS] Speaking: ${entry.text}');

        try {
          await _speak(entry).timeout(entry.timeout);
          _log('[TTS] Completed: ${entry.text}');
        } on TimeoutException catch (error) {
          _log('[TTS] Error: timeout speaking "${entry.text}" -> $error');
          await _stopCurrent();
        } catch (error) {
          _log('[TTS] Error: ${entry.text} -> $error');
          await _stopCurrent();
        } finally {
          _currentEntry = null;
        }
      }
    } finally {
      _isProcessing = false;
    }
  }

  bool _isDuplicate(String dedupeKey) {
    final timestamp = _recentDedupes[dedupeKey];
    if (timestamp == null) {
      return false;
    }

    return _clock().difference(timestamp) <= duplicateExpiry;
  }

  void _cleanupDedupes() {
    final now = _clock();
    _recentDedupes.removeWhere((_, timestamp) => now.difference(timestamp) > duplicateExpiry);
  }

  int _priorityWeight(SpeechPriority priority) {
    switch (priority) {
      case SpeechPriority.low:
        return 0;
      case SpeechPriority.medium:
        return 1;
      case SpeechPriority.high:
        return 2;
    }
  }

  void _log(String message) {
    final logger = _logger;
    if (logger != null) {
      logger(message);
      return;
    }
    log(message, name: 'SpeechQueueManager');
  }
}
