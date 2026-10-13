import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../../core/errors/result.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';
import '../models/profile_model.dart';
import 'chat_repository.dart';

class FirestoreChatRepository implements ChatRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  static const _uuid = Uuid();

  String get _currentUid => _auth.currentUser?.uid ?? 'guest';

  @override
  Future<Result<List<ConversationModel>>> fetchConversations() async {
    try {
      final snap = await _firestore
          .collection('conversations')
          .where('members', arrayContains: _currentUid)
          .orderBy('lastMessageAt', descending: true)
          .limit(30)
          .get();

      final list = snap.docs.map((doc) => ConversationModel.fromFirestore(doc, currentUserId: _currentUid)).toList();
      return Ok(list);
    } catch (e) {
      return Err(AppException.network('Failed to fetch conversations: $e'));
    }
  }

  @override
  Stream<List<ConversationModel>> watchConversations() {
    return _firestore
        .collection('conversations')
        .where('members', arrayContains: _currentUid)
        .orderBy('lastMessageAt', descending: true)
        .limit(30)
        .snapshots(includeMetadataChanges: true)
        .map((snap) => snap.docs
            .map((doc) => ConversationModel.fromFirestore(doc, currentUserId: _currentUid))
            .toList());
  }

  @override
  Future<Result<List<MessageModel>>> fetchMessages({required String conversationId}) async {
    try {
      final snap = await _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .orderBy('createdAt', descending: false)
          .limit(50)
          .get();

      final list = snap.docs.map((d) => MessageModel.fromFirestore(d, isPending: d.metadata.hasPendingWrites)).toList();
      return Ok(list);
    } catch (e) {
      return Err(AppException.network('Failed to fetch messages: $e'));
    }
  }

  @override
  Stream<MessageModel> watchMessages(String conversationId) {
    // Stream controller that broadcasts individual newly arrived or updated messages
    final controller = StreamController<MessageModel>.broadcast();

    _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .limitToLast(30)
        .snapshots(includeMetadataChanges: true)
        .listen((snapshot) {
      for (final change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added || change.type == DocumentChangeType.modified) {
          final msg = MessageModel.fromFirestore(
            change.doc,
            isPending: change.doc.metadata.hasPendingWrites,
          );
          controller.add(msg);
        }
      }
    }, onError: (e) {
      controller.addError(e);
    });

    return controller.stream;
  }

  @override
  Future<Result<MessageModel>> sendMessage({
    required String conversationId,
    required String content,
    String? replyToId,
    String? replySnippet,
  }) async {
    try {
      final clientId = _uuid.v4();
      final msgRef = _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .doc();

      final msgData = {
        'id': msgRef.id,
        'conversationId': conversationId,
        'senderId': _currentUid,
        'clientId': clientId,
        'kind': 'text',
        'content': content,
        'replyToId': replyToId,
        'replySnippet': replySnippet,
        'createdAt': FieldValue.serverTimestamp(),
      };

      await msgRef.set(msgData);

      // Update parent conversation preview
      await _firestore.collection('conversations').doc(conversationId).update({
        'lastMessageAt': FieldValue.serverTimestamp(),
        'lastMessagePreview': content,
      });

      final model = MessageModel(
        id: msgRef.id,
        conversationId: conversationId,
        senderId: _currentUid,
        clientId: clientId,
        content: content,
        replyToId: replyToId,
        replySnippet: replySnippet,
        createdAt: DateTime.now(),
      );

      return Ok(model);
    } catch (e) {
      return Err(AppException.network('Failed to send message: $e'));
    }
  }

  @override
  Future<Result<void>> markAsRead(String conversationId) async {
    try {
      await _firestore.collection('conversations').doc(conversationId).update({
        'lastReadAt': FieldValue.serverTimestamp(),
      });
      return const Ok(null);
    } catch (e) {
      return const Ok(null); // non-critical
    }
  }

  @override
  Future<Result<ConversationModel>> createDirectConversation(String handle) async {
    try {
      final cleanHandle = handle.replaceAll('@', '').trim().toLowerCase();
      final userQuery = await _firestore
          .collection('users')
          .where('handle', isEqualTo: cleanHandle)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        return Err(AppException.notFound('User @$cleanHandle not found.'));
      }

      final recipientDoc = userQuery.docs.first;
      final recipientId = recipientDoc.id;
      final recipientData = recipientDoc.data();

      final sortedIds = [_currentUid, recipientId]..sort();
      final directKey = '${sortedIds[0]}:${sortedIds[1]}';

      // Check existing conversation
      final existingQuery = await _firestore
          .collection('conversations')
          .where('directKey', isEqualTo: directKey)
          .limit(1)
          .get();

      if (existingQuery.docs.isNotEmpty) {
        final conv = ConversationModel.fromFirestore(existingQuery.docs.first, currentUserId: _currentUid);
        return Ok(conv);
      }

      final convRef = _firestore.collection('conversations').doc();
      final newConvData = {
        'id': convRef.id,
        'type': 'direct',
        'title': recipientData['displayName'] ?? recipientData['handle'] ?? 'User',
        'directKey': directKey,
        'members': [_currentUid, recipientId],
        'createdBy': _currentUid,
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessageAt': FieldValue.serverTimestamp(),
        'lastMessagePreview': 'Started a conversation',
      };

      await convRef.set(newConvData);

      final otherProfile = ProfileModel(
        id: recipientId,
        handle: recipientData['handle'] ?? 'user',
        displayName: recipientData['displayName'] ?? 'User',
        createdAt: DateTime.now(),
      );

      final convModel = ConversationModel(
        id: convRef.id,
        type: 'direct',
        title: recipientData['displayName'] ?? recipientData['handle'] ?? 'User',
        directKey: directKey,
        lastMessageAt: DateTime.now(),
        lastMessagePreview: 'Started a conversation',
        otherUser: otherProfile,
      );

      return Ok(convModel);
    } catch (e) {
      return Err(AppException.network('Failed to create conversation: $e'));
    }
  }

  @override
  Future<Result<ConversationModel>> createGroupConversation({
    required String title,
    required List<String> memberHandles,
  }) async {
    try {
      final convRef = _firestore.collection('conversations').doc();
      final groupData = {
        'id': convRef.id,
        'type': 'group',
        'title': title,
        'members': [_currentUid],
        'createdBy': _currentUid,
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessageAt': FieldValue.serverTimestamp(),
        'lastMessagePreview': 'Group created',
      };

      await convRef.set(groupData);

      final convModel = ConversationModel(
        id: convRef.id,
        type: 'group',
        title: title,
        memberCount: 1,
        lastMessageAt: DateTime.now(),
        lastMessagePreview: 'Group created',
      );

      return Ok(convModel);
    } catch (e) {
      return Err(AppException.network('Failed to create group: $e'));
    }
  }
}
