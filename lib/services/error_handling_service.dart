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
    return 'A apărut o problemă neașteptată. Vă rugăm să încercați din nou.';
  }

  /// Handle DioException (network-related errors)
  static String _handleDioException(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return 'Timpul de conexiune a expirat. Vă rugăm să verificați conexiunea la internet.';

      case DioExceptionType.sendTimeout:
        return 'Timpul de trimitere a expirat. Vă rugăm să încercați din nou.';

      case DioExceptionType.receiveTimeout:
        return 'Timpul de primire a expirat. Vă rugăm să încercați din nou.';

      case DioExceptionType.badResponse:
        return _handleHttpError(error.response?.statusCode);

      case DioExceptionType.cancel:
        return 'Operațiunea a fost anulată.';

      case DioExceptionType.connectionError:
        return 'Nu s-a putut conecta la server. Vă rugăm să verificați conexiunea la internet.';

      case DioExceptionType.badCertificate:
        return 'Certificat de securitate invalid. Vă rugăm să contactați administratorul.';

      case DioExceptionType.unknown:
        return 'Eroare de conexiune necunoscută. Vă rugăm să încercați din nou.';
    }
  }

  /// Handle HTTP status codes
  static String _handleHttpError(int? statusCode) {
    switch (statusCode) {
      case 400:
        return 'Cererea este invalidă. Vă rugăm să verificați datele introduse.';
      case 401:
        return 'Nu sunteți autentificat. Vă rugăm să vă conectați din nou.';
      case 403:
        return 'Nu aveți permisiunea de a accesa această resursă.';
      case 404:
        return 'Serviciul nu a fost găsit. Vă rugăm să contactați administratorul.';
      case 408:
        return 'Timpul de așteptare a expirat. Vă rugăm să încercați din nou.';
      case 409:
        return 'Conflict de date. Vă rugăm să verificați informațiile.';
      case 422:
        return 'Datele introduse nu sunt valide. Vă rugăm să le corectați.';
      case 429:
        return 'Prea multe cereri. Vă rugăm să așteptați puțin.';
      case 500:
        return 'Eroare internă a serverului. Vă rugăm să încercați mai târziu.';
      case 502:
        return 'Serverul nu este disponibil. Vă rugăm să încercați mai târziu.';
      case 503:
        return 'Serviciul este temporar indisponibil. Vă rugăm să încercați mai târziu.';
      case 504:
        return 'Timpul de așteptare a expirat. Vă rugăm să încercați din nou.';
      default:
        return 'Eroare de server (${statusCode ?? 'necunoscut'}). Vă rugăm să încercați mai târziu.';
    }
  }

  /// Handle generic exceptions
  static String _handleGenericException(Exception error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('socketexception') ||
        errorString.contains('handshakeexception')) {
      return 'Nu s-a putut conecta la server. Vă rugăm să verificați conexiunea la internet.';
    }

    if (errorString.contains('timeout')) {
      return 'Timpul de așteptare a expirat. Vă rugăm să încercați din nou.';
    }

    if (errorString.contains('format')) {
      return 'Formatul datelor este invalid. Vă rugăm să contactați administratorul.';
    }

    if (errorString.contains('permission')) {
      return 'Nu aveți permisiunea necesară pentru această operațiune.';
    }

    return 'A apărut o problemă neașteptată. Vă rugăm să încercați din nou.';
  }

  /// Handle string errors
  static String _handleStringError(String error) {
    final errorLower = error.toLowerCase();

    if (errorLower.contains('device necunoscut')) {
      return 'Dispozitivul nu este înregistrat. Vă rugăm să contactați administratorul.';
    }

    if (errorLower.contains('session required') ||
        errorLower.contains('session expired')) {
      return 'Sesiunea a expirat. Vă rugăm să vă conectați din nou.';
    }

    if (errorLower.contains('invalid credentials') ||
        errorLower.contains('authentication failed')) {
      return 'Numele de utilizator sau parola sunt incorecte.';
    }

    if (errorLower.contains('network') || errorLower.contains('connection')) {
      return 'Probleme de conexiune. Vă rugăm să verificați internetul.';
    }

    if (errorLower.contains('server') ||
        errorLower.contains('internal error')) {
      return 'Eroare de server. Vă rugăm să încercați mai târziu.';
    }

    if (errorLower.contains('not found') || errorLower.contains('404')) {
      return 'Informațiile căutate nu au fost găsite.';
    }

    if (errorLower.contains('unauthorized') || errorLower.contains('403')) {
      return 'Nu aveți permisiunea de a accesa această funcție.';
    }

    if (errorLower.contains('validation') || errorLower.contains('invalid')) {
      return 'Datele introduse nu sunt valide. Vă rugăm să le verificați.';
    }

    // Return the original error if no pattern matches (for debugging)
    return error;
  }

  /// Get user-friendly error message for API responses
  static String getApiErrorMessage(Map<String, dynamic> response) {
    final err = response['err'];
    final msgErr = response['msg_err']?.toString() ?? '';

    // If err is 0, it's success
    if (err == 0) {
      return '';
    }

    // Handle specific error messages from API
    if (msgErr.isNotEmpty) {
      return _handleStringError(msgErr);
    }

    // Default API error
    return 'A apărut o problemă la comunicarea cu serverul. Vă rugăm să încercați din nou.';
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
