import '../config/app_config.dart';

class DebugLogger {
  static void log(String message, {String? tag}) {
    if (AppConfig.showDebugInfo) {
      final timestamp = DateTime.now().toIso8601String().substring(11, 23);
      final prefix = tag != null ? '[$tag]' : '[DEBUG]';
      // ignore: avoid_print
      print('$prefix $timestamp: $message');
    }
  }

  static void api(String message) {
    log(message, tag: 'API');
  }

  static void search(String message) {
    log(message, tag: 'SEARCH');
  }

  static void location(String message) {
    log(message, tag: 'LOCATION');
  }

  static void auth(String message) {
    log(message, tag: 'AUTH');
  }

  static void device(String message) {
    log(message, tag: 'DEVICE');
  }

  static void encryption(String message) {
    log(message, tag: 'ENCRYPTION');
  }

  static void error(String message, {Object? error, StackTrace? stackTrace}) {
    if (AppConfig.showDebugInfo) {
      final timestamp = DateTime.now().toIso8601String().substring(11, 23);
      // ignore: avoid_print
      print('🚨 [ERROR] $timestamp: $message');
      if (error != null) {
        // ignore: avoid_print
        print('🚨 [ERROR] Exception: $error');
      }
      if (stackTrace != null) {
        // ignore: avoid_print
        print('🚨 [ERROR] StackTrace: $stackTrace');
      }
    }
  }

  static void warning(String message) {
    if (AppConfig.showDebugInfo) {
      final timestamp = DateTime.now().toIso8601String().substring(11, 23);
      // ignore: avoid_print
      print('⚠️ [WARNING] $timestamp: $message');
    }
  }

  static void success(String message) {
    if (AppConfig.showDebugInfo) {
      final timestamp = DateTime.now().toIso8601String().substring(11, 23);
      // ignore: avoid_print
      print('✅ [SUCCESS] $timestamp: $message');
    }
  }
}
