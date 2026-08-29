import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/audio_recorder_service.dart';

class TrainingScreen extends StatefulWidget {
  final String activeUserId;
  const TrainingScreen({Key? key, required this.activeUserId}) : super(key: key);

  @override
  State<TrainingScreen> createState() => _TrainingScreenState();
}

class _TrainingScreenState extends State<TrainingScreen> {
  final AudioRecorderService _recorderService = AudioRecorderService();
  
  List<dynamic> _datasetScripts = [];
  int _currentScriptIdx = 0;
  bool _isRecording = false;
  bool _isAnalyzing = false;
  Map<String, dynamic>? _analysisResult;

  @override
  void initState() {
    super.initState();
    _loadDatasetScripts();
  }

  Future<void> _loadDatasetScripts() async {
    try {
      final scripts = await ApiService.fetchDatasetScripts();
      setState(() {
        _datasetScripts = scripts;
      });
    } catch (e) {
      debugPrint('Failed to load dataset scripts: $e');
    }
  }

  void _toggleRecording() async {
    if (_isRecording) {
      final path = await _recorderService.stopRecording();
      setState(() {
        _isRecording = false;
        _isAnalyzing = true;
      });

      if (path != null) {
        try {
          final res = await ApiService.analyzeVoiceSample(path);
          setState(() {
            _analysisResult = res;
            _isAnalyzing = false;
          });
        } catch (e) {
          setState(() => _isAnalyzing = false);
        }
      }
    } else {
      await _recorderService.startRecording();
      setState(() {
        _isRecording = true;
        _analysisResult = null;
      });
    }
  }

  void _nextScript() {
    if (_currentScriptIdx < _datasetScripts.length - 1) {
      setState(() {
        _currentScriptIdx++;
        _analysisResult = null;
      });
    }
  }

  @override
  void dispose() {
    _recorderService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentScript = _datasetScripts.isNotEmpty
        ? _datasetScripts[_currentScriptIdx]
        : {'title': 'శిక్షణ వాక్యం 1', 'script_text': 'మోపిదేవి ఆలయ విచ్చేసిన భక్తులందరికీ శ్రీ సుబ్రహ్మణ్య స్వామి వారి ఆశీస్సులు.'};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Card
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
                        '🎯 లిపి శిక్షణ (Sentence Reader ${_currentScriptIdx + 1}/${_datasetScripts.isNotEmpty ? _datasetScripts.length : 20})',
                        style: const TextStyle(color: Color(0xFFE5A93C), fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      Chip(
                        label: Text('సెషన్ ${_currentScriptIdx + 1}', style: const TextStyle(color: Colors.black, fontSize: 11)),
                        backgroundColor: const Color(0xFFE5A93C),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    currentScript['title'] ?? '',
                    style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Text(
                      currentScript['script_text'] ?? '',
                      style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Recording Action
          ElevatedButton.icon(
            onPressed: _toggleRecording,
            style: ElevatedButton.styleFrom(
              backgroundColor: _isRecording ? Colors.redAccent : const Color(0xFFE5A93C),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: Icon(_isRecording ? Icons.stop : Icons.mic),
            label: Text(
              _isRecording ? 'రికార్డింగ్ ఆపండి (STOP RECORDING)' : 'చదవడం ప్రారంభించండి (START READING)',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
          const SizedBox(height: 16),

          if (_isAnalyzing)
            const Center(child: CircularProgressIndicator(color: Color(0xFFE5A93C))),

          // Quality Badges
          if (_analysisResult != null && !_isAnalyzing)
            Card(
              color: const Color(0xFF1E293B),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text('నాణ్యతా హోదా: ${_analysisResult!['quality_badge']}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    Text('నాయిస్ ఫ్లోర్: ${_analysisResult!['noise_floor_db']} dB', style: const TextStyle(color: Colors.white70)),
                    Text('పిచ్ అంచనా: ${_analysisResult!['pitch_estimate_hz']} Hz', style: const TextStyle(color: Colors.white70)),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _nextScript,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      child: const Text('ఆమోదించండి & తరువాతి వాక్యం ➔'),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
