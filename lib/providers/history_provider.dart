import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:vorflux/models/chat_message.dart';
import 'package:vorflux/models/conversation_thread.dart';
import 'package:vorflux/providers/searchable_entries_mixin.dart';
import 'package:vorflux/services/database_service.dart';
import 'package:vorflux/services/firebase_config.dart';
import 'package:vorflux/services/firestore_service.dart';
import 'package:vorflux/services/openai_service.dart';
import 'package:vorflux/utils/text_utils.dart';

class HistoryProvider extends ChangeNotifier with SearchableEntriesMixin {
  List<ConversationThread> _threads = [];
  ConversationThread? _activeThread;
  bool _isLoading = false;
  bool _isSending = false;
  StreamSubscription? _subscription;
  String? _currentUserId;
  String _currentUserName = '';
  String _currentUserPhotoURL = '';

  List<ConversationThread> get threads => _threads;
  ConversationThread? get activeThread => _activeThread;

  @override
  List<ConversationThread> get entries => _threads;

  bool get isLoading => _isLoading;
  bool get isSending => _isSending;
  bool get isEmpty => _threads.isEmpty;

  @override
  @visibleForTesting
  set entriesForTesting(List<ConversationThread> entries) {
    _threads = entries;
  }

  @override
  List<String> searchableFields(ConversationThread entry) => [
        entry.title,
        entry.lastMessagePreview,
      ];

  void listenToUserThreads({
    required String userId,
    required String userName,
    required String userPhotoURL,
  }) {
    _currentUserId = userId;
    _currentUserName = userName;
    _currentUserPhotoURL = userPhotoURL;

    if (!FirebaseConfig.isAvailable) {
      Future.microtask(_loadFromLocalDb);
      return;
    }

    Future.microtask(() {
      FirestoreService.migrateLegacyQuestions(userId).then((_) {
        _startFirestoreListener(userId);
      }).catchError((e) {
        debugPrint('Legacy migration error (non-fatal): $e');
        _startFirestoreListener(userId);
      });
    });
  }

