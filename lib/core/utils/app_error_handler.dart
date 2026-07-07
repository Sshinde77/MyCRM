import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class AppErrorHandler {
  const AppErrorHandler._();

  static const String noInternetMessage =
      'No internet connection. Please check your network.';
  static const String timeoutMessage = 'Request timed out. Please try again.';
  static const String sessionExpiredMessage =
      'Your session has expired. Please login again.';
  static const String forbiddenMessage =
      "You don't have permission to perform this action.";
  static const String notFoundMessage = 'Requested data not found.';
  static const String validationFallbackMessage =
      'Please check the entered details.';
  static const String serverErrorMessage =
      'Something went wrong on our side. Please try again later.';
  static const String unknownErrorMessage =
      'Something went wrong. Please try again.';

  static String messageFromError(
    Object? error, {
    String? fallback,
    bool showValidationMessage = true,
  }) {
    if (error == null) {
      return fallback ?? unknownErrorMessage;
    }

    if (error is DioException) {
      final response = error.response;
      final statusCode = response?.statusCode;
      final validationMessage = showValidationMessage
          ? _extractValidationMessage(response?.data)
          : null;

      if (validationMessage != null && validationMessage.isNotEmpty) {
        return validationMessage;
      }

      if (statusCode == 401) return sessionExpiredMessage;
      if (statusCode == 403) return forbiddenMessage;
      if (statusCode == 404) return notFoundMessage;
      if (statusCode == 422) {
        return validationFallbackMessage;
      }
      if (statusCode != null && statusCode >= 500) {
        return serverErrorMessage;
      }

      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.transformTimeout:
          return timeoutMessage;
        case DioExceptionType.connectionError:
          return noInternetMessage;
        case DioExceptionType.badResponse:
          return _messageFromResponseData(response?.data) ??
              fallback ??
              unknownErrorMessage;
        case DioExceptionType.cancel:
          return fallback ?? unknownErrorMessage;
        case DioExceptionType.badCertificate:
        case DioExceptionType.unknown:
          if (_looksLikeNetworkError(error.error) ||
              _looksLikeNetworkError(error.message)) {
            return noInternetMessage;
          }
          return _messageFromResponseData(response?.data) ??
              fallback ??
              unknownErrorMessage;
      }
    }

    if (error is SocketException) {
      return noInternetMessage;
    }

    final responseStatus = _extractStatusCode(error);
    if (responseStatus == 401) return sessionExpiredMessage;
    if (responseStatus == 403) return forbiddenMessage;
    if (responseStatus == 404) return notFoundMessage;
    if (responseStatus == 422) return validationFallbackMessage;
    if (responseStatus != null && responseStatus >= 500) {
      return serverErrorMessage;
    }

    final message = _messageFromAny(error);
    if (message != null) {
      if (_looksLikeTechnicalMessage(message)) {
        return fallback ?? unknownErrorMessage;
      }
      return message;
    }

    return fallback ?? unknownErrorMessage;
  }

  static String sanitizeMessage(String message, {bool isError = false}) {
    final trimmed = message.trim();
    if (trimmed.isEmpty) return trimmed;
    if (_looksLikeTechnicalMessage(trimmed)) {
      return isError ? unknownErrorMessage : trimmed;
    }
    return trimmed;
  }

  static void debugLog(Object? error, {String? context}) {
    if (!kDebugMode) return;
    final prefix = context == null || context.trim().isEmpty
        ? '[Error]'
        : '[Error][$context]';
    debugPrint('$prefix ${messageFromError(error)}');
    if (error != null) {
      debugPrint(error.toString());
    }
  }

  static String? _messageFromAny(Object? error) {
    if (error == null) return null;
    if (error is String) {
      final text = error.trim();
      return text.isEmpty ? null : text;
    }
    final text = error.toString().trim();
    return text.isEmpty ? null : text;
  }

  static int? _extractStatusCode(Object? error) {
    if (error is DioException) {
      return error.response?.statusCode;
    }
    if (error is Map) {
      final normalized = error.map(
        (key, value) => MapEntry(key.toString(), value),
      );
      final status = normalized['statusCode'] ?? normalized['status'];
      return int.tryParse(status?.toString() ?? '');
    }
    return null;
  }

  static bool _looksLikeNetworkError(Object? value) {
    final text = value?.toString().toLowerCase() ?? '';
    if (text.isEmpty) return false;
    return text.contains('socketexception') ||
        text.contains('failed host lookup') ||
        text.contains('connection refused') ||
        text.contains('network is unreachable') ||
        text.contains('connection error') ||
        text.contains('no address associated with hostname');
  }

  static bool _looksLikeTechnicalMessage(String value) {
    final text = value.toLowerCase();
    return text.contains('dioexception') ||
        text.contains('socketexception') ||
        text.contains('stack trace') ||
        text.contains('requestoptions') ||
        text.contains('validatestatus') ||
        text.contains('http status') ||
        text.contains('exception:') ||
        text.contains('bad response') ||
        text.contains('response:') ||
        text.contains('statuscode:') ||
        text.contains('status code') ||
        text.contains('traceback');
  }

  static String? _messageFromResponseData(dynamic data) {
    if (data == null) return null;
    if (data is String) {
      final trimmed = data.trim();
      return trimmed.isEmpty ? null : trimmed;
    }
    if (data is Map) {
      final normalized = data.map(
        (key, value) => MapEntry(key.toString(), value),
      );
      for (final key in const [
        'message',
        'error',
        'error_message',
        'detail',
        'title',
      ]) {
        final value = normalized[key];
        if (value == null) continue;
        if (value is String && value.trim().isNotEmpty) {
          return value.trim();
        }
        final nested = _messageFromResponseData(value);
        if (nested != null && nested.trim().isNotEmpty) {
          return nested.trim();
        }
      }
      final validation = _extractValidationMessage(normalized);
      if (validation != null && validation.isNotEmpty) {
        return validation;
      }
    }
    if (data is Iterable) {
      for (final item in data) {
        final message = _messageFromResponseData(item);
        if (message != null && message.trim().isNotEmpty) {
          return message.trim();
        }
      }
    }
    return null;
  }

  static String? _extractValidationMessage(dynamic data) {
    if (data == null) return null;
    if (data is String) {
      final trimmed = data.trim();
      return trimmed.isEmpty ? null : trimmed;
    }
    if (data is Map) {
      final normalized = data.map(
        (key, value) => MapEntry(key.toString(), value),
      );
      final errors = normalized['errors'];
      if (errors != null) {
        final nested = _extractValidationMessage(errors);
        if (nested != null && nested.isNotEmpty) return nested;
      }
      final field =
          normalized['field']?.toString().trim() ??
          normalized['name']?.toString().trim() ??
          '';
      final message =
          normalized['message']?.toString().trim() ??
          normalized['error']?.toString().trim() ??
          normalized['detail']?.toString().trim() ??
          '';
      if (field.isNotEmpty && message.isNotEmpty) {
        return '$field: $message';
      }
      for (final entry in normalized.entries) {
        final key = entry.key;
        final value = entry.value;
        if (key == 'errors' ||
            key == 'message' ||
            key == 'error' ||
            key == 'detail' ||
            key == 'field' ||
            key == 'name') {
          continue;
        }
        if (value is Map || value is Iterable) {
          final nested = _extractValidationMessage(value);
          if (nested != null && nested.isNotEmpty) {
            return nested;
          }
          continue;
        }
        final text = value?.toString().trim() ?? '';
        if (text.isNotEmpty) {
          return '$key: $text';
        }
      }
    }
    if (data is Iterable) {
      for (final item in data) {
        final message = _extractValidationMessage(item);
        if (message != null && message.isNotEmpty) return message;
      }
    }
    return null;
  }
}
