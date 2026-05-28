import 'package:translator/translator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TranslatorService {
  static final _translator = GoogleTranslator();
  static String _currentLanguage = 'en';
  static const _prefKey = 'selected_language';

  static String get currentLanguage => _currentLanguage;

  // Call this once at app startup
  static Future<void> loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    _currentLanguage = prefs.getString(_prefKey) ?? 'en';
  }

  static Future<void> setLanguage(String langCode) async {
    _currentLanguage = langCode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, langCode); // ← persist it
  }

  static final Map<String, String> _cache = {};

  static Future<String> translate(String text) async {
    if (_currentLanguage == 'en') return text;
    final cacheKey = '${_currentLanguage}_$text';
    if (_cache.containsKey(cacheKey)) return _cache[cacheKey]!;
    try {
      final result = await _translator.translate(text, to: _currentLanguage);
      _cache[cacheKey] = result.text;
      return result.text;
    } catch (e) {
      return text;
    }
  }
}