import 'dart:convert';
import 'package:flutter/services.dart';
import '../utils/debug_logger.dart';

class LocalizationService {
  static Map<String, dynamic> _localizedStrings = {};
  static String _currentLanguage = 'ro';

  static Future<void> loadLanguage(String languageCode) async {
    _currentLanguage = languageCode;
    try {
      String jsonString =
          await rootBundle.loadString('assets/l10n/$languageCode.json');
      _localizedStrings = json.decode(jsonString);
      DebugLogger.success(
          '✅ Loaded localization for $languageCode: ${_localizedStrings.length} keys');
    } catch (e) {
      DebugLogger.log('❌ Failed to load $languageCode.json: $e');
      // Fallback to Romanian if the language file doesn't exist
      if (languageCode != 'ro') {
        try {
          String jsonString =
              await rootBundle.loadString('assets/l10n/ro.json');
          _localizedStrings = json.decode(jsonString);
          DebugLogger.success('✅ Loaded fallback Romanian localization');
        } catch (fallbackError) {
          DebugLogger.log('❌ Failed to load fallback Romanian: $fallbackError');
        }
      }
    }
  }

  static String getString(String key, {Map<String, String>? params}) {
    if (_localizedStrings.isEmpty) {
      DebugLogger.warning('⚠️ LocalizationService: No strings loaded yet for key: $key');
      return key;
    }

    List<String> keys = key.split('.');
    dynamic value = _localizedStrings;

    for (String k in keys) {
      if (value is Map<String, dynamic> && value.containsKey(k)) {
        value = value[k];
      } else {
        DebugLogger.warning('⚠️ LocalizationService: Key not found: $key');
        return key; // Return the key if translation not found
      }
    }

    String result = value.toString();

    // Replace parameters if provided
    if (params != null) {
      params.forEach((paramKey, paramValue) {
        result = result.replaceAll('{$paramKey}', paramValue);
      });
    }

    return result;
  }

  static String get currentLanguage => _currentLanguage;
}
