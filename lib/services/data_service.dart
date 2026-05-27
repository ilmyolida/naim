import 'package:flutter/services.dart' show rootBundle;
import '../models/word_model.dart';
class DataService {
  static Future<List<DictionaryWord>> loadAllData() async {
    List<DictionaryWord> allWords = [];
    List<String> files = [
      'assets/naim/naim1.txt', 'assets/naim/naim2.txt', 'assets/naim/naim3.txt',
      'assets/naim/naim4.txt', 'assets/naim/naim5.txt', 'assets/naim/naim6.txt',
    ];

    int currentId = 0; // Har bir so'zga ID berish uchun

    for (String file in files) {
      try {
        final String content = await rootBundle.loadString(file);
        final List<String> lines = content.split('\n');

        for (var line in lines) {
          if (line.trim().isEmpty) continue;

          RegExp arabicRegex = RegExp(r'[\u0600-\u06FF]+');
          var matches = arabicRegex.allMatches(line);
          
          if (matches.isNotEmpty) {
            String arabic = matches.map((m) => m.group(0)).join(' ');
            String meaning = line.replaceAll(arabic, '').trim();
            meaning = meaning.replaceAll(RegExp(r'\[U\+[0-9A-F]+\]'), '').trim();

            // WordType aniqlash mantiqi
            WordType type = WordType.ism; 
            if (meaning.endsWith('мок') || meaning.contains(' мок')) {
              type = WordType.fel;
            } else if (line.contains('...')) {
              type = WordType.harf;
            }

            allWords.add(DictionaryWord(
              id: currentId++, 
              word: arabic, 
              translation: meaning, 
              type: type,
            ));
          }
        }
      // ignore: empty_catches
      } catch (e) {
      }
    }
    return allWords;
  }
}