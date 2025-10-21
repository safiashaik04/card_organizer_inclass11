import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {
  static const _databaseName = "CardOrganizer.db";
  static const _databaseVersion = 1;

  static const tableFolders = 'folders';
  static const tableCards = 'cards';

  static Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = join(directory.path, _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  Future _onCreate(Database db, int version) async {
  // Create folders table
  await db.execute('''
    CREATE TABLE $tableFolders (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      created_at TEXT
    )
  ''');

  // Create cards table
  await db.execute('''
    CREATE TABLE $tableCards (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      suit TEXT NOT NULL,
      imageUrl TEXT,
      folderId INTEGER,
      FOREIGN KEY (folderId) REFERENCES $tableFolders (id)
    )
  ''');

  // Prepopulate folders and one card per folder
  final suits = ['Hearts', 'Spades', 'Diamonds', 'Clubs'];
  for (var suit in suits) {
    final folderId = await db.insert(tableFolders, {
      'name': suit,
      'created_at': DateTime.now().toIso8601String(),
    });

    await db.insert(tableCards, {
      'name': '$suit Card 1',
      'suit': suit,
      'imageUrl': imageForSuit(suit),  // <-- assign a valid image URL
      'folderId': folderId,
    });
  }
}

// Add this helper function inside database_helper.dart
String imageForSuit(String suit) {
  switch (suit) {
    case 'Hearts':
      return 'https://deckofcardsapi.com/static/img/AH.png';
    case 'Spades':
      return 'https://deckofcardsapi.com/static/img/AS.png';
    case 'Diamonds':
      return 'https://deckofcardsapi.com/static/img/AD.png';
    case 'Clubs':
      return 'https://deckofcardsapi.com/static/img/AC.png';
    default:
      return 'https://deckofcardsapi.com/static/img/back.png';
  }
}

Future<int> getMaxCardNumberInFolder(int folderId) async {
  final db = await database;
  final result = await db.rawQuery(
    'SELECT MAX(CAST(SUBSTR(name, 6) AS INTEGER)) as maxNumber FROM $tableCards WHERE folderId = ?',
    [folderId],
  );
  return result.first['maxNumber'] != null ? result.first['maxNumber'] as int : 0;
}



  // ---------------- CRUD for Folders ----------------
  Future<List<Map<String, dynamic>>> getAllFolders() async {
    final db = await database;
    return await db.query(tableFolders);
  }

  // ---------------- CRUD for Cards ----------------
  Future<List<Map<String, dynamic>>> getCardsByFolder(int folderId) async {
    final db = await database;
    return await db.query(
      tableCards,
      where: 'folderId = ?',
      whereArgs: [folderId],
    );
  }

  Future<int> insertCard(Map<String, dynamic> row) async {
    final db = await database;
    return await db.insert(tableCards, row);
  }

  Future<int> deleteCard(int id) async {
    final db = await database;
    return await db.delete(tableCards, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> updateCard(Map<String, dynamic> row) async {
    final db = await database;
    return await db.update(
      tableCards,
      row,
      where: 'id = ?',
      whereArgs: [row['id']],
    );
  }

  Future<int> getCardCountInFolder(int folderId) async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) FROM $tableCards WHERE folderId = ?', [folderId]);
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
