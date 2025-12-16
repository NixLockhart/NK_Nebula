/// 用户模型
class User {
  final String userId;
  final String username;
  final String? token;
  final int? tokenExpiresAt;
  final DateTime? createdAt;
  final DateTime? lastOnlineAt;

  User({
    required this.userId,
    required this.username,
    this.token,
    this.tokenExpiresAt,
    this.createdAt,
    this.lastOnlineAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['user_id'] as String? ?? json['username'] as String? ?? '',
      username: json['username'] as String? ?? '',
      token: json['token'] as String?,
      tokenExpiresAt: json['expires_at'] as int?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      lastOnlineAt: json['last_online_at'] != null
          ? DateTime.tryParse(json['last_online_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'username': username,
        if (token != null) 'token': token,
        if (tokenExpiresAt != null) 'expires_at': tokenExpiresAt,
      };

  User copyWith({
    String? userId,
    String? username,
    String? token,
    int? tokenExpiresAt,
  }) {
    return User(
      userId: userId ?? this.userId,
      username: username ?? this.username,
      token: token ?? this.token,
      tokenExpiresAt: tokenExpiresAt ?? this.tokenExpiresAt,
      createdAt: createdAt,
      lastOnlineAt: lastOnlineAt,
    );
  }

  /// 检查 token 是否有效
  bool get isTokenValid {
    if (token == null || tokenExpiresAt == null) return false;
    return DateTime.now().millisecondsSinceEpoch < tokenExpiresAt!;
  }
}