  void _startFirestoreListener(String userId) {
    _subscription?.cancel();
    _isLoading = true;
    notifyListeners();

    _subscription = FirestoreService.getUserThreads(userId).listen(
      (threads) {
        _threads = threads;
        _isLoading = false;
        notifyListeners();
      },
      onError: (e) {
        debugPrint('Error loading threads: $e');
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<void> _loadFromLocalDb() async {
    _isLoading = true;
    notifyListeners();

    try {
      _threads = await DatabaseService.getAllThreads();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading local threads: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  void startNewThread() {
    _activeThread = null;
    notifyListeners();
  }

  Future<void> openThread(String threadId) async {
    _activeThread = null;
    _isLoading = true;
    notifyListeners();

    try {
      if (!FirebaseConfig.isAvailable) {
        _activeThread = await DatabaseService.getThread(threadId);
      } else {
        final threadMeta = _threads.firstWhere((t) => t.id == threadId);
        final messages = await FirestoreService.getThreadMessages(threadId);
        _activeThread = threadMeta.copyWith(messages: messages);
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error opening thread: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> sendMessage(String question) async {
    _isSending = true;
    notifyListeners();

    try {
      final now = DateTime.now();
      final threadId = await _ensureThread(question, now);
      final conversationHistory = List<ChatMessage>.from(_activeThread!.messages);

      _showOptimisticUserMessage(threadId, question, now);

      final answer = await OpenAIService.askQuestion(
        question,
        conversationHistory: conversationHistory,
      );

      final answerTime = DateTime.now();
      final persistedMessages = await _persistMessages(
        threadId: threadId,
        question: question,
        answer: answer,
        questionTime: now,
        answerTime: answerTime,
        conversationHistory: conversationHistory,
      );
      final preview = truncatePreview(answer);

      _updateLocalThreadList(
        threadId: threadId,
        persistedMessages: persistedMessages,
        updatedAt: answerTime,
        preview: preview,
      );

      _isSending = false;
      notifyListeners();
    } catch (e) {
      await _rollbackOnFailure();
      _isSending = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<String> _ensureThread(String question, DateTime now) async {
    if (_activeThread != null) return _activeThread!.id;

    final title = truncateTitle(question);

    if (!FirebaseConfig.isAvailable) {
      final threadId = const Uuid().v4();
      final newThread = ConversationThread(
        id: threadId,
        title: title,
        createdAt: now,
        updatedAt: now,
        userId: _currentUserId,
        userName: _currentUserName,
        userPhotoURL: _currentUserPhotoURL,
        messages: const [],
        messageCount: 0,
        lastMessagePreview: '',
      );
      await DatabaseService.insertThread(newThread);
      _activeThread = newThread;
      return threadId;
    }

    final threadId = await FirestoreService.createThread(
      userId: _currentUserId ?? '',
      userName: _currentUserName,
      userPhotoURL: _currentUserPhotoURL,
      title: title,
    );
    _activeThread = ConversationThread(
      id: threadId,
      title: title,
      createdAt: now,
      updatedAt: now,
      userId: _currentUserId,
      userName: _currentUserName,
      userPhotoURL: _currentUserPhotoURL,
      messages: const [],
      messageCount: 0,
      lastMessagePreview: '',
    );
    return threadId;
  }

  void _showOptimisticUserMessage(String threadId, String question, DateTime now) {
    final tempUserMessage = ChatMessage(
      id: 'temp-user-${now.millisecondsSinceEpoch}',
      threadId: threadId,
      role: 'user',
      content: question,
      timestamp: now,
    );

    _activeThread = _activeThread!.copyWith(
      messages: [..._activeThread!.messages, tempUserMessage],
    );
    notifyListeners();
  }

  Future<List<ChatMessage>> _persistMessages({
    required String threadId,
    required String question,
    required String answer,
    required DateTime questionTime,
    required DateTime answerTime,
    required List<ChatMessage> conversationHistory,
  }) async {
    final userMessage = ChatMessage(
      id: const Uuid().v4(),
      threadId: threadId,
      role: 'user',
      content: question,
      timestamp: questionTime,
    );
    final assistantMessage = ChatMessage(
      id: const Uuid().v4(),
      threadId: threadId,
      role: 'assistant',
      content: answer,
      timestamp: answerTime,
    );

    final preview = truncatePreview(answer);
    final persistedMessages = List<ChatMessage>.from(conversationHistory)
      ..add(userMessage)
      ..add(assistantMessage);

    if (!FirebaseConfig.isAvailable) {
      await DatabaseService.insertMessage(userMessage);
      await DatabaseService.insertMessage(assistantMessage);
      await DatabaseService.updateThreadMetadata(
        threadId: threadId,
        updatedAt: answerTime,
        messageCount: persistedMessages.length,
        lastMessagePreview: preview,
      );
    } else {
      await FirestoreService.addMessage(
        threadId: threadId,
        role: 'user',
        content: question,
      );
      await FirestoreService.addMessage(
        threadId: threadId,
        role: 'assistant',
        content: answer,
      );
    }

    return persistedMessages;
  }

  void _updateLocalThreadList({
    required String threadId,
    required List<ChatMessage> persistedMessages,
    required DateTime updatedAt,
    required String preview,
  }) {
    _activeThread = _activeThread!.copyWith(
      messages: persistedMessages,
      updatedAt: updatedAt,
      messageCount: persistedMessages.length,
      lastMessagePreview: preview,
    );

    final threadIndex = _threads.indexWhere((t) => t.id == threadId);
    final updatedThreadMeta = _activeThread!.copyWith(messages: const []);

    if (threadIndex >= 0) {
      _threads[threadIndex] = updatedThreadMeta;
    } else {
      _threads.insert(0, updatedThreadMeta);
    }

    _threads.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  Future<void> _rollbackOnFailure() async {
    if (_activeThread != null && _activeThread!.messages.isNotEmpty) {
      final messages = List<ChatMessage>.from(_activeThread!.messages);
      if (messages.last.id.startsWith('temp-user-')) {
        messages.removeLast();
        _activeThread = _activeThread!.copyWith(messages: messages);
      }
    }

    if (_activeThread != null && _activeThread!.messages.isEmpty) {
      try {
        if (!FirebaseConfig.isAvailable) {
          await DatabaseService.deleteThread(_activeThread!.id);
        } else {
          await FirestoreService.deleteThread(_activeThread!.id);
        }
      } catch (_) {}
      _activeThread = null;
    }
  }

  Future<void> deleteThread(String id) async {
    final removedThread = _threads.cast<ConversationThread?>().firstWhere(
          (t) => t!.id == id,
          orElse: () => null,
        );

    _threads.removeWhere((t) => t.id == id);
    if (_activeThread?.id == id) _activeThread = null;
    notifyListeners();

    try {
      if (!FirebaseConfig.isAvailable) {
        await DatabaseService.deleteThread(id);
      } else {
        await FirestoreService.deleteThread(id);
      }
    } catch (e) {
      debugPrint('Error deleting thread: $e');
      if (removedThread != null) {
        _threads.add(removedThread);
        _threads.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        notifyListeners();
      }
      rethrow;
    }
  }

  Future<void> clearHistory() async {
    if (!FirebaseConfig.isAvailable) {
      await DatabaseService.clearAllThreads();
      _threads = [];
      _activeThread = null;
      notifyListeners();
      return;
    }

    if (_currentUserId == null) return;

    try {
      await FirestoreService.deleteAllUserThreads(_currentUserId!);
      _activeThread = null;
    } catch (e) {
      debugPrint('Error clearing history: $e');
    }
  }

  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
    _threads = [];
    _activeThread = null;
    _currentUserId = null;
    _currentUserName = '';
    _currentUserPhotoURL = '';
    clearSearch();
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
