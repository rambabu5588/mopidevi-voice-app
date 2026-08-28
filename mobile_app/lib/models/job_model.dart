class AnnouncementJob {
  final String id;
  final String userId;
  final String voiceId;
  final String teluguScript;
  final String? cleanScript;
  final String style;
  final String status;
  final String currentStep;
  final int progressPercent;
  final String? outputAudioPath;
  final String? outputMp3Path;
  final double createdAt;

  AnnouncementJob({
    required this.id,
    required this.userId,
    required this.voiceId,
    required this.teluguScript,
    this.cleanScript,
    required this.style,
    required this.status,
    required this.currentStep,
    required this.progressPercent,
    this.outputAudioPath,
    this.outputMp3Path,
    required this.createdAt,
  });

  factory AnnouncementJob.fromJson(Map<String, dynamic> json) {
    return AnnouncementJob(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      voiceId: json['voice_id'] ?? '',
      teluguScript: json['telugu_script'] ?? '',
      cleanScript: json['clean_script'],
      style: json['style'] ?? 'Devotional',
      status: json['status'] ?? 'QUEUED',
      currentStep: json['current_step'] ?? 'Job Created',
      progressPercent: json['progress_percent'] ?? 0,
      outputAudioPath: json['output_audio_path'],
      outputMp3Path: json['output_mp3_path'],
      createdAt: (json['created_at'] ?? 0.0).toDouble(),
    );
  }
}
