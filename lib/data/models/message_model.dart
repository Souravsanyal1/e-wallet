import '../../core/widgets/status_badge.dart';

class MessageModel {
  final String id;
  final String conversationId;
  final String senderId;
  final String clientId;
  final String kind; // 'text', 'image', 'file', 'system'
  final String content;
  final String? replyToId;
  final String? replySnippet;
  final DateTime createdAt;
  final MessageDeliveryStatus status;
  final String? mediaUrl;

  const MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.clientId,
    this.kind = 'text',
    required this.content,
    this.replyToId,
    this.replySnippet,
    required this.createdAt,
    this.status = MessageDeliveryStatus.sent,
    this.mediaUrl,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] as String,
      conversationId: json['conversation_id'] as String,
      senderId: json['sender_id'] as String,
      clientId: json['client_id'] as String? ?? json['id'] as String,
      kind: json['kind'] as String? ?? 'text',
      content: json['content'] as String? ?? '',
      replyToId: json['reply_to_id'] as String?,
      replySnippet: json['reply_snippet'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      status: MessageDeliveryStatus.values.firstWhere(
        (e) => e.name == (json['status'] as String? ?? 'sent'),
        orElse: () => MessageDeliveryStatus.sent,
      ),
      mediaUrl: json['media_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'conversation_id': conversationId,
        'sender_id': senderId,
        'client_id': clientId,
        'kind': kind,
        'content': content,
        'reply_to_id': replyToId,
        'reply_snippet': replySnippet,
        'created_at': createdAt.toIso8601String(),
        'status': status.name,
        'media_url': mediaUrl,
      };

  MessageModel copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? clientId,
    String? kind,
    String? content,
    String? replyToId,
    String? replySnippet,
    DateTime? createdAt,
    MessageDeliveryStatus? status,
    String? mediaUrl,
  }) {
    return MessageModel(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      clientId: clientId ?? this.clientId,
      kind: kind ?? this.kind,
      content: content ?? this.content,
      replyToId: replyToId ?? this.replyToId,
      replySnippet: replySnippet ?? this.replySnippet,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      mediaUrl: mediaUrl ?? this.mediaUrl,
    );
  }
}
