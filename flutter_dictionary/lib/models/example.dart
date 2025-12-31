class Example {
  final String id;
  String chineseSentence;
  String pinyinSentence;
  String russianTranslation;
  DateTime createdAt;
  String wordId;

  Example({
    required this.id,
    required this.chineseSentence,
    required this.pinyinSentence,
    required this.russianTranslation,
    required this.createdAt,
    required this.wordId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'chineseSentence': chineseSentence,
      'pinyinSentence': pinyinSentence,
      'russianTranslation': russianTranslation,
      'createdAt': createdAt.toIso8601String(),
      'wordId': wordId,
    };
  }

  factory Example.fromMap(Map<String, dynamic> map) {
    return Example(
      id: map['id'] as String,
      chineseSentence: map['chineseSentence'] as String,
      pinyinSentence: map['pinyinSentence'] as String,
      russianTranslation: map['russianTranslation'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      wordId: map['wordId'] as String,
    );
  }

  Example copyWith({
    String? chineseSentence,
    String? pinyinSentence,
    String? russianTranslation,
  }) {
    return Example(
      id: id,
      chineseSentence: chineseSentence ?? this.chineseSentence,
      pinyinSentence: pinyinSentence ?? this.pinyinSentence,
      russianTranslation: russianTranslation ?? this.russianTranslation,
      createdAt: createdAt,
      wordId: wordId,
    );
  }
}
