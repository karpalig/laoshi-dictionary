import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../models/dictionary.dart';
import '../models/word.dart';
import '../models/example.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('dictionary.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await _getDBPath();
    final path = join(dbPath, filePath);
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<String> _getDBPath() async {
    if (Platform.isWindows || Platform.isLinux) {
      final directory = await getApplicationDocumentsDirectory();
      final dbDirectory = Directory(join(directory.path, 'ChineseRussianDictionary'));
      if (!await dbDirectory.exists()) {
        await dbDirectory.create(recursive: true);
      }
      return dbDirectory.path;
    } else {
      return await getDatabasesPath();
    }
  }

  Future<void> _createDB(Database db, int version) async {
    // Dictionaries table
    await db.execute('''
      CREATE TABLE dictionaries (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        isActive INTEGER NOT NULL DEFAULT 1,
        createdAt TEXT NOT NULL,
        color TEXT NOT NULL
      )
    ''');

    // Words table
    await db.execute('''
      CREATE TABLE words (
        id TEXT PRIMARY KEY,
        chinese TEXT NOT NULL,
        pinyin TEXT NOT NULL,
        russian TEXT NOT NULL,
        isFavorite INTEGER NOT NULL DEFAULT 0,
        createdAt TEXT NOT NULL,
        lastAccessed TEXT,
        hskLevel INTEGER NOT NULL DEFAULT 0,
        dictionaryId TEXT NOT NULL,
        FOREIGN KEY (dictionaryId) REFERENCES dictionaries (id) ON DELETE CASCADE
      )
    ''');

    // Examples table
    await db.execute('''
      CREATE TABLE examples (
        id TEXT PRIMARY KEY,
        chineseSentence TEXT NOT NULL,
        pinyinSentence TEXT NOT NULL,
        russianTranslation TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        wordId TEXT NOT NULL,
        FOREIGN KEY (wordId) REFERENCES words (id) ON DELETE CASCADE
      )
    ''');

    // Indexes for better search performance
    await db.execute('CREATE INDEX idx_words_dictionary ON words(dictionaryId)');
    await db.execute('CREATE INDEX idx_words_favorite ON words(isFavorite)');
    await db.execute('CREATE INDEX idx_examples_word ON examples(wordId)');
  }

  // CRUD Operations for Dictionaries
  Future<void> insertDictionary(Dictionary dictionary) async {
    final db = await database;
    await db.insert('dictionaries', dictionary.toMap());
  }

  Future<List<Dictionary>> getAllDictionaries() async {
    final db = await database;
    final result = await db.query('dictionaries', orderBy: 'createdAt DESC');
    return result.map((map) => Dictionary.fromMap(map)).toList();
  }

  Future<void> updateDictionary(Dictionary dictionary) async {
    final db = await database;
    await db.update(
      'dictionaries',
      dictionary.toMap(),
      where: 'id = ?',
      whereArgs: [dictionary.id],
    );
  }

  Future<void> deleteDictionary(String id) async {
    final db = await database;
    await db.delete('dictionaries', where: 'id = ?', whereArgs: [id]);
  }

  // CRUD Operations for Words
  Future<void> insertWord(Word word) async {
    final db = await database;
    await db.insert('words', word.toMap());
  }

  Future<List<Word>> getAllWords() async {
    final db = await database;
    final result = await db.query('words', orderBy: 'createdAt DESC');
    return result.map((map) => Word.fromMap(map)).toList();
  }

  Future<List<Word>> getWordsByDictionary(String dictionaryId) async {
    final db = await database;
    final result = await db.query(
      'words',
      where: 'dictionaryId = ?',
      whereArgs: [dictionaryId],
      orderBy: 'createdAt DESC',
    );
    return result.map((map) => Word.fromMap(map)).toList();
  }

  Future<List<Word>> getFavoriteWords() async {
    final db = await database;
    final result = await db.query(
      'words',
      where: 'isFavorite = ?',
      whereArgs: [1],
      orderBy: 'createdAt DESC',
    );
    return result.map((map) => Word.fromMap(map)).toList();
  }

  Future<void> updateWord(Word word) async {
    final db = await database;
    await db.update(
      'words',
      word.toMap(),
      where: 'id = ?',
      whereArgs: [word.id],
    );
  }

  Future<void> deleteWord(String id) async {
    final db = await database;
    await db.delete('words', where: 'id = ?', whereArgs: [id]);
  }

  // CRUD Operations for Examples
  Future<void> insertExample(Example example) async {
    final db = await database;
    await db.insert('examples', example.toMap());
  }

  Future<List<Example>> getExamplesByWord(String wordId) async {
    final db = await database;
    final result = await db.query(
      'examples',
      where: 'wordId = ?',
      whereArgs: [wordId],
      orderBy: 'createdAt ASC',
    );
    return result.map((map) => Example.fromMap(map)).toList();
  }

  Future<void> updateExample(Example example) async {
    final db = await database;
    await db.update(
      'examples',
      example.toMap(),
      where: 'id = ?',
      whereArgs: [example.id],
    );
  }

  Future<void> deleteExample(String id) async {
    final db = await database;
    await db.delete('examples', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
