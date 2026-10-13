import 'dart:async';
import 'package:uuid/uuid.dart';
import '../../core/errors/result.dart';
import '../../core/widgets/status_badge.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';
import '../models/profile_model.dart';
import 'chat_repository.dart';

class MockChatRepository implements ChatRepository {
  static const _uuid = Uuid();

  final List<ConversationModel> _conversations = [];
  final Map<String, List<MessageModel>> _messagesByConv = {};

  final _conversationsStreamController = StreamController<List<ConversationModel>>.broadcast();
  final Map<String, StreamController<MessageModel>> _messageControllers = {};

  MockChatRepository() {
    _initMockData();
  }

  void _initMockData() {
    final alice = ProfileModel(
      id: 'user_alice',
      handle: 'alice',
      displayName: 'Alice Chen',
      bio: 'Web3 Builder & Cryptographer',
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      isOnline: true,
    );

    final bob = ProfileModel(
      id: 'user_bob',
      handle: 'bob',
      displayName: 'Bob Smith',
      bio: 'Smart contract security researcher',
      createdAt: DateTime.now().subtract(const Duration(days: 20)),
      isOnline: false,
    );

    final convAlice = ConversationModel(
      id: 'c_alice',
      type: 'direct',
      title: 'Alice Chen',
      otherUser: alice,
      lastMessageAt: DateTime.now().subtract(const Duration(minutes: 5)),
      lastMessagePreview: 'Sounds good, see you soon!',
      unreadCount: 1,
    );

    final convBob = ConversationModel(
      id: 'c_bob',
      type: 'direct',
      title: 'Bob Smith',
      otherUser: bob,
      lastMessageAt: DateTime.now().subtract(const Duration(hours: 2)),
      lastMessagePreview: 'Audit findings report ready for review.',
      unreadCount: 0,
    );

    final convDesign = ConversationModel(
      id: 'c_design',
      type: 'group',
      title: 'Design Team',
      memberCount: 5,
      lastMessageAt: DateTime.now().subtract(const Duration(hours: 4)),
      lastMessagePreview: 'Sam: Uploaded the new token badge designs',
      unreadCount: 3,
    );

    _conversations.addAll([convAlice, convBob, convDesign]);

    // Initial messages for Alice
    _messagesByConv['c_alice'] = [
      MessageModel(
        id: 'm1',
        conversationId: 'c_alice',
        senderId: 'user_alice',
        clientId: 'c1',
        content: 'Hey! Did you check out the new EIP-4361 authentication specs?',
        createdAt: DateTime.now().subtract(const Duration(minutes: 25)),
        status: MessageDeliveryStatus.read,
      ),
      MessageModel(
        id: 'm2',
        conversationId: 'c_alice',
        senderId: 'me',
        clientId: 'c2',
        content: 'Yes! The wallet sign-in flow looks very clean and secure.',
        createdAt: DateTime.now().subtract(const Duration(minutes: 20)),
        status: MessageDeliveryStatus.read,
      ),
      MessageModel(
        id: 'm3',
        conversationId: 'c_alice',
        senderId: 'user_alice',
        clientId: 'c3',
        content: 'Sounds good, see you soon!',
        createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
        status: MessageDeliveryStatus.delivered,
      ),
    ];

    // Initial messages for Bob
    _messagesByConv['c_bob'] = [
      MessageModel(
        id: 'mb1',
        conversationId: 'c_bob',
        senderId: 'user_bob',
        clientId: 'cb1',
        content: 'Audit findings report ready for review.',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        status: MessageDeliveryStatus.read,
      ),
    ];

    // Initial messages for Design Team
    _messagesByConv['c_design'] = [
      MessageModel(
        id: 'md1',
        conversationId: 'c_design',
        senderId: 'user_sam',
        clientId: 'cd1',
        content: 'Sam: Uploaded the new token badge designs',
        createdAt: DateTime.now().subtract(const Duration(hours: 4)),
        status: MessageDeliveryStatus.read,
      ),
    ];
  }

  @override
  Future<Result<List<ConversationModel>>> fetchConversations() async {
    await Future.delayed(const Duration(milliseconds: 150));
    return Ok(List.unmodifiable(_conversations));
  }

  @override
  Stream<List<ConversationModel>> watchConversations() {
    return _conversationsStreamController.stream;
  }

