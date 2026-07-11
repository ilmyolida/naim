import 'package:shared_preferences/shared_preferences.dart';
import '../models/word_model.dart';
import '../services/database_service.dart';

/// Ilovaning holatini va lokal bazani boshqaruvchi klass.
/// Endi tarix, sevimlilar va saqlanganlar SQLite bazasida saqlanadi.
class PreferencesManager {
  static const String _keyThemeMode = 'theme_mode'; // 0: Light, 1: Soft Cream, 2: Dark
  static const String _keyExactSearch = 'exact_search';
  static const String _keyFuzzySearch = 'fuzzy_search';

  static late SharedPreferences _prefs;
  static List<DictionaryWord> _favoritesCache = [];
  static List<DictionaryWord> _savedCache = [];
  static List<DictionaryWord> _historyCache = [];

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await DatabaseService.init();
    _favoritesCache = await DatabaseService.loadFavorites();
    _savedCache = await DatabaseService.loadSavedWords();
    _historyCache = await DatabaseService.loadHistory();
  }

  // --- Wrapper methods for compatibility with UI code ---
  static Future<void> addFavorite(DictionaryWord word) => addToFavorites(word);
  static Future<void> removeFavorite(DictionaryWord word) => removeFromFavorites(word);
  static Future<void> addSaved(DictionaryWord word) => addToSaved(word);
  static Future<void> removeSaved(DictionaryWord word) => removeFromSaved(word);

  // --- Sevimlilar boshqaruvi ---
  static List<DictionaryWord> loadFavorites() => List.unmodifiable(_favoritesCache);

  static Future<void> addToFavorites(DictionaryWord word) async {
    if (_favoritesCache.any((w) => w.id == word.id)) return;
    await DatabaseService.addToFavorites(word);
    _favoritesCache = await DatabaseService.loadFavorites();
  }

  static Future<void> removeFromFavorites(DictionaryWord word) async {
    await DatabaseService.removeFromFavorites(word);
    _favoritesCache.removeWhere((w) => w.id == word.id);
  }

  // --- Saqlanganlar boshqaruvi ---
  static List<DictionaryWord> loadSaved() => List.unmodifiable(_savedCache);

  static Future<void> addToSaved(DictionaryWord word) async {
    if (_savedCache.any((w) => w.id == word.id)) return;
    await DatabaseService.addToSaved(word);
    _savedCache = await DatabaseService.loadSavedWords();
  }

  static Future<void> removeFromSaved(DictionaryWord word) async {
    await DatabaseService.removeFromSaved(word);
    _savedCache.removeWhere((w) => w.id == word.id);
  }

  // --- Qidiruv Tarixi boshqaruvi ---
  static List<DictionaryWord> loadHistory() => List.unmodifiable(_historyCache);

  static Future<void> addToHistory(DictionaryWord word) async {
    await DatabaseService.addToHistory(word);
    _historyCache = await DatabaseService.loadHistory();
  }

  static Future<void> clearHistory() async {
    await DatabaseService.clearHistory();
    _historyCache = [];
  }

  // --- Ilova Rejimlari boshqaruvi ---
  static Future<void> saveThemeMode(int modeIndex) async {
    await _prefs.setInt(_keyThemeMode, modeIndex);
  }

  static int loadThemeMode() {
    return _prefs.getInt(_keyThemeMode) ?? 0;
  }

  // --- Qidiruv Sozlamalari boshqaruvi ---
  static Future<void> saveExactSearch(bool value) async {
    await _prefs.setBool(_keyExactSearch, value);
  }

  static bool loadExactSearch() => _prefs.getBool(_keyExactSearch) ?? false;

  static Future<void> saveFuzzySearch(bool value) async {
    await _prefs.setBool(_keyFuzzySearch, value);
  }

  static bool loadFuzzySearch() => _prefs.getBool(_keyFuzzySearch) ?? true;
}
