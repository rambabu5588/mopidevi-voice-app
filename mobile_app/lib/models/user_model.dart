class SystemUser {
  final String id;
  final String name;
  final String role;
  final String? assignedVoiceId;
  final double createdAt;

  SystemUser({
    required this.id,
    required this.name,
    required this.role,
    this.assignedVoiceId,
    required this.createdAt,
  });

  factory SystemUser.fromJson(Map<String, dynamic> json) {
    return SystemUser(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      role: json['role'] ?? 'operator',
      assignedVoiceId: json['assigned_voice_id'],
      createdAt: (json['created_at'] ?? 0.0).toDouble(),
    );
  }
}
