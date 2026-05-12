import 'words_data_fel.dart';
import 'words_data_ism.dart';
import 'words_data_harf.dart';
import '../models/word_model.dart';

/// Barcha 3ta guruhni birlashtirib, umumiy ro'yxatni beradigan klass.
/// Bu ilovada umumiy qidiruv va ma'lumotlarni yuklash uchun ishlatiladi.
class WordsRepository {
  // Barcha ro'yxatlarni birlashtiramiz (Order saqlangan holda)
  static final List<DictionaryWord> allWords = [
    ...verbsData,
    ...nounsData,
    ...particlesData,
  ];

  // Alohida guruhlarni olish uchun getter'lar (kelajakda kerak bo'lishi mumkin)
  static List<DictionaryWord> get verbs => verbsData;
  static List<DictionaryWord> get nouns => nounsData;
  static List<DictionaryWord> get particles => particlesData;
}