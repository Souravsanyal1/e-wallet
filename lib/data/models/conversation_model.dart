import 'profile_model.dart';

class ConversationModel {
  final String id;
  final String type; // 'direct' or 'group'
  final String title;
  final String? avatarPath;
  final String? directKey;
  final DateTime? lastMessageAt;
  final String? lastMessagePreview;
  final int unreadCount;
  final ProfileModel? otherUser;
  final int memberCount;
  final bool isMuted;

  const ConversationModel({
    required this.id,
    required this.type,
    required this.title,
    this.avatarPath,
    this.directKey,
    this.lastMessageAt,
    this.lastMessagePreview,
    this.unreadCount = 0,
    this.otherUser,
    this.memberCount = 2,
    this.isMuted = false,
  });

  bool get isDirect => type == 'direct';
  bool get isGroup => type == 'group';

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: json['id'] as String,
      type: json['type'] as String? ?? 'direct',
      title: json['title'] as String? ?? 'Conversation',
      avatarPath: json['avatar_path'] as String?,
      directKey: json['direct_key'] as String?,
      lastMessageAt: json['last_message_at'] != null
          ? DateTime.parse(json['last_message_at'] as String)
          : null,
      lastMessagePreview: json['last_message_preview'] as String?,
      unreadCount: json['unread_count'] as int? ?? 0,
      otherUser: json['other_user'] != null
          ? ProfileModel.fromJson(json['other_user'] as Map<String, dynamic>)
          : null,
      memberCount: json['member_count'] as int? ?? 2,
      isMuted: json['is_muted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'title': title,
        'avatar_path': avatarPath,
        'direct_key': directKey,
        'last_message_at': lastMessageAt?.toIso8601String(),
        'last_message_preview': lastMessagePreview,
        'unread_count': unreadCount,
        'other_user': otherUser?.toJson(),
        'member_count': memberCount,
        'is_muted': isMuted,
      };

  ConversationModel copyWith({
    String? id,
    String? type,
    String? title,
    String? avatarPath,
    String? directKey,
    DateTime? lastMessageAt,
    String? lastMessagePreview,
    int? unreadCount,
    ProfileModel? otherUser,
    int? memberCount,
    bool? isMuted,
  }) {
    return ConversationModel(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      avatarPath: avatarPath ?? this.avatarPath,
      directKey: directKey ?? this.directKey,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      lastMessagePreview: lastMessagePreview ?? this.lastMessagePreview,
      unreadCount: unreadCount ?? this.unreadCount,
      otherUser: otherUser ?? this.otherUser,
      memberCount: memberCount ?? this.memberCount,
      isMuted: isMuted ?? this.isMuted,
    );
  }
}
