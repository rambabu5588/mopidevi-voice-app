class TaskItem {
  final String id;
  final String taskId;
  final String wordId;
  final String targetText;
  final String? sentenceContext;
  final String status; // PENDING, ACCEPTED, REJECTED, RETAKE
  final String? audioId;
  final String? audioPath;
  final double pronunciationScore;
  final String audioQualityScore;

  TaskItem({
    required this.id,
    required this.taskId,
    required this.wordId,
    required this.targetText,
    this.sentenceContext,
    required this.status,
    this.audioId,
    this.audioPath,
    this.pronunciationScore = 0.0,
    this.audioQualityScore = '🟢 Good',
  });

  factory TaskItem.fromJson(Map<String, dynamic> json) {
    return TaskItem(
      id: json['id'] ?? '',
      taskId: json['task_id'] ?? '',
      wordId: json['word_id'] ?? '',
      targetText: json['target_text'] ?? '',
      sentenceContext: json['sentence_context'],
      status: json['status'] ?? 'PENDING',
      audioId: json['audio_id'],
      audioPath: json['audio_path'],
      pronunciationScore: (json['pronunciation_score'] as num?)?.toDouble() ?? 0.0,
      audioQualityScore: json['audio_quality_score'] ?? '🟢 Good',
    );
  }
}

class UserTask {
  final String id;
  final String userId;
  final String taskType; // VOICE_IMPROVEMENT, RECORDING_RETAKE, INITIAL_RECORDING
  final String title;
  final String? description;
  final String status; // NEW, IN_PROGRESS, COMPLETED, RETAKE_REQUIRED
  final int totalItems;
  final int completedItems;
  final String dueDate;
  final List<TaskItem> items;

  UserTask({
    required this.id,
    required this.userId,
    required this.taskType,
    required this.title,
    this.description,
    required this.status,
    required this.totalItems,
    required this.completedItems,
    required this.dueDate,
    this.items = const [],
  });

  factory UserTask.fromJson(Map<String, dynamic> json) {
    var rawItems = json['items'] as List<dynamic>? ?? [];
    List<TaskItem> parsedItems = rawItems.map((i) => TaskItem.fromJson(i as Map<String, dynamic>)).toList();

    return UserTask(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      taskType: json['task_type'] ?? 'VOICE_IMPROVEMENT',
      title: json['title'] ?? 'Task',
      description: json['description'],
      status: json['status'] ?? 'NEW',
      totalItems: (json['total_items'] as num?)?.toInt() ?? 1,
      completedItems: (json['completed_items'] as num?)?.toInt() ?? 0,
      dueDate: json['due_date'] ?? 'Due Today',
      items: parsedItems,
    );
  }

  double get progressPercent => totalItems > 0 ? (completedItems / totalItems).clamp(0.0, 1.0) : 0.0;
}
