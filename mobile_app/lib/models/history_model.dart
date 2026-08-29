class AnnouncementHistoryItem {
  final String id;
  final String jobId;
  final String userId;
  final String voiceId;
  final String voiceName;
  final String title;
  final String scriptText;
  final String style;
  final String outputAudioPath;
  final double durationSeconds;
  final String dateGroup; // Today, Yesterday, Older
  final double createdAt;

  AnnouncementHistoryItem({
    required this.id,
    required this.jobId,
    required this.userId,
    required this.voiceId,
    required this.voiceName,
    required this.title,
    required this.scriptText,
    required this.style,
    required this.outputAudioPath,
    required this.durationSeconds,
    required this.dateGroup,
    required this.createdAt,
  });

  factory AnnouncementHistoryItem.fromJson(Map<String, dynamic> json) {
    return AnnouncementHistoryItem(
      id: json['id'] ?? '',
      jobId: json['job_id'] ?? '',
      userId: json['user_id'] ?? '',
      voiceId: json['voice_id'] ?? '',
      voiceName: json['voice_name'] ?? 'తెలుగు గుడి స్వరము',
      title: json['title'] ?? (json['script_text'] != null && (json['script_text'] as String).length > 25 ? '${(json['script_text'] as String).substring(0, 25)}...' : 'ఆలయ ప్రకటన'),
      scriptText: json['script_text'] ?? json['telugu_script'] ?? '',
      style: json['style'] ?? 'Devotional',
      outputAudioPath: json['output_audio_path'] ?? '',
      durationSeconds: (json['duration_seconds'] as num?)?.toDouble() ?? 0.0,
      dateGroup: json['date_group'] ?? 'Today',
      createdAt: (json['created_at'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