  @override
  Future<Result<List<MessageModel>>> fetchMessages({required String conversationId}) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final list = _messagesByConv[conversationId] ?? [];
    return Ok(List.unmodifiable(list));
  }

  @override
  Stream<MessageModel> watchMessages(String conversationId) {
    _messageControllers.putIfAbsent(
      conversationId,
      () => StreamController<MessageModel>.broadcast(),
    );
    return _messageControllers[conversationId]!.stream;
  }

  @override
  Future<Result<MessageModel>> sendMessage({
    required String conversationId,
    required String content,
    String? replyToId,
    String? replySnippet,
  }) async {
    final msg = MessageModel(
      id: _uuid.v4(),
      conversationId: conversationId,
      senderId: 'me',
      clientId: _uuid.v4(),
      content: content,
      replyToId: replyToId,
      replySnippet: replySnippet,
      createdAt: DateTime.now(),
      status: MessageDeliveryStatus.sent,
    );

    _messagesByConv.putIfAbsent(conversationId, () => []).add(msg);
    _messageControllers[conversationId]?.add(msg);

    // Update conversation preview
    final idx = _conversations.indexWhere((c) => c.id == conversationId);
    if (idx != -1) {
      _conversations[idx] = _conversations[idx].copyWith(
        lastMessageAt: msg.createdAt,
        lastMessagePreview: msg.content,
      );
      _conversationsStreamController.add(List.unmodifiable(_conversations));
    }

    // Auto-reply simulation for interactive demo
    if (conversationId == 'c_alice') {
      Timer(const Duration(milliseconds: 1800), () {
        final reply = MessageModel(
          id: _uuid.v4(),
          conversationId: conversationId,
          senderId: 'user_alice',
          clientId: _uuid.v4(),
          content: 'Got it! Looking forward to reviewing the implementation with you.',
          createdAt: DateTime.now(),
          status: MessageDeliveryStatus.delivered,
        );
        _messagesByConv[conversationId]?.add(reply);
        _messageControllers[conversationId]?.add(reply);

        if (idx != -1) {
          _conversations[idx] = _conversations[idx].copyWith(
            lastMessageAt: reply.createdAt,
            lastMessagePreview: reply.content,
          );
          _conversationsStreamController.add(List.unmodifiable(_conversations));
        }
      });
    }

    return Ok(msg);
  }

  @override
  Future<Result<void>> markAsRead(String conversationId) async {
    final idx = _conversations.indexWhere((c) => c.id == conversationId);
    if (idx != -1) {
      _conversations[idx] = _conversations[idx].copyWith(unreadCount: 0);
      _conversationsStreamController.add(List.unmodifiable(_conversations));
    }
    return const Ok(null);
  }

  @override
  Future<Result<ConversationModel>> createDirectConversation(String handle) async {
    final cleanHandle = handle.replaceAll('@', '').toLowerCase();
    final existing = _conversations.firstWhereOrNull(
      (c) => c.isDirect && c.otherUser?.handle.toLowerCase() == cleanHandle,
    );
    if (existing != null) {
      return Ok(existing);
    }

    final newProfile = ProfileModel(
      id: 'user_${_uuid.v4().substring(0, 8)}',
      handle: cleanHandle,
      displayName: cleanHandle[0].toUpperCase() + cleanHandle.substring(1),
      createdAt: DateTime.now(),
      isOnline: true,
    );

    final newConv = ConversationModel(
      id: 'c_${_uuid.v4()}',
      type: 'direct',
      title: newProfile.displayName,
      otherUser: newProfile,
      lastMessageAt: DateTime.now(),
      lastMessagePreview: 'Started a new chat',
      unreadCount: 0,
    );

    _conversations.insert(0, newConv);
    _conversationsStreamController.add(List.unmodifiable(_conversations));
    return Ok(newConv);
  }

  @override
  Future<Result<ConversationModel>> createGroupConversation({
    required String title,
    required List<String> memberHandles,
  }) async {
    final newConv = ConversationModel(
      id: 'g_${_uuid.v4()}',
      type: 'group',
      title: title,
      memberCount: memberHandles.length + 1,
      lastMessageAt: DateTime.now(),
      lastMessagePreview: 'Group created',
      unreadCount: 0,
    );

    _conversations.insert(0, newConv);
    _conversationsStreamController.add(List.unmodifiable(_conversations));
    return Ok(newConv);
  }
}

extension FirstWhereOrNullExt<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T element) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}
