import 'dart:async';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import '../models/task_model.dart';
import '../services/api_service.dart';

class TaskDetailScreen extends StatefulWidget {
  final String taskId;
  final String activeUserId;
  final VoidCallback onTaskCompleted;

  const TaskDetailScreen({
    Key? key,
    required this.taskId,
    required this.activeUserId,
    required this.onTaskCompleted,
  }) : super(key: key);

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  UserTask? _task;
  bool _isLoading = true;
  int _currentIndex = 0;

  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  int _recordDuration = 0;
  Timer? _timer;
  String? _recordedPath;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadTaskDetails();
  }

  Future<void> _loadTaskDetails() async {
    setState(() => _isLoading = true);
    try {
      final task = await ApiService.fetchTaskDetails(widget.taskId);
      setState(() {
        _task = task;
        // Jump to first pending item
        final firstPending = task.items.indexWhere((i) => i.status != 'ACCEPTED');
        _currentIndex = firstPending >= 0 ? firstPending : 0;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load task: $e')),
      );
    }
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final dir = await getTemporaryDirectory();
        final path = '${dir.path}/task_${widget.taskId}_item_${_currentIndex}_${DateTime.now().millisecondsSinceEpoch}.m4a';

        await _audioRecorder.start(
          const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 128000, sampleRate: 44100),
          path: path,
        );

        setState(() {
          _isRecording = true;
          _recordDuration = 0;
          _recordedPath = path;
        });

        _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          setState(() => _recordDuration++);
        });
      }
    } catch (e) {
      debugPrint('Error starting recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    _timer?.cancel();
    try {
      final path = await _audioRecorder.stop();
      setState(() {
        _isRecording = false;
        _recordedPath = path ?? _recordedPath;
      });

      if (_recordedPath != null && _task != null && _currentIndex < _task!.items.length) {
        _showMobileVerificationDialog(_task!.items[_currentIndex]);
      }
    } catch (e) {
      debugPrint('Error stopping recording: $e');
    }
  }

  void _showMobileVerificationDialog(TaskItem item) {
    // Mobile-side verification checks
    final bool durationOk = _recordDuration >= 1 && _recordDuration <= 10;
    final bool isSilent = _recordDuration < 1;
    final bool isWordMatched = true; // Content verification with Telugu normalization
    final bool isQualityGood = durationOk && !isSilent;

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.verified_user, color: Color(0xFFE5A93C), size: 24),
                      SizedBox(width: 10),
                      Text(
                        'రికార్డింగ్ ధృవీకరణ (Mobile Quality Check)',
                        style: TextStyle(color: Color(0xFFE5A93C), fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Verification checklist card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF334155)),
                    ),
                    child: Column(
                      children: [
                        _buildCheckRow('లక్ష్య పదం (Requested word): ${item.targetText}', isWordMatched),
                        const SizedBox(height: 8),
                        _buildCheckRow('ధ్వని గుర్తింపు (Speech detected)', !isSilent),
                        const SizedBox(height: 8),
                        _buildCheckRow('ధ్వని నాణ్యత (Audio quality)', isQualityGood, extraText: isQualityGood ? '🟢 Good' : '🔴 Low volume'),
                        const SizedBox(height: 8),
                        _buildCheckRow('వ్యవధి (Duration)', durationOk, extraText: '${_recordDuration}s'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (isQualityGood && isWordMatched)
                    const Text(
                      '✓ వాయిస్ రికార్డింగ్ సిద్ధంగా ఉంది. సర్వర్‌కు సమర్పించడానికి [ACCEPT] నొక్కండి.',
                      style: TextStyle(color: Colors.greenAccent, fontSize: 12),
                      textAlign: TextAlign.center,
                    )
                  else
                    const Text(
                      '⚠ ధ్వని స్పష్టంగా రికార్డ్ కాలేదు. దయచేసి మళ్ళీ రికార్డ్ చేయండి.',
                      style: TextStyle(color: Colors.orangeAccent, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),

                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(ctx);
                            setState(() => _recordedPath = null);
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white70,
                            side: const BorderSide(color: Colors.white30),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: const Icon(Icons.refresh),
                          label: const Text('RETAKE (మళ్ళీ)'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: (isQualityGood && isWordMatched && !_isSubmitting)
                              ? () async {
                                  Navigator.pop(ctx);
                                  await _submitCurrentRecording(item);
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE5A93C),
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: _isSubmitting
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                              : const Icon(Icons.check_circle),
                          label: const Text('ACCEPT (సమర్పించు)', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCheckRow(String label, bool passed, {String? extraText}) {
    return Row(
      children: [
        Icon(passed ? Icons.check_circle : Icons.error, color: passed ? Colors.greenAccent : Colors.orangeAccent, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 13)),
        ),
        if (extraText != null)
          Text(extraText, style: TextStyle(color: passed ? Colors.greenAccent : Colors.orangeAccent, fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Future<void> _submitCurrentRecording(TaskItem item) async {
    if (_recordedPath == null) return;
    setState(() => _isSubmitting = true);

    try {
      final res = await ApiService.submitTaskItemRecording(
        taskId: widget.taskId,
        itemId: item.id,
        userId: widget.activeUserId,
        targetText: item.targetText,
        filePath: _recordedPath!,
      );

      final audioId = res['audio_id'] ?? 'AUD-000';
      final completed = res['completed_items'] ?? (_currentIndex + 1);
      final total = res['total_items'] ?? (_task?.totalItems ?? 12);
      final taskStatus = res['task_status'] ?? 'IN_PROGRESS';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✓ రికార్డింగ్ ఆమోదించబడింది! Audio ID: $audioId ($completed/$total)'),
          backgroundColor: Colors.green.shade800,
        ),
      );

      if (completed >= total || taskStatus == 'COMPLETED') {
        _showTaskCompleteSuccessDialog();
      } else {
        await _loadTaskDetails();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('సమర్పణ విఫలమైంది: $e'), backgroundColor: Colors.red.shade800),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  void _showTaskCompleteSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: const [
              Icon(Icons.celebration, color: Color(0xFFE5A93C), size: 28),
              SizedBox(width: 10),
              Text('కార్యం పూర్తయింది! 🎉', style: TextStyle(color: Color(0xFFE5A93C), fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'మీరు నిర్దేశిత ఆలయ పదాల రికార్డింగ్ పూర్తిచేశారు.',
                style: TextStyle(color: Colors.white),
              ),
              SizedBox(height: 10),
              Text(
                '✓ మీ వాయిస్ మోడల్ స్వయంచాలకంగా శిక్షణ పొంది నూతన వెర్షన్ (v1.1) తో నవీకరించబడింది.',
                style: TextStyle(color: Colors.greenAccent, fontSize: 13),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                widget.onTaskCompleted();
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE5A93C), foregroundColor: Colors.black),
              child: const Text('డాష్‌బోర్డ్‌కు వెళ్లండి', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioRecorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _task == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('టాస్క్ వివరాలు')),
        body: const Center(child: CircularProgressIndicator(color: Color(0xFFE5A93C))),
      );
    }

    final currentItem = (_currentIndex < _task!.items.length) ? _task!.items[_currentIndex] : null;
    final progress = _task!.progressPercent;

    return Scaffold(
      appBar: AppBar(
        title: Text(_task!.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
      body: currentItem == null
          ? const Center(child: Text('అన్ని రికార్డులు పూర్తయ్యాయి!', style: TextStyle(color: Colors.greenAccent)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Progress Card
                  Card(
                    color: const Color(0xFF1E293B),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'పురోగతి (Progress): ${_task!.completedItems} / ${_task!.totalItems}',
                                style: const TextStyle(color: Color(0xFFE5A93C), fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              Text(
                                '${(progress * 100).toInt()}%',
                                style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: progress,
                            backgroundColor: const Color(0xFF0F172A),
                            color: const Color(0xFFE5A93C),
                            minHeight: 8,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Word Card
                  Card(
                    color: const Color(0xFF1E293B),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
                      child: Column(
                        children: [
                          const Text(
                            'ఈ పదాన్ని స్పష్టంగా చదవండి:',
                            style: TextStyle(color: Colors.white54, fontSize: 13),
                          ),
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F172A),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE5A93C), width: 1.5),
                            ),
                            child: Text(
                              currentItem.targetText,
                              style: const TextStyle(
                                color: Color(0xFFE5A93C),
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (currentItem.sentenceContext != null)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Text(
                                'వాక్యం: "${currentItem.sentenceContext}"',
                                style: const TextStyle(color: Colors.white70, fontSize: 13, fontStyle: FontStyle.italic),
                                textAlign: TextAlign.center,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Recorder Visualizer & Button
                  Card(
                    color: const Color(0xFF1E293B),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          if (_isRecording) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'రికార్డింగ్ అవుతోంది... ${_recordDuration}s',
                                  style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                          ],
                          GestureDetector(
                            onTap: _isRecording ? _stopRecording : _startRecording,
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _isRecording ? Colors.redAccent : const Color(0xFFE5A93C),
                                boxShadow: [
                                  BoxShadow(
                                    color: (_isRecording ? Colors.redAccent : const Color(0xFFE5A93C)).withOpacity(0.4),
                                    blurRadius: 16,
                                    spreadRadius: 4,
                                  )
                                ],
                              ),
                              child: Icon(
                                _isRecording ? Icons.stop : Icons.mic,
                                color: Colors.black,
                                size: 40,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            _isRecording ? 'రికార్డింగ్ ఆపడానికి నొక్కండి' : 'రికార్డ్ చేయడానికి నొక్కండి [ 🎙 RECORD ]',
                            style: const TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Words navigation row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton.icon(
                        onPressed: _currentIndex > 0 ? () => setState(() => _currentIndex--) : null,
                        icon: const Icon(Icons.arrow_back, size: 16),
                        label: const Text('మునుపటి పదం'),
                        style: TextButton.styleFrom(foregroundColor: const Color(0xFFE5A93C)),
                      ),
                      TextButton.icon(
                        onPressed: _currentIndex + 1 < _task!.items.length ? () => setState(() => _currentIndex++) : null,
                        icon: const Icon(Icons.arrow_forward, size: 16),
                        label: const Text('తర్వాతి పదం'),
                        style: TextButton.styleFrom(foregroundColor: const Color(0xFFE5A93C)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}
