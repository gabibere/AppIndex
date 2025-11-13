import 'dart:convert';
import 'package:dio/dio.dart';
import '../utils/debug_logger.dart';

/// Service for handling and converting technical errors into user-friendly messages
class ErrorHandlingService {
  /// Convert technical errors into user-friendly messages
  static String getFriendlyErrorMessage(dynamic error) {
    // Log the technical error for debugging
    DebugLogger.error('Technical error: $error');

    // Handle DioException (network errors)
    if (error is DioException) {
      return _handleDioException(error);
    }

    // Handle generic exceptions
    if (error is Exception) {
      return _handleGenericException(error);
    }

    // Handle string errors
    if (error is String) {
      return _handleStringError(error);
    }

    // Default fallback
    return 'Eroare de server';
  }

  /// Handle DioException (network-related errors)
  static String _handleDioException(DioException error) {
    // Try to extract msg_err from error response body first
    if (error.response != null && error.response!.data != null) {
      try {
        Map<String, dynamic>? errorData;
        if (error.response!.data is String) {
          final responseString = error.response!.data as String;
          if (responseString.isNotEmpty) {
            errorData = json.decode(responseString) as Map<String, dynamic>?;
          }
        } else {
          errorData = error.response!.data as Map<String, dynamic>?;
        }

        if (errorData != null && errorData.containsKey('msg_err')) {
          final msgErr = errorData['msg_err']?.toString();
          if (msgErr != null && msgErr.isNotEmpty) {
            return msgErr;
          }
        }
      } catch (e) {
        // If parsing fails, fall through to default error
      }
    }

    // Default error message for all DioException types
    return 'Eroare de server';
  }

  /// Handle generic exceptions
  static String _handleGenericException(Exception error) {
    // All generic exceptions return the same generic message
    return 'Eroare de server';
  }

  /// Handle string errors
  static String _handleStringError(String error) {
    // Return the original error message if it's not empty, otherwise generic error
    if (error.isNotEmpty) {
      return error;
    }
    return 'Eroare de server';
  }

  /// Get user-friendly error message for API responses
  static String getApiErrorMessage(Map<String, dynamic> response) {
    final err = response['err'];
    final msgErr = response['msg_err']?.toString() ?? '';

    // If err is 0, it's success
    if (err == 0) {
      return '';
    }

    // Return the actual msg_err from API if available
    if (msgErr.isNotEmpty) {
      return msgErr;
    }

    // Default API error
    return 'Eroare de server';
  }

  /// Check if error is retryable
  static bool isRetryableError(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.connectionError:
          return true;
        case DioExceptionType.badResponse:
          final statusCode = error.response?.statusCode;
          return statusCode != null && statusCode >= 500;
        default:
          return false;
      }
    }

    if (error is Exception) {
      final errorString = error.toString().toLowerCase();
      return errorString.contains('timeout') ||
          errorString.contains('socketexception') ||
          errorString.contains('handshakeexception');
    }

    return false;
  }

  /// Get retry suggestion message
  static String getRetryMessage() {
    return 'Vă rugăm să încercați din nou în câteva momente.';
  }
}
