class ProfileModel {
  final String id;
  final String handle;
  final String displayName;
  final String? avatarPath;
  final String? bio;
  final DateTime createdAt;
  final bool isOnline;

  const ProfileModel({
    required this.id,
    required this.handle,
    required this.displayName,
    this.avatarPath,
    this.bio,
    required this.createdAt,
    this.isOnline = false,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] as String,
      handle: json['handle'] as String? ?? 'anon',
      displayName: json['display_name'] as String? ?? 'Anonymous',
      avatarPath: json['avatar_path'] as String?,
      bio: json['bio'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      isOnline: json['is_online'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'handle': handle,
        'display_name': displayName,
        'avatar_path': avatarPath,
        'bio': bio,
        'created_at': createdAt.toIso8601String(),
        'is_online': isOnline,
      };

  ProfileModel copyWith({
    String? id,
    String? handle,
    String? displayName,
    String? avatarPath,
    String? bio,
    DateTime? createdAt,
    bool? isOnline,
  }) {
    return ProfileModel(
      id: id ?? this.id,
      handle: handle ?? this.handle,
      displayName: displayName ?? this.displayName,
      avatarPath: avatarPath ?? this.avatarPath,
      bio: bio ?? this.bio,
      createdAt: createdAt ?? this.createdAt,
      isOnline: isOnline ?? this.isOnline,
    );
  }
}
