class SystemUser {
  final String id;
  final String authId;
  final String profileId;
  final String name;
  final String mobileEmail;
  final String role;
  final String status;
  final String password;
  final double? lastLoginAt;
  final double? lastLogoutAt;
  final String? assignedVoiceId;
  final double createdAt;

  SystemUser({
    required this.id,
    this.authId = '',
    this.profileId = '',
    required this.name,
    this.mobileEmail = '',
    required this.role,
    this.status = 'Active',
    this.password = 'User\$1234',
    this.lastLoginAt,
    this.lastLogoutAt,
    this.assignedVoiceId,
    required this.createdAt,
  });

  factory SystemUser.fromJson(Map<String, dynamic> json) {
    return SystemUser(
      id: json['id'] ?? '',
      authId: json['auth_id'] ?? (json['id'] != null ? 'AUTH-${json['id']}' : 'AUTH-00001'),
      profileId: json['profile_id'] ?? (json['id'] != null ? 'PROF-${json['id']}' : 'PROF-00001'),
      name: json['name'] ?? '',
      mobileEmail: json['mobile_email'] ?? '',
      role: json['role'] ?? 'operator',
      status: json['status'] ?? 'Active',
      password: json['password'] ?? 'User\$1234',
      lastLoginAt: (json['last_login_at'] is num) ? (json['last_login_at'] as num).toDouble() : null,
      lastLogoutAt: (json['last_logout_at'] is num) ? (json['last_logout_at'] as num).toDouble() : null,
      assignedVoiceId: json['assigned_voice_id'],
      createdAt: (json['created_at'] is num) ? (json['created_at'] as num).toDouble() : 0.0,
    );
  }
}

