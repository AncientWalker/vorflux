import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:vorflux/models/qa_entry.dart';

class DatabaseService {
  static Database? _database;
  static const String _tableName = 'history';

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'vorflux.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_tableName (
            id TEXT PRIMARY KEY,
            question TEXT NOT NULL,
            answer TEXT NOT NULL,
            timestamp TEXT NOT NULL,
            askedBy TEXT
          )
        ''');
      },
    );
  }

  static Future<void> insertEntry(QAEntry entry) async {
    final db = await database;
    await db.insert(
      _tableName,
      entry.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<QAEntry>> getAllEntries() async {
    final db = await database;
    final maps = await db.query(
      _tableName,
      orderBy: 'timestamp DESC',
    );
    return maps.map((map) => QAEntry.fromMap(map)).toList();
  }

  static Future<void> deleteEntry(String id) async {
    final db = await database;
    await db.delete(_tableName, where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> clearAll() async {
    final db = await database;
    await db.delete(_tableName);
  }
}
