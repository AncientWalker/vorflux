import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import 'package:vorflux/models/chat_message.dart';
import 'package:vorflux/models/conversation_thread.dart';
import 'package:vorflux/utils/text_utils.dart';

class DatabaseService {
  static Database? _database;
  static const String _bookmarksTable = 'bookmarks';

  static const String _createBookmarksTableSql = '''
    CREATE TABLE $_bookmarksTable (
      id TEXT PRIMARY KEY,
      title TEXT NOT NULL,
      createdAt TEXT NOT NULL,
      updatedAt TEXT NOT NULL,
      userId TEXT,
      userName TEXT,
      userPhotoURL TEXT,
      messageCount INTEGER NOT NULL DEFAULT 0,
      lastMessagePreview TEXT NOT NULL DEFAULT '',
      bookmarkedAt TEXT NOT NULL
    )
  ''';

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'vorflux.db');

    return openDatabase(
      path,
      version: 3,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await _createV3Schema(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _migrateV1ToV2(db);
        }
        if (oldVersion < 3) {
          await db.execute(_createBookmarksTableSql);
        }
      },
    );
  }

  static Future<void> _createV3Schema(DatabaseExecutor db) async {
    await _createTablesAndIndex(db);
    await db.execute(_createBookmarksTableSql);
  }

  static Future<void> _createTablesAndIndex(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE threads (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        userId TEXT,
        userName TEXT,
        userPhotoURL TEXT,
        messageCount INTEGER NOT NULL DEFAULT 0,
        lastMessagePreview TEXT NOT NULL DEFAULT ''
      )
    ''');

    await db.execute('''
      CREATE TABLE messages (
        id TEXT PRIMARY KEY,
        threadId TEXT NOT NULL,
        role TEXT NOT NULL,
        content TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        FOREIGN KEY (threadId) REFERENCES threads(id) ON DELETE CASCADE
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_messages_threadId ON messages(threadId)',
    );
  }

  static Future<void> _migrateV1ToV2(Database db) async {
    const uuid = Uuid();

    await db.transaction((txn) async {
      await _createTablesAndIndex(txn);
      final rows = await txn.query('history');

      for (final row in rows) {
        final oldId = (row['id'] as String?) ?? uuid.v4();
        final question = (row['question'] as String?) ?? '';
        final answer = (row['answer'] as String?) ?? '';
        final askedBy = (row['askedBy'] as String?) ?? '';
        final timestampStr = row['timestamp'] as String?;

        DateTime createdAt;
        try {
          createdAt = DateTime.parse(timestampStr!);
        } catch (_) {
          createdAt = DateTime.now();
        }

        final updatedAt = createdAt.add(const Duration(seconds: 1));

        await txn.insert('threads', {
          'id': oldId,
          'title': truncateTitle(question),
          'createdAt': createdAt.toIso8601String(),
          'updatedAt': updatedAt.toIso8601String(),
          'userId': null,
          'userName': askedBy,
          'userPhotoURL': null,
          'messageCount': 2,
          'lastMessagePreview': truncatePreview(answer),
        });

        await txn.insert('messages', {
          'id': uuid.v4(),
          'threadId': oldId,
          'role': 'user',
          'content': question,
          'timestamp': createdAt.toIso8601String(),
        });

        await txn.insert('messages', {
          'id': uuid.v4(),
          'threadId': oldId,
          'role': 'assistant',
          'content': answer,
          'timestamp': updatedAt.toIso8601String(),
        });
      }

      await txn.execute('DROP TABLE history');
    });
  }

  static Future<void> insertThread(ConversationThread thread) async {
    final db = await database;
    await db.insert(
      'threads',
      thread.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<void> updateThreadMetadata({
    required String threadId,
    required DateTime updatedAt,
    required int messageCount,
    required String lastMessagePreview,
  }) async {
    final db = await database;
    await db.update(
      'threads',
      {
        'updatedAt': updatedAt.toIso8601String(),
        'messageCount': messageCount,
        'lastMessagePreview': lastMessagePreview,
      },
      where: 'id = ?',
      whereArgs: [threadId],
    );
  }

  static Future<List<ConversationThread>> getAllThreads() async {
    final db = await database;
    final maps = await db.query('threads', orderBy: 'updatedAt DESC');
    return maps.map((map) => ConversationThread.fromMap(map)).toList();
  }

  static Future<ConversationThread?> getThread(String id) async {
    final db = await database;
    final threadMaps = await db.query(
      'threads',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (threadMaps.isEmpty) return null;

    final thread = ConversationThread.fromMap(threadMaps.first);
    final messageMaps = await db.query(
      'messages',
      where: 'threadId = ?',
      whereArgs: [id],
      orderBy: 'timestamp ASC',
    );
    final messages = messageMaps.map(ChatMessage.fromMap).toList();
    return thread.copyWith(messages: messages);
  }

  static Future<void> deleteThread(String id) async {
    final db = await database;
    await db.delete(_bookmarksTable, where: 'id = ?', whereArgs: [id]);
    await db.delete('threads', where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> clearAllThreads() async {
    final db = await database;
    await db.delete(_bookmarksTable);
    await db.delete('messages');
    await db.delete('threads');
  }

  static Future<void> insertMessage(ChatMessage message) async {
    final db = await database;
    await db.insert(
      'messages',
      message.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<ChatMessage>> getMessagesForThread(String threadId) async {
    final db = await database;
    final maps = await db.query(
      'messages',
      where: 'threadId = ?',
      whereArgs: [threadId],
      orderBy: 'timestamp ASC',
    );
    return maps.map(ChatMessage.fromMap).toList();
  }

  static Future<void> insertBookmark(ConversationThread thread) async {
    final db = await database;
    await db.insert(
      _bookmarksTable,
      {
        ...thread.copyWith(messages: const []).toMap(),
        'bookmarkedAt': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<void> removeBookmark(String threadId) async {
    final db = await database;
    await db.delete(_bookmarksTable, where: 'id = ?', whereArgs: [threadId]);
  }

  static Future<List<ConversationThread>> getAllBookmarks() async {
    final db = await database;
    final maps = await db.query(_bookmarksTable, orderBy: 'bookmarkedAt DESC');
    return maps.map((map) => ConversationThread.fromMap(map)).toList();
  }
}
