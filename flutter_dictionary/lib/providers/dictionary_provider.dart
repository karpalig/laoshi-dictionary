import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../database/database_helper.dart';
import '../models/dictionary.dart';
import '../models/word.dart';
import '../models/example.dart';
import '../utils/pinyin_helper.dart';

class DictionaryProvider with ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final _uuid = const Uuid();

  List<Dictionary> _dictionaries = [];
  List<Word> _allWords = [];
  List<Word> _searchResults = [];
  List<Word> _favoriteWords = [];
  String _searchQuery = '';

  List<Dictionary> get dictionaries => _dictionaries;
  List<Word> get allWords => _allWords;
  List<Word> get searchResults => _searchResults;
  List<Word> get favoriteWords => _favoriteWords;
  String get searchQuery => _searchQuery;

  DictionaryProvider() {
    _init();
  }

  Future<void> _init() async {
    await loadDictionaries();
    await loadAllWords();
  }

  // Dictionary operations
  Future<void> loadDictionaries() async {
    _dictionaries = await _db.getAllDictionaries();
    notifyListeners();
  }

  Future<void> createDictionary({
    required String name,
    String? description,
    String color = 'cyan',
  }) async {
    final dictionary = Dictionary(
      id: _uuid.v4(),
      name: name,
      description: description,
      createdAt: DateTime.now(),
      color: color,
      isActive: true,
    );
    await _db.insertDictionary(dictionary);
    await loadDictionaries();
  }

  Future<void> updateDictionary(Dictionary dictionary) async {
    await _db.updateDictionary(dictionary);
    await loadDictionaries();
  }

  Future<void> deleteDictionary(String id) async {
    await _db.deleteDictionary(id);
    await loadDictionaries();
    await loadAllWords();
  }

  Future<void> toggleDictionaryActive(Dictionary dictionary) async {
    final updated = dictionary.copyWith(isActive: !dictionary.isActive);
    await updateDictionary(updated);
  }

  // Word operations
  Future<void> loadAllWords() async {
    _allWords = await _db.getAllWords();
    _favoriteWords = await _db.getFavoriteWords();
    if (_searchQuery.isNotEmpty) {
      performSearch(_searchQuery);
    }
    notifyListeners();
  }

  Future<List<Word>> getWordsByDictionary(String dictionaryId) async {
    return await _db.getWordsByDictionary(dictionaryId);
  }

  Future<void> createWord({
    required String chinese,
    required String pinyin,
    required String russian,
    required String dictionaryId,
    int hskLevel = 0,
  }) async {
    final word = Word(
      id: _uuid.v4(),
      chinese: chinese,
      pinyin: PinyinHelper.numberedToToneMarks(pinyin),
      russian: russian,
      createdAt: DateTime.now(),
      dictionaryId: dictionaryId,
      hskLevel: hskLevel,
    );
    await _db.insertWord(word);
    await loadAllWords();
  }

  Future<void> updateWord(Word word) async {
    await _db.updateWord(word);
    await loadAllWords();
  }

  Future<void> deleteWord(String id) async {
    await _db.deleteWord(id);
    await loadAllWords();
  }

  Future<void> toggleFavorite(Word word) async {
    final updated = word.copyWith(isFavorite: !word.isFavorite);
    await updateWord(updated);
  }

  Future<void> updateLastAccessed(Word word) async {
    final updated = word.copyWith(lastAccessed: DateTime.now());
    await _db.updateWord(updated);
  }

  // Example operations
  Future<List<Example>> getExamplesByWord(String wordId) async {
    return await _db.getExamplesByWord(wordId);
  }

  Future<void> createExample({
    required String wordId,
    required String chineseSentence,
    required String pinyinSentence,
    required String russianTranslation,
  }) async {
    final example = Example(
      id: _uuid.v4(),
      chineseSentence: chineseSentence,
      pinyinSentence: PinyinHelper.numberedToToneMarks(pinyinSentence),
      russianTranslation: russianTranslation,
      createdAt: DateTime.now(),
      wordId: wordId,
    );
    await _db.insertExample(example);
    notifyListeners();
  }

  Future<void> updateExample(Example example) async {
    await _db.updateExample(example);
    notifyListeners();
  }

  Future<void> deleteExample(String id) async {
    await _db.deleteExample(id);
    notifyListeners();
  }

  // Search
  void setSearchQuery(String query) {
    _searchQuery = query;
    performSearch(query);
  }

  void performSearch(String query) {
    if (query.isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }

    final normalizedQuery = PinyinHelper.normalizeForSearch(query);
    
    _searchResults = _allWords.where((word) {
      final normalizedChinese = word.chinese.toLowerCase();
      final normalizedPinyin = PinyinHelper.normalizeForSearch(word.pinyin);
      final normalizedRussian = word.russian.toLowerCase();
      
      return normalizedChinese.contains(normalizedQuery) ||
          normalizedPinyin.contains(normalizedQuery) ||
          normalizedRussian.contains(normalizedQuery);
    }).toList();
    
    notifyListeners();
  }

  // Sample data
  Future<void> createSampleData() async {
    // Create default dictionary
    final dictId = _uuid.v4();
    final dictionary = Dictionary(
      id: dictId,
      name: 'Основной словарь',
      description: 'Основной китайско-русский словарь',
      createdAt: DateTime.now(),
      color: 'cyan',
      isActive: true,
    );
    await _db.insertDictionary(dictionary);

    // Add sample words
    final sampleWords = [
      {'chinese': '你好', 'pinyin': 'nǐ hǎo', 'russian': 'Привет', 'hsk': 1},
      {'chinese': '谢谢', 'pinyin': 'xièxie', 'russian': 'Спасибо', 'hsk': 1},
      {'chinese': '再见', 'pinyin': 'zàijiàn', 'russian': 'До свидания', 'hsk': 1},
      {'chinese': '学习', 'pinyin': 'xuéxí', 'russian': 'Учиться', 'hsk': 2},
      {'chinese': '汉语', 'pinyin': 'hànyǔ', 'russian': 'Китайский язык', 'hsk': 3},
    ];

    for (var wordData in sampleWords) {
      final wordId = _uuid.v4();
      final word = Word(
        id: wordId,
        chinese: wordData['chinese'] as String,
        pinyin: wordData['pinyin'] as String,
        russian: wordData['russian'] as String,
        createdAt: DateTime.now(),
        dictionaryId: dictId,
        hskLevel: wordData['hsk'] as int,
      );
      await _db.insertWord(word);

      // Add example for first word
      if (wordData['chinese'] == '你好') {
        final example = Example(
          id: _uuid.v4(),
          chineseSentence: '你好，我是学生。',
          pinyinSentence: 'Nǐ hǎo, wǒ shì xuésheng.',
          russianTranslation: 'Привет, я студент.',
          createdAt: DateTime.now(),
          wordId: wordId,
        );
        await _db.insertExample(example);
      }
    }

    await loadDictionaries();
    await loadAllWords();
  }
}
