import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'speech_queue_manager.dart';

class TtsUnavailableException implements Exception {
  TtsUnavailableException(this.message);

  final String message;

  @override
  String toString() => 'TtsUnavailableException: $message';
}

class TtsService {
  TtsService._();

  static final TtsService instance = TtsService._();

  final FlutterTts _flutterTts = FlutterTts();

  bool _initialized = false;
  bool _available = false;
  bool _disposed = false;
  bool _isSpeaking = false;
  String? _lastError;
  double _configuredSpeechRate = 0.35;
  Future<bool>? _initInFlight;
  Completer<void>? _activeSpeechCompleter;

  bool get isInitialized => _initialized;
  bool get isAvailable => _available;
  bool get isSpeaking => _isSpeaking;
  String? get lastError => _lastError;
  double get configuredSpeechRate => _configuredSpeechRate;

  Future<bool> initialize({bool forceRetry = false}) async {
    if (_disposed) {
      return false;
    }

    if (_initialized && _available && !forceRetry) {
      return true;
    }

    final inFlight = _initInFlight;
    if (inFlight != null && !forceRetry) {
      return inFlight;
    }

    final future = _initializeInternal();
    _initInFlight = future;
    try {
      final result = await future;
      return result;
    } finally {
      if (identical(_initInFlight, future)) {
        _initInFlight = null;
      }
    }
  }

  Future<bool> _initializeInternal() async {
    if (_disposed) {
      return false;
    }

    const int maxAttempts = 3;
    var attempt = 0;
    while (attempt < maxAttempts && !_disposed) {
      attempt += 1;
      try {
        await _configureEngine();
        _initialized = true;
        _available = true;
        _lastError = null;
        _log('[TTS] Initialized');
        return true;
      } catch (error, stackTrace) {
        _lastError = error.toString();
        _available = false;
        _initialized = true;
        _log(
          '[TTS] Error: initialization failed on attempt $attempt -> $error',
        );
        if (kDebugMode) {
          log(
            'TTS initialization stacktrace',
            name: 'TtsService',
            error: error,
            stackTrace: stackTrace,
          );
        }
        if (attempt < maxAttempts) {
          await Future<void>.delayed(Duration(milliseconds: attempt * 250));
        }
      }
    }

    return false;
  }

  Future<void> _configureEngine() async {
    await _flutterTts.setLanguage(_bestLanguageCode());
    _configuredSpeechRate = 0.35;
    await _flutterTts.setSpeechRate(_configuredSpeechRate);
    if (kDebugMode) {
      debugPrint('Speech rate configured: $_configuredSpeechRate');
    }
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.awaitSpeakCompletion(true);

    if (Platform.isAndroid) {
      try {
        await _flutterTts.setAudioAttributesForNavigation();
      } catch (_) {
        // Best-effort audio focus configuration.
      }
    } else if (Platform.isIOS) {
      try {
        await _flutterTts.setSharedInstance(true);
        await _flutterTts.setIosAudioCategory(
          IosTextToSpeechAudioCategory.ambient,
          [
            IosTextToSpeechAudioCategoryOptions.allowBluetooth,
            IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
            IosTextToSpeechAudioCategoryOptions.mixWithOthers,
          ],
          IosTextToSpeechAudioMode.voicePrompt,
        );
      } catch (_) {
        // Best-effort configuration only.
      }
    }

    _flutterTts.setStartHandler(() {
      _isSpeaking = true;
      _log('[TTS] Speaking');
    });

    _flutterTts.setCompletionHandler(() {
      _isSpeaking = false;
      _log('[TTS] Completed');
      _completeActiveSpeech();
    });

    _flutterTts.setCancelHandler(() {
      _isSpeaking = false;
      _log('[TTS] Interrupted');
      _completeActiveSpeech();
    });

    _flutterTts.setErrorHandler((message) {
      _isSpeaking = false;
      _lastError = message;
      _log('[TTS] Error: $message');
      _completeActiveSpeech(error: TtsUnavailableException(message));
    });
  }

  String _bestLanguageCode() {
    final candidates = <String>[
      Platform.localeName.replaceAll('_', '-'),
      'en-IN',
      'en-US',
    ];

    for (final candidate in candidates) {
      if (candidate.trim().isNotEmpty) {
        return candidate;
      }
    }

    return 'en-US';
  }

  Future<void> speak(
    String text, {
    SpeechPriority priority = SpeechPriority.medium,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final announcement = text.trim();
    if (announcement.isEmpty || _disposed) {
      return;
    }

    final ready = await initialize();
    if (!ready || !_available) {
      throw TtsUnavailableException(_lastError ?? 'TTS engine unavailable');
    }

    final completer = Completer<void>();
    _activeSpeechCompleter = completer;

    try {
      _log('[TTS] Queue Add: ${priority.name} :: $announcement');
      await _flutterTts.speak(announcement);
      await completer.future.timeout(timeout);
    } finally {
      if (identical(_activeSpeechCompleter, completer)) {
        _activeSpeechCompleter = null;
      }
    }
  }

  Future<void> stop() async {
    try {
      await _flutterTts.stop();
      _isSpeaking = false;
      _completeActiveSpeech();
      _log('[TTS] Interrupted');
    } catch (error) {
      _lastError = error.toString();
      _log('[TTS] Error: stop failed -> $error');
    }
  }

  Future<void> pause() async {
    try {
      if (Platform.isAndroid && _isSpeaking) {
        await _flutterTts.pause();
      }
    } catch (error) {
      _lastError = error.toString();
      _log('[TTS] Error: pause failed -> $error');
    }
  }

  Future<void> resume() async {
    _log('[TTS] Resume requested (no-op)');
  }

  Future<void> dispose() async {
    _disposed = true;
    try {
      await _flutterTts.stop();
    } catch (_) {}
    _completeActiveSpeech();
    _available = false;
    _initialized = false;
    _isSpeaking = false;
  }

  void _completeActiveSpeech({Object? error}) {
    final completer = _activeSpeechCompleter;
    if (completer == null || completer.isCompleted) {
      return;
    }

    if (error == null) {
      completer.complete();
    } else {
      completer.completeError(error);
    }
    _activeSpeechCompleter = null;
  }

  void _log(String message) {
    if (kDebugMode) {
      print(message);
    }
    log(message, name: 'TtsService');
  }
}
