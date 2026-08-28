class VoiceModel {
  final String id;
  final String userId;
  final String voiceName;
  final String voiceType;
  final String? audioSamplePath;
  final String qualityScore;
  final String modelStatus;
  final double createdAt;

  VoiceModel({
    required this.id,
    required this.userId,
    required this.voiceName,
    required this.voiceType,
    this.audioSamplePath,
    required this.qualityScore,
    required this.modelStatus,
    required this.createdAt,
  });

  factory VoiceModel.fromJson(Map<String, dynamic> json) {
    return VoiceModel(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      voiceName: json['voice_name'] ?? '',
      voiceType: json['voice_type'] ?? 'system',
      audioSamplePath: json['audio_sample_path'],
      qualityScore: json['quality_score'] ?? '🟢 Good',
      modelStatus: json['model_status'] ?? 'READY',
      createdAt: (json['created_at'] ?? 0.0).toDouble(),
    );
  }
}
