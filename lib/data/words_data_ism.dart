import '../models/word_model.dart';
/// "An-Na’im al-Kubro" lug'atidagi barcha ismlar (otlar) ro'yxati.
List<DictionaryWord> nounsData = [
  DictionaryWord(
    id: 1001, // Noyob ID boshqa guruhlardan ajralib turishi uchun
    word: "كِتَابٌ",
    translation: "Kitob",
    type: WordType.ism,
  ),
  DictionaryWord(
    id: 1002,
    word: "مَدْرَسَةٌ",
    translation: "Maktab",
    type: WordType.ism,
  ),
  // ... qolgan ismlarni shu yerga qo'shing ...
];