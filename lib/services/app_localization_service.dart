import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service to manage app localization with SharedPreferences persistence
class AppLocalizationService {
  static const String _languageKey = 'selected_language';
  static const Locale _defaultLocale = Locale('en');
  
  static final List<Locale> _supportedLocales = [
    const Locale('en'),
    const Locale('ml'),
    const Locale('hi'),
  ];

  static List<Locale> get supportedLocales => _supportedLocales;

  /// Get the saved locale from SharedPreferences
  static Future<Locale> getSavedLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final languageCode = prefs.getString(_languageKey) ?? 'en';
      return Locale(languageCode);
    } catch (e) {
      return _defaultLocale;
    }
  }

  /// Save the selected locale to SharedPreferences
  static Future<void> saveLocale(Locale locale) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, locale.languageCode);
    } catch (e) {
      // Handle error silently
    }
  }

  /// Get locale name for display
  static String getLocaleName(Locale locale) {
    switch (locale.languageCode) {
      case 'en':
        return 'English';
      case 'ml':
        return 'മലയാളം';
      case 'hi':
        return 'हिंदी';
      default:
        return locale.languageCode;
    }
  }

  /// Get locale flag emoji
  static String getLocaleFlag(Locale locale) {
    switch (locale.languageCode) {
      case 'en':
        return '🇺🇸';
      case 'ml':
      case 'hi':
        return '🇮🇳';
      default:
        return '';
    }
  }

  /// Get list of supported languages with names and flags
  static List<Map<String, String>> getSupportedLanguages() {
    return _supportedLocales.map((locale) {
      return {
        'code': locale.languageCode,
        'name': getLocaleName(locale),
        'flag': getLocaleFlag(locale),
      };
    }).toList();
  }
}

