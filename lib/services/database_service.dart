import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/word_model.dart';
import 'data_service.dart';

class DatabaseService {
  static Database? _database;
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'naim_dictionary.db');

    _database = await openDatabase(
      path,
      version: 1,
      onCreate: _createSchema,
    );

    _initialized = true;
    await _ensureDictionaryFilled();
  }

  static Future<void> _createSchema(Database db, int version) async {
    await db.execute('''
      CREATE TABLE dictionary(
        id INTEGER PRIMARY KEY,
        word TEXT NOT NULL,
        translation TEXT NOT NULL,
        typeIndex INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE history(
        wordId INTEGER PRIMARY KEY,
        timestamp INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE favorites(
        wordId INTEGER PRIMARY KEY
      )
    ''');

    await db.execute('''
      CREATE TABLE saved_words(
        wordId INTEGER PRIMARY KEY
      )
    ''');

    await db.execute('CREATE INDEX idx_dictionary_word ON dictionary(word);');
    await db.execute('CREATE INDEX idx_dictionary_translation ON dictionary(translation);');
  }

  static Future<void> _ensureDictionaryFilled() async {
    final count = Sqflite.firstIntValue(
          await _database!.rawQuery('SELECT COUNT(*) FROM dictionary'),
        ) ??
        0;

    if (count == 0) {
      final words = await DataService.loadAllData();
      await bulkInsertWords(words);
    }
  }

  static Future<void> bulkInsertWords(List<DictionaryWord> words) async {
    final batch = _database!.batch();
    for (final word in words) {
      batch.insert(
        'dictionary',
        {
          'id': word.id,
          'word': word.word,
          'translation': word.translation,
          'typeIndex': word.type.index,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  static Future<List<DictionaryWord>> loadAllWords() async {
    final rows = await _database!.query(
      'dictionary',
      orderBy: 'word COLLATE NOCASE',
    );
    return rows
        .map((row) => DictionaryWord(
              id: row['id'] as int,
              word: row['word'] as String,
              translation: row['translation'] as String,
              type: WordType.values[row['typeIndex'] as int],
            ))
        .toList();
  }

  static Future<List<DictionaryWord>> searchWords(
    String query,
    bool exact,
    bool fuzzy,
  ) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return [];

    final whereParts = <String>[];
    final whereArgs = <Object>[];

    if (exact) {
      whereParts.add('(word = ? OR translation = ?)');
      whereArgs.addAll([trimmed, trimmed]);
    }
    if (fuzzy) {
      whereParts.add('(word LIKE ? OR translation LIKE ?)');
      whereArgs.addAll(['%$trimmed%', '%$trimmed%']);
    }

    if (whereParts.isEmpty) {
      // If no mode is selected, fallback to fuzzy search.
      whereParts.add('(word LIKE ? OR translation LIKE ?)');
      whereArgs.addAll(['%$trimmed%', '%$trimmed%']);
    }

    final rows = await _database!.query(
      'dictionary',
      where: whereParts.join(' OR '),
      whereArgs: whereArgs,
      orderBy: 'word COLLATE NOCASE',
      limit: 200,
    );

    return rows
        .map((row) => DictionaryWord(
              id: row['id'] as int,
              word: row['word'] as String,
              translation: row['translation'] as String,
              type: WordType.values[row['typeIndex'] as int],
            ))
        .toList();
  }

  static Future<void> addToHistory(DictionaryWord word) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    await _database!.insert(
      'history',
      {'wordId': word.id, 'timestamp': timestamp},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    final total = Sqflite.firstIntValue(
          await _database!.rawQuery('SELECT COUNT(*) FROM history'),
        ) ??
        0;
    if (total > 500) {
      await _database!.rawDelete(
        'DELETE FROM history WHERE timestamp IN (SELECT timestamp FROM history ORDER BY timestamp ASC LIMIT ?)',
        [total - 500],
      );
    }
  }

  static Future<List<DictionaryWord>> loadHistory() async {
    final rows = await _database!.rawQuery('''
      SELECT d.* FROM dictionary d
      INNER JOIN history h ON h.wordId = d.id
      ORDER BY h.timestamp DESC
      LIMIT 500
    ''');

    return rows
        .map((row) => DictionaryWord(
              id: row['id'] as int,
              word: row['word'] as String,
              translation: row['translation'] as String,
              type: WordType.values[row['typeIndex'] as int],
            ))
        .toList();
  }

  static Future<void> clearHistory() async {
    await _database!.delete('history');
  }

  static Future<void> addToFavorites(DictionaryWord word) async {
    await _database!.insert(
      'favorites',
      {'wordId': word.id},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  static Future<void> removeFromFavorites(DictionaryWord word) async {
    await _database!.delete(
      'favorites',
      where: 'wordId = ?',
      whereArgs: [word.id],
    );
  }

  static Future<List<DictionaryWord>> loadFavorites() async {
    final rows = await _database!.rawQuery('''
      SELECT d.* FROM dictionary d
      INNER JOIN favorites f ON f.wordId = d.id
      ORDER BY d.word COLLATE NOCASE
    ''');

    return rows
        .map((row) => DictionaryWord(
              id: row['id'] as int,
              word: row['word'] as String,
              translation: row['translation'] as String,
              type: WordType.values[row['typeIndex'] as int],
            ))
        .toList();
  }

  static Future<void> addToSaved(DictionaryWord word) async {
    await _database!.insert(
      'saved_words',
      {'wordId': word.id},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  static Future<void> removeFromSaved(DictionaryWord word) async {
    await _database!.delete(
      'saved_words',
      where: 'wordId = ?',
      whereArgs: [word.id],
    );
  }

  static Future<List<DictionaryWord>> loadSavedWords() async {
    final rows = await _database!.rawQuery('''
      SELECT d.* FROM dictionary d
      INNER JOIN saved_words s ON s.wordId = d.id
      ORDER BY d.word COLLATE NOCASE
    ''');

    return rows
        .map((row) => DictionaryWord(
              id: row['id'] as int,
              word: row['word'] as String,
              translation: row['translation'] as String,
              type: WordType.values[row['typeIndex'] as int],
            ))
        .toList();
  }

  static Future<void> updateWordTranslation(int wordId, String translation) async {
    await _database!.update(
      'dictionary',
      {'translation': translation},
      where: 'id = ?',
      whereArgs: [wordId],
    );
  }
}
