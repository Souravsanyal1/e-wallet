import 'package:cloud_firestore/cloud_firestore.dart';
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

  factory ConversationModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc, {
    String? currentUserId,
  }) {
    final data = doc.data() ?? {};
    final rawLastAt = data['lastMessageAt'];
    DateTime? lastMsgDate;
    if (rawLastAt is Timestamp) {
      lastMsgDate = rawLastAt.toDate();
    } else if (rawLastAt is String) {
      lastMsgDate = DateTime.tryParse(rawLastAt);
    }

    final members = (data['members'] as List<dynamic>?)?.cast<String>() ?? [];

    return ConversationModel(
      id: doc.id,
      type: data['type'] as String? ?? 'direct',
      title: data['title'] as String? ?? 'Conversation',
      avatarPath: data['avatarPath'] as String?,
      directKey: data['directKey'] as String?,
      lastMessageAt: lastMsgDate,
      lastMessagePreview: data['lastMessagePreview'] as String?,
      unreadCount: data['unreadCount'] as int? ?? 0,
      memberCount: members.length,
      isMuted: data['isMuted'] as bool? ?? false,
    );
  }

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: json['id'] as String,
      type: json['type'] as String? ?? 'direct',
      title: json['title'] as String? ?? 'Conversation',
      avatarPath: json['avatar_path'] as String? ?? json['avatarPath'] as String?,
      directKey: json['direct_key'] as String? ?? json['directKey'] as String?,
      lastMessageAt: json['last_message_at'] != null
          ? DateTime.parse(json['last_message_at'] as String)
          : null,
      lastMessagePreview: json['last_message_preview'] as String? ?? json['lastMessagePreview'] as String?,
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
        'avatarPath': avatarPath,
        'directKey': directKey,
        'lastMessageAt': lastMessageAt?.toIso8601String(),
        'lastMessagePreview': lastMessagePreview,
        'unreadCount': unreadCount,
        'otherUser': otherUser?.toJson(),
        'memberCount': memberCount,
        'isMuted': isMuted,
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
