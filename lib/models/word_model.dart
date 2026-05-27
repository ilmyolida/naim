enum WordType { fel, ism, harf }

class DictionaryWord {
  final int id;
  final String word;
  final String translation;
  final WordType type;

  DictionaryWord({
    required this.id,
    required this.word,
    required this.translation,
    required this.type,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'word': word,
    'translation': translation,
    'typeIndex': type.index,
  };

  factory DictionaryWord.fromJson(Map<String, dynamic> json) => DictionaryWord(
    id: json['id'],
    word: json['word'],
    translation: json['translation'],
    type: WordType.values[json['typeIndex']],
  );
}