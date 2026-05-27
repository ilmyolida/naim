import '../models/word_model.dart';
/// "An-Na’im al-Kubro" lug'atidagi barcha harflar (bog'lovchilar, old qo'shimchalar) ro'yxati.
List<DictionaryWord> particlesData = [
  DictionaryWord(
    id: 2001, // Noyob ID boshqa guruhlardan ajralib turishi uchun
    word: "وَ",
    translation: "va",
    type: WordType.harf,
  ),
  DictionaryWord(
    id: 2002,
    word: "فَ",
    translation: "va (keyingi gapni bog'lash uchun)",
    type: WordType.harf,
  ),
  // ... qolgan harflarni shu yerga qo'shing ...
];