import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:vorflux/models/chat_message.dart';
import 'package:vorflux/models/conversation_thread.dart';
import 'package:vorflux/utils/text_utils.dart';

Future<void> _createTablesAndIndex(DatabaseExecutor db) async {
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

Future<void> _createBookmarksTable(DatabaseExecutor db) async {
  await db.execute('''
    CREATE TABLE bookmarks (
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
  ''');
}

Future<void> _runMigration(Database db, {String msgIdPrefix = 'test-msg'}) async {
  await db.transaction((txn) async {
    await _createTablesAndIndex(txn);
    final rows = await txn.query('history');
    var msgCounter = 0;

    for (final row in rows) {
      final oldId = (row['id'] as String?) ?? 'fallback-id';
      final question = (row['question'] as String?) ?? '';
      final answer = (row['answer'] as String?) ?? '';
      final askedBy = (row['askedBy'] as String?) ?? '';

      DateTime createdAt;
      try {
        createdAt = DateTime.parse(row['timestamp'] as String);
      } catch (_) {
        createdAt = DateTime.now();
      }
      final updatedAt = createdAt.add(const Duration(seconds: 1));

      final title = truncateTitle(question);
      final preview = truncatePreview(answer);

      await txn.insert('threads', {
        'id': oldId,
        'title': title,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'userId': null,
        'userName': askedBy,
        'userPhotoURL': null,
        'messageCount': 2,
        'lastMessagePreview': preview,
      });

      await txn.insert('messages', {
        'id': '$msgIdPrefix-${msgCounter++}',
        'threadId': oldId,
        'role': 'user',
        'content': question,
        'timestamp': createdAt.toIso8601String(),
      });

      await txn.insert('messages', {
        'id': '$msgIdPrefix-${msgCounter++}',
        'threadId': oldId,
        'role': 'assistant',
        'content': answer,
        'timestamp': updatedAt.toIso8601String(),
      });
    }

    await txn.execute('DROP TABLE history');
  });
}

Future<Database> _createV3Database() async {
  sqfliteFfiInit();
  final db = await databaseFactoryFfi.openDatabase(
    inMemoryDatabasePath,
    options: OpenDatabaseOptions(
      version: 1,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await _createTablesAndIndex(db);
        await _createBookmarksTable(db);
      },
    ),
  );
  return db;
}

