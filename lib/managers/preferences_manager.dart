import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/word_model.dart';

/// Ilovaning holatini (Settings, History) xotirada saqlash va yuklash klassi.
/// Bu klass orqali ilova yopilib ochilganda ma'lumotlar yo'qolmaydi.
class PreferencesManager {
    static const String _keyFavorites = 'favorites';
    static const String _keySaved = 'saved_words';

    // --- Sevimlilar boshqaruvi ---
    static List<DictionaryWord> loadFavorites() {
      final jsonStrList = _prefs.getStringList(_keyFavorites) ?? [];
      return jsonStrList
          .map((jsonStr) => DictionaryWord.fromJson(jsonDecode(jsonStr)))
          .toList();
    }

    static Future<void> addToFavorites(DictionaryWord word) async {
      List<DictionaryWord> current = loadFavorites();
      if (!current.contains(word)) {
        current.insert(0, word);
        final jsonStrList = current.map((w) => jsonEncode(w.toJson())).toList();
        await _prefs.setStringList(_keyFavorites, jsonStrList);
      }
    }

    static Future<void> removeFromFavorites(DictionaryWord word) async {
      List<DictionaryWord> current = loadFavorites();
      current.remove(word);
      final jsonStrList = current.map((w) => jsonEncode(w.toJson())).toList();
      await _prefs.setStringList(_keyFavorites, jsonStrList);
    }

    // --- Saqlanganlar boshqaruvi ---
    static List<DictionaryWord> loadSaved() {
      final jsonStrList = _prefs.getStringList(_keySaved) ?? [];
      return jsonStrList
          .map((jsonStr) => DictionaryWord.fromJson(jsonDecode(jsonStr)))
          .toList();
    }

    static Future<void> addToSaved(DictionaryWord word) async {
      List<DictionaryWord> current = loadSaved();
      if (!current.contains(word)) {
        current.insert(0, word);
        final jsonStrList = current.map((w) => jsonEncode(w.toJson())).toList();
        await _prefs.setStringList(_keySaved, jsonStrList);
      }
    }

    static Future<void> removeFromSaved(DictionaryWord word) async {
      List<DictionaryWord> current = loadSaved();
      current.remove(word);
      final jsonStrList = current.map((w) => jsonEncode(w.toJson())).toList();
      await _prefs.setStringList(_keySaved, jsonStrList);
    }
  static const String _keyHistory = 'search_history';
  static const String _keyThemeMode = 'theme_mode'; // 0: Light, 1: Soft Cream
  static const String _keyExactSearch = 'exact_search';
  static const String _keyFuzzySearch = 'fuzzy_search';

  static late SharedPreferences _prefs;

  // SharedPreferences'ni bir marta initializatsiya qilish funksiyasi (main.dart da chaqiriladi)
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // --- Qidiruv Tarixini boshqarish ---

  // Xotiradan 500ta qidiruv tarixini yuklash funksiyasi
  static List<DictionaryWord> loadHistory() {
    // JSON stringini olamiz
    final jsonStrList = _prefs.getStringList(_keyHistory) ?? [];
    // Har bir stringni qaytadan DictionaryWord modeliga o'tkazamiz
    return jsonStrList
        .map((jsonStr) => DictionaryWord.fromJson(jsonDecode(jsonStr)))
        .toList();
  }

  // Tarixga yangi so'zni qo'shish funksiyasi (500 limit)
  static Future<void> addToHistory(DictionaryWord word) async {
    List<DictionaryWord> currentHistory = loadHistory();
    
    // Agar bu so'z allaqachon bo'lsa, uni o'chirib boshiga o'tkazamiz (most recent)
    currentHistory.remove(word); 
    currentHistory.insert(0, word);

    // Agar limit oshsa, eng oxirgisini o'chiramiz
    if (currentHistory.length > 500) {
      currentHistory.removeLast();
    }

    // Yangi tarixni JSON formatiga o'tkazib saqlaymiz
    final jsonStrList = currentHistory.map((word) => jsonEncode(word.toJson())).toList();
    await _prefs.setStringList(_keyHistory, jsonStrList);
  }

  // Tarixni butunlay o'chirish
  static Future<void> clearHistory() async {
    await _prefs.remove(_keyHistory);
  }

  // --- Ilova Rejimlari boshqaruvi ---

  // Mavzu rejimini saqlash (0: light, 1: cream)
  static Future<void> saveThemeMode(int modeIndex) async {
    await _prefs.setInt(_keyThemeMode, modeIndex);
  }

  // Mavzu rejimini yuklash (standart holda 0 - light)
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