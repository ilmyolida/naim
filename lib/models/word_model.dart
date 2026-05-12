import 'package:flutter/foundation.dart';

/// Lug'atdagi so'z turini aniqlash (Fel, Ism, Harf).
/// Bu kelajakda kodni kengaytirish va xatolarni kamaytirish uchun kerak.
enum WordType { fel, ism, harf }

/// "An-Na’im al-Kubro" lug'atidagi bitta so'z yozuvi modeli.
/// Bu klass har bir so'z haqidagi ma'lumotni saqlaydi.
class DictionaryWord {
  final int id;           // Unique ID (xotiraga saqlash va tekshirish uchun)
  final String word;        // Arabcha so'z (masalan: فَعَلَ)
  final String translation; // O'zbekcha tarjimasi (masalan: Bajarmoq)
  final WordType type;      // So'z turining enumi

  DictionaryWord({
    required this.id,
    required this.word,
    required this.translation,
    required this.type,
  });

  // Xotiraga saqlash uchun JSON formatiga o'tkazish funksiyasi
  Map<String, dynamic> toJson() => {
    'id': id,
    'word': word,
    'translation': translation,
    'typeIndex': type.index, // Enumni index sifatida saqlaymiz (0, 1, 2)
  };

  // JSON dan modelga o'tkazish funksiyasi (xotiradan o'qiyotganda)
  factory DictionaryWord.fromJson(Map<String, dynamic> json) => DictionaryWord(
    id: json['id'],
    word: json['word'],
    translation: json['translation'],
    type: WordType.values[json['typeIndex']], // Indexdan enumni qaytaramiz
  );

  // So'zlarni taqqoslash uchun kerak (duplicates oldini olish)
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DictionaryWord &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}