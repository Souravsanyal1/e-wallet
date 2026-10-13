import '../../core/errors/result.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';

abstract class ChatRepository {
  /// Fetches conversation list
  Future<Result<List<ConversationModel>>> fetchConversations();

  /// Watches realtime updates to conversations list
  Stream<List<ConversationModel>> watchConversations();

  /// Fetches initial paginated messages for a conversation
  Future<Result<List<MessageModel>>> fetchMessages({required String conversationId});

  /// Watches realtime stream of new messages in a conversation
  Stream<MessageModel> watchMessages(String conversationId);

  /// Sends a message optimistically
  Future<Result<MessageModel>> sendMessage({
    required String conversationId,
    required String content,
    String? replyToId,
    String? replySnippet,
  });

  /// Marks conversation as read
  Future<Result<void>> markAsRead(String conversationId);

  /// Creates a direct conversation with a recipient handle
  Future<Result<ConversationModel>> createDirectConversation(String handle);

  /// Creates a new group conversation
  Future<Result<ConversationModel>> createGroupConversation({
    required String title,
    required List<String> memberHandles,
  });
}
