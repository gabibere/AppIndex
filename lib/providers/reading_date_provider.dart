import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../utils/debug_logger.dart';

class ReadingDateProvider extends ChangeNotifier {
  static const String _dateKey = 'global_reading_date';

  DateTime _selectedDate = DateTime.now();
  bool _isInitialized = false;

  DateTime get selectedDate => _selectedDate;
  bool get isInitialized => _isInitialized;

  String get formattedDate {
    return '${_selectedDate.day.toString().padLeft(2, '0')}.'
        '${_selectedDate.month.toString().padLeft(2, '0')}.'
        '${_selectedDate.year}';
  }

  String get apiFormattedDate {
    return '${_selectedDate.year}-'
        '${_selectedDate.month.toString().padLeft(2, '0')}-'
        '${_selectedDate.day.toString().padLeft(2, '0')}';
  }

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedDate = prefs.getString(_dateKey);

      if (savedDate != null) {
        _selectedDate = DateTime.parse(savedDate);
        if (AppConfig.showDebugInfo) {
          DebugLogger.log(
              '📅 [READING_DATE] Loaded saved date: $formattedDate');
        }
      } else {
        _selectedDate = DateTime.now();
        if (AppConfig.showDebugInfo) {
          DebugLogger.log(
              '📅 [READING_DATE] Using current date: $formattedDate');
        }
      }

      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      if (AppConfig.showDebugInfo) {
        DebugLogger.log('📅 [READING_DATE] Error loading date: $e');
      }
      _selectedDate = DateTime.now();
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<void> setDate(DateTime newDate) async {
    if (_selectedDate == newDate) return;

    _selectedDate = newDate;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_dateKey, newDate.toIso8601String());

      if (AppConfig.showDebugInfo) {
        DebugLogger.log('📅 [READING_DATE] Saved new date: $formattedDate');
      }
    } catch (e) {
      if (AppConfig.showDebugInfo) {
        DebugLogger.log('📅 [READING_DATE] Error saving date: $e');
      }
    }
  }

  Future<void> setToday() async {
    await setDate(DateTime.now());
  }

  Future<void> setYesterday() async {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    await setDate(yesterday);
  }

  Future<void> setTomorrow() async {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    await setDate(tomorrow);
  }

  bool isToday() {
    final now = DateTime.now();
    return _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;
  }

  bool isYesterday() {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return _selectedDate.year == yesterday.year &&
        _selectedDate.month == yesterday.month &&
        _selectedDate.day == yesterday.day;
  }

  bool isTomorrow() {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return _selectedDate.year == tomorrow.year &&
        _selectedDate.month == tomorrow.month &&
        _selectedDate.day == tomorrow.day;
  }

  String getRelativeDescription() {
    if (isToday()) return 'Astăzi';
    if (isYesterday()) return 'Ieri';
    if (isTomorrow()) return 'Mâine';

    final now = DateTime.now();
    final difference = _selectedDate.difference(now).inDays;

    if (difference > 0) {
      return 'În $difference zile';
    } else if (difference < 0) {
      return 'Acum ${-difference} zile';
    } else {
      return 'Astăzi';
    }
  }
}
