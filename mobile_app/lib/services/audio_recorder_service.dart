import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class AudioRecorderService {
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  String? _lastRecordedPath;

  bool get isRecording => _isRecording;
  String? get lastRecordedPath => _lastRecordedPath;

  Future<void> startRecording() async {
    if (await _audioRecorder.hasPermission()) {
      final Directory tempDir = await getTemporaryDirectory();
      final String filePath = '${tempDir.path}/rec_${DateTime.now().millisecondsSinceEpoch}.wav';
      
      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 16000,
          numChannels: 1,
        ),
        path: filePath,
      );
      _isRecording = true;
      _lastRecordedPath = filePath;
    } else {
      throw Exception('Microphone permission denied');
    }
  }

  Future<String?> stopRecording() async {
    final path = await _audioRecorder.stop();
    _isRecording = false;
    _lastRecordedPath = path;
    return path;
  }

  Future<void> dispose() async {
    _audioRecorder.dispose();
  }
}