Future<Database> _createV1Database() async {
  sqfliteFfiInit();
  final db = await databaseFactoryFfi.openDatabase(
    inMemoryDatabasePath,
    options: OpenDatabaseOptions(
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE history (
            id TEXT PRIMARY KEY,
            question TEXT NOT NULL,
            answer TEXT NOT NULL,
            timestamp TEXT NOT NULL,
            askedBy TEXT
          )
        ''');
      },
    ),
  );
  return db;
}

void main() {
  group('V3 Schema - threads table', () {
    late Database db;

    setUp(() async {
      db = await _createV3Database();
    });

    tearDown(() async {
      await db.close();
    });

    test('insert and retrieve a thread', () async {
      final now = DateTime(2025, 6, 15, 10, 0, 0);
      final thread = ConversationThread(
        id: 'thread-1',
        title: 'Test Thread',
        createdAt: now,
        updatedAt: now,
        userId: 'user-1',
        userName: 'Alice',
        userPhotoURL: 'https://example.com/photo.jpg',
        messageCount: 0,
        lastMessagePreview: '',
      );

      await db.insert('threads', thread.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);

      final maps = await db.query('threads');
      expect(maps.length, 1);
      final restored = ConversationThread.fromMap(maps.first);
      expect(restored.id, 'thread-1');
      expect(restored.title, 'Test Thread');
      expect(restored.userId, 'user-1');
      expect(restored.userName, 'Alice');
      expect(restored.messageCount, 0);
    });

    test('getAllThreads returns threads ordered by updatedAt DESC', () async {
      final now = DateTime(2025, 6, 15, 10, 0, 0);
      final older = ConversationThread(
        id: 'thread-old',
        title: 'Older Thread',
        createdAt: now,
        updatedAt: now,
      );
      final newer = ConversationThread(
        id: 'thread-new',
        title: 'Newer Thread',
        createdAt: now,
        updatedAt: now.add(const Duration(hours: 1)),
      );

      await db.insert('threads', older.toMap());
      await db.insert('threads', newer.toMap());

      final maps = await db.query('threads', orderBy: 'updatedAt DESC');
      expect(maps.length, 2);
      expect(maps[0]['id'], 'thread-new');
      expect(maps[1]['id'], 'thread-old');
    });

    test('bookmarks table exists in fresh schema', () async {
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='bookmarks'",
      );
      expect(tables.length, 1);
    });

    test('insert and retrieve bookmark snapshot', () async {
      final now = DateTime(2025, 6, 15, 10, 0, 0);
      final thread = ConversationThread(
        id: 'thread-bookmark',
        title: 'Saved thread',
        createdAt: now,
        updatedAt: now,
        userName: 'Aisha',
        messageCount: 3,
        lastMessagePreview: 'Latest saved message',
      );

      await db.insert('bookmarks', {
        ...thread.toMap(),
        'bookmarkedAt': now.toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      final maps = await db.query('bookmarks');
      expect(maps.length, 1);
      final restored = ConversationThread.fromMap(maps.first);
      expect(restored.id, thread.id);
      expect(restored.title, thread.title);
      expect(restored.lastMessagePreview, thread.lastMessagePreview);
    });
  });

  group('V3 Schema - messages table', () {
    late Database db;

    setUp(() async {
      db = await _createV3Database();
    });

    tearDown(() async {
      await db.close();
    });

    test('insert and retrieve messages for a thread', () async {
      final now = DateTime(2025, 6, 15, 10, 0, 0);
      await db.insert('threads', ConversationThread(
        id: 'thread-1',
        title: 'Test',
        createdAt: now,
        updatedAt: now,
      ).toMap());

      final msg1 = ChatMessage(
        id: 'msg-1',
        threadId: 'thread-1',
        role: 'user',
        content: 'Hello',
        timestamp: now,
      );
      final msg2 = ChatMessage(
        id: 'msg-2',
        threadId: 'thread-1',
        role: 'assistant',
        content: 'Hi there!',
        timestamp: now.add(const Duration(seconds: 1)),
      );

      await db.insert('messages', msg1.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
      await db.insert('messages', msg2.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);

      final maps = await db.query('messages',
          where: 'threadId = ?',
          whereArgs: ['thread-1'],
          orderBy: 'timestamp ASC');
      expect(maps.length, 2);

      final messages = maps.map((m) => ChatMessage.fromMap(m)).toList();
      expect(messages[0].id, 'msg-1');
      expect(messages[0].role, 'user');
      expect(messages[1].id, 'msg-2');
      expect(messages[1].role, 'assistant');
    });
  });

  group('V1 to V2 migration logic', () {
    late Database db;

    setUp(() async {
      db = await _createV1Database();
    });

    tearDown(() async {
      await db.close();
    });

    test('migrates single history row to thread + 2 messages', () async {
      final ts = DateTime(2025, 6, 15, 10, 0, 0);
      await db.insert('history', {
        'id': 'old-1',
        'question': 'What is Islam?',
        'answer': 'Islam is a monotheistic religion.',
        'timestamp': ts.toIso8601String(),
        'askedBy': 'TestUser',
      });

      await _runMigration(db);
      await _createBookmarksTable(db);

      final threads = await db.query('threads');
      expect(threads.length, 1);

      final thread = ConversationThread.fromMap(threads.first);
      expect(thread.id, 'old-1');
      expect(thread.title, 'What is Islam?');
      expect(thread.userName, 'TestUser');
      expect(thread.messageCount, 2);
      expect(thread.lastMessagePreview, 'Islam is a monotheistic religion.');

      final messages = await db.query('messages', orderBy: 'timestamp ASC');
      expect(messages.length, 2);
      expect(messages[0]['role'], 'user');
      expect(messages[0]['content'], 'What is Islam?');
      expect(messages[1]['role'], 'assistant');
      expect(messages[1]['content'], 'Islam is a monotheistic religion.');

      final tables = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='history'");
      expect(tables, isEmpty);
    });

    test('migration truncates long question to 100 chars for title', () async {
      final longQuestion = 'A' * 200;
      final ts = DateTime(2025, 6, 15, 10, 0, 0);
      await db.insert('history', {
        'id': 'old-long',
        'question': longQuestion,
        'answer': 'Short answer',
        'timestamp': ts.toIso8601String(),
        'askedBy': null,
      });

      await _runMigration(db);

      final threads = await db.query('threads');
      expect(threads.first['title'], 'A' * 100);
    });

    test('migration truncates long answer to 120 chars + ellipsis for preview',
        () async {
      final longAnswer = 'B' * 200;
      final ts = DateTime(2025, 6, 15, 10, 0, 0);
      await db.insert('history', {
        'id': 'old-long-ans',
        'question': 'Question',
        'answer': longAnswer,
        'timestamp': ts.toIso8601String(),
        'askedBy': null,
      });

      await _runMigration(db);

      final threads = await db.query('threads');
      final preview = threads.first['lastMessagePreview'] as String;
      expect(preview.length, 123);
      expect(preview.endsWith('...'), true);
      expect(preview.startsWith('B' * 120), true);
    });

    test('migration handles malformed timestamp defensively', () async {
      await db.insert('history', {
        'id': 'old-bad-ts',
        'question': 'Question',
        'answer': 'Answer',
        'timestamp': 'not-a-date',
        'askedBy': null,
      });

      await _runMigration(db);

      final threads = await db.query('threads');
      expect(threads.length, 1);
      expect(
        () => DateTime.parse(threads.first['createdAt'] as String),
        returnsNormally,
      );
    });
  });
}
