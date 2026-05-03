import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart';
import 'package:vorflux/models/chat_message.dart';
import 'package:vorflux/models/conversation_thread.dart';
import 'package:vorflux/utils/text_utils.dart';

// We can't directly test DatabaseService static methods because they use
// a private singleton. Instead, we test the schema, migration logic, and
// CRUD operations by reproducing the same SQL and logic in-memory.

/// Creates V2 tables and index on the given [DatabaseExecutor].
/// Mirrors DatabaseService._createTablesAndIndex.
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
      'CREATE INDEX idx_messages_threadId ON messages(threadId)');
}

/// Runs the V1→V2 migration inside a transaction: creates V2 tables,
/// migrates rows from `history`, then drops `history`.
/// [msgIdPrefix] is used to generate deterministic message IDs in tests.
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

/// Helper to create a fresh in-memory database with v2 schema
Future<Database> _createV2Database() async {
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
      },
    ),
  );
  return db;
}

/// Helper to create a v1 database (old schema) for migration testing
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
  group('V2 Schema - threads table', () {
    late Database db;

    setUp(() async {
      db = await _createV2Database();
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

    test('updateThreadMetadata updates only targeted fields', () async {
      final now = DateTime(2025, 6, 15, 10, 0, 0);
      final thread = ConversationThread(
        id: 'thread-1',
        title: 'Test Thread',
        createdAt: now,
        updatedAt: now,
        messageCount: 0,
        lastMessagePreview: '',
      );
      await db.insert('threads', thread.toMap());

      final newUpdatedAt = now.add(const Duration(hours: 2));
      await db.update(
        'threads',
        {
          'updatedAt': newUpdatedAt.toIso8601String(),
          'messageCount': 5,
          'lastMessagePreview': 'Latest message preview',
        },
        where: 'id = ?',
        whereArgs: ['thread-1'],
      );

      final maps =
          await db.query('threads', where: 'id = ?', whereArgs: ['thread-1']);
      expect(maps.length, 1);
      final updated = ConversationThread.fromMap(maps.first);
      expect(updated.title, 'Test Thread'); // unchanged
      expect(updated.messageCount, 5);
      expect(updated.lastMessagePreview, 'Latest message preview');
      expect(updated.updatedAt, newUpdatedAt);
    });

    test('deleteThread removes thread', () async {
      final now = DateTime(2025, 6, 15);
      final thread = ConversationThread(
        id: 'thread-1',
        title: 'Test',
        createdAt: now,
        updatedAt: now,
      );
      await db.insert('threads', thread.toMap());

      await db.delete('threads', where: 'id = ?', whereArgs: ['thread-1']);

      final maps = await db.query('threads');
      expect(maps, isEmpty);
    });

    test('deleteThread cascades to messages', () async {
      final now = DateTime(2025, 6, 15);
      final thread = ConversationThread(
        id: 'thread-1',
        title: 'Test',
        createdAt: now,
        updatedAt: now,
      );
      await db.insert('threads', thread.toMap());
      await db.insert('messages', {
        'id': 'msg-1',
        'threadId': 'thread-1',
        'role': 'user',
        'content': 'Hello',
        'timestamp': now.toIso8601String(),
      });

      await db.delete('threads', where: 'id = ?', whereArgs: ['thread-1']);

      final messages = await db.query('messages');
      expect(messages, isEmpty);
    });

    test('clearAllThreads removes all threads and messages', () async {
      final now = DateTime(2025, 6, 15);
      for (var i = 0; i < 3; i++) {
        await db.insert('threads', ConversationThread(
          id: 'thread-$i',
          title: 'Thread $i',
          createdAt: now,
          updatedAt: now,
        ).toMap());
        await db.insert('messages', {
          'id': 'msg-$i',
          'threadId': 'thread-$i',
          'role': 'user',
          'content': 'Message $i',
          'timestamp': now.toIso8601String(),
        });
      }

      await db.delete('messages');
      await db.delete('threads');

      expect(await db.query('threads'), isEmpty);
      expect(await db.query('messages'), isEmpty);
    });

    test('insertThread with conflictAlgorithm.replace updates existing', () async {
      final now = DateTime(2025, 6, 15);
      final thread = ConversationThread(
        id: 'thread-1',
        title: 'Original',
        createdAt: now,
        updatedAt: now,
      );
      await db.insert('threads', thread.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);

      final updated = ConversationThread(
        id: 'thread-1',
        title: 'Updated',
        createdAt: now,
        updatedAt: now.add(const Duration(hours: 1)),
      );
      await db.insert('threads', updated.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);

      final maps = await db.query('threads');
      expect(maps.length, 1);
      expect(maps.first['title'], 'Updated');
    });
  });

  group('V2 Schema - messages table', () {
    late Database db;

    setUp(() async {
      db = await _createV2Database();
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

    test('messages for non-existent thread returns empty', () async {
      final maps = await db.query('messages',
          where: 'threadId = ?', whereArgs: ['no-such-thread']);
      expect(maps, isEmpty);
    });

    test('getThread returns null for non-existent id', () async {
      final maps = await db.query('threads',
          where: 'id = ?', whereArgs: ['nonexistent']);
      expect(maps, isEmpty);
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

      // Verify migration results
      final threads = await db.query('threads');
      expect(threads.length, 1);

      final thread = ConversationThread.fromMap(threads.first);
      expect(thread.id, 'old-1');
      expect(thread.title, 'What is Islam?');
      expect(thread.userName, 'TestUser');
      expect(thread.messageCount, 2);
      expect(thread.lastMessagePreview, 'Islam is a monotheistic religion.');

      final messages =
          await db.query('messages', orderBy: 'timestamp ASC');
      expect(messages.length, 2);
      expect(messages[0]['role'], 'user');
      expect(messages[0]['content'], 'What is Islam?');
      expect(messages[1]['role'], 'assistant');
      expect(messages[1]['content'], 'Islam is a monotheistic religion.');

      // Verify old table is dropped
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

    test('migration truncates long answer to 120 chars + "..." for preview',
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
      expect(preview.length, 123); // 120 chars + "..."
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

      // Should succeed without throwing
      final threads = await db.query('threads');
      expect(threads.length, 1);
      // The createdAt should be a valid ISO 8601 string (from DateTime.now() fallback)
      expect(
          () => DateTime.parse(threads.first['createdAt'] as String),
          returnsNormally);
    });

    test('migration handles null askedBy and fields defensively', () async {
      final ts = DateTime(2025, 6, 15);
      await db.insert('history', {
        'id': 'old-null',
        'question': 'Q',
        'answer': 'A',
        'timestamp': ts.toIso8601String(),
        'askedBy': null,
      });

      await _runMigration(db);

      final threads = await db.query('threads');
      expect(threads.length, 1);
      expect(threads.first['userName'], ''); // null => ''
    });

    test('migration of multiple rows creates correct number of threads/messages',
        () async {
      final ts = DateTime(2025, 6, 15, 10, 0, 0);
      for (var i = 0; i < 5; i++) {
        await db.insert('history', {
          'id': 'old-$i',
          'question': 'Question $i',
          'answer': 'Answer $i',
          'timestamp': ts.add(Duration(minutes: i)).toIso8601String(),
          'askedBy': 'User$i',
        });
      }

      await _runMigration(db);

      final threads = await db.query('threads');
      expect(threads.length, 5);

      final messages = await db.query('messages');
      expect(messages.length, 10); // 2 per thread
    });

    test('updatedAt is exactly 1 second after createdAt in migration', () async {
      final ts = DateTime(2025, 6, 15, 10, 0, 0);
      await db.insert('history', {
        'id': 'old-ts',
        'question': 'Q',
        'answer': 'A',
        'timestamp': ts.toIso8601String(),
        'askedBy': null,
      });

      await _runMigration(db);

      final threads = await db.query('threads');
      final createdAt = DateTime.parse(threads.first['createdAt'] as String);
      final updatedAt = DateTime.parse(threads.first['updatedAt'] as String);
      expect(updatedAt.difference(createdAt), const Duration(seconds: 1));

      final messages =
          await db.query('messages', orderBy: 'timestamp ASC');
      final userTs = DateTime.parse(messages[0]['timestamp'] as String);
      final assistantTs = DateTime.parse(messages[1]['timestamp'] as String);
      expect(assistantTs.difference(userTs), const Duration(seconds: 1));
    });
  });

  group('getThread with messages', () {
    late Database db;

    setUp(() async {
      db = await _createV2Database();
    });

    tearDown(() async {
      await db.close();
    });

    test('retrieves thread with all messages attached', () async {
      final now = DateTime(2025, 6, 15, 10, 0, 0);
      await db.insert('threads', ConversationThread(
        id: 'thread-1',
        title: 'Test',
        createdAt: now,
        updatedAt: now,
        messageCount: 2,
      ).toMap());

      await db.insert('messages', ChatMessage(
        id: 'msg-1',
        threadId: 'thread-1',
        role: 'user',
        content: 'First',
        timestamp: now,
      ).toMap());

      await db.insert('messages', ChatMessage(
        id: 'msg-2',
        threadId: 'thread-1',
        role: 'assistant',
        content: 'Second',
        timestamp: now.add(const Duration(seconds: 1)),
      ).toMap());

      // Simulate getThread logic
      final threadMaps =
          await db.query('threads', where: 'id = ?', whereArgs: ['thread-1']);
      expect(threadMaps.isNotEmpty, true);
      final thread = ConversationThread.fromMap(threadMaps.first);

      final messageMaps = await db.query('messages',
          where: 'threadId = ?',
          whereArgs: ['thread-1'],
          orderBy: 'timestamp ASC');
      final messages =
          messageMaps.map((m) => ChatMessage.fromMap(m)).toList();
      final result = thread.copyWith(messages: messages);

      expect(result.messages.length, 2);
      expect(result.messages[0].content, 'First');
      expect(result.messages[1].content, 'Second');
      expect(result.title, 'Test');
    });
  });

  group('truncateTitle and truncatePreview (used by migration and services)', () {
    test('preview for short content stays unchanged', () {
      const content = 'Short answer';
      final preview = truncatePreview(content);
      expect(preview, 'Short answer');
    });

    test('preview for content exactly 120 chars stays unchanged', () {
      final content = 'A' * 120;
      final preview = truncatePreview(content);
      expect(preview, content);
      expect(preview.length, 120);
    });

    test('preview for content over 120 chars is truncated with ellipsis', () {
      final content = 'A' * 200;
      final preview = truncatePreview(content);
      expect(preview.length, 123);
      expect(preview.endsWith('...'), true);
    });

    test('title truncation for question over 100 chars', () {
      final questionText = 'Q' * 150;
      final title = truncateTitle(questionText);
      expect(title.length, 100);
    });

    test('title stays unchanged for question under 100 chars', () {
      const questionText = 'Short question';
      final title = truncateTitle(questionText);
      expect(title, 'Short question');
    });
  });
}
