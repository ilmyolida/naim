import '../models/word_model.dart';
import '../data/words_data_fel.dart';
import '../data/words_data_ism.dart';
import '../data/words_data_harf.dart';

class DataService {
  static Future<List<DictionaryWord>> loadAllData() async {
    final List<DictionaryWord> allWords = [];
    allWords.addAll(verbsData);
    allWords.addAll(nounsData);
    allWords.addAll(particlesData);
    return allWords;
  }
}