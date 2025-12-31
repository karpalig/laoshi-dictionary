class Word {
  final String id;
  String chinese;
  String pinyin;
  String russian;
  bool isFavorite;
  DateTime createdAt;
  DateTime? lastAccessed;
  int hskLevel;
  String dictionaryId;

  Word({
    required this.id,
    required this.chinese,
    required this.pinyin,
    required this.russian,
    this.isFavorite = false,
    required this.createdAt,
    this.lastAccessed,
    this.hskLevel = 0,
    required this.dictionaryId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'chinese': chinese,
      'pinyin': pinyin,
      'russian': russian,
      'isFavorite': isFavorite ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
      'lastAccessed': lastAccessed?.toIso8601String(),
      'hskLevel': hskLevel,
      'dictionaryId': dictionaryId,
    };
  }

  factory Word.fromMap(Map<String, dynamic> map) {
    return Word(
      id: map['id'] as String,
      chinese: map['chinese'] as String,
      pinyin: map['pinyin'] as String,
      russian: map['russian'] as String,
      isFavorite: (map['isFavorite'] as int) == 1,
      createdAt: DateTime.parse(map['createdAt'] as String),
      lastAccessed: map['lastAccessed'] != null
          ? DateTime.parse(map['lastAccessed'] as String)
          : null,
      hskLevel: map['hskLevel'] as int? ?? 0,
      dictionaryId: map['dictionaryId'] as String,
    );
  }

  Word copyWith({
    String? chinese,
    String? pinyin,
    String? russian,
    bool? isFavorite,
    DateTime? lastAccessed,
    int? hskLevel,
  }) {
    return Word(
      id: id,
      chinese: chinese ?? this.chinese,
      pinyin: pinyin ?? this.pinyin,
      russian: russian ?? this.russian,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt,
      lastAccessed: lastAccessed ?? this.lastAccessed,
      hskLevel: hskLevel ?? this.hskLevel,
      dictionaryId: dictionaryId,
    );
  }

  String get hskLevelString {
    return hskLevel > 0 ? 'HSK $hskLevel' : '';
  }
}
