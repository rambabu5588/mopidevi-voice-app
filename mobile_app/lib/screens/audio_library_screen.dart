import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../services/api_service.dart';

class AudioLibraryScreen extends StatefulWidget {
  const AudioLibraryScreen({Key? key}) : super(key: key);

  @override
  State<AudioLibraryScreen> createState() => _AudioLibraryScreenState();
}

class _AudioLibraryScreenState extends State<AudioLibraryScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _currentlyPlayingUrl;

  final List<Map<String, String>> _todayAudio = [
    {
      "id": "JOB-101",
      "title": "🎧 ఉదయం దర్శనం (Morning Darshan)",
      "style": "Devotional Style",
      "path": "/api/audio/announcement_JOB-75DC44.wav"
    },
    {
      "id": "JOB-102",
      "title": "🎧 అభిషేకం ప్రకటన (Abhishekam Notice)",
      "style": "Important Style",
      "path": "/api/audio/announcement_JOB-1D3EE2.wav"
    }
  ];

  final List<Map<String, String>> _yesterdayAudio = [
    {
      "id": "JOB-103",
      "title": "🎧 క్షేత్ర స్వాగతం (Temple Welcome)",
      "style": "Warm Style",
      "path": "/api/audio/announcement_JOB-6CFC9B.wav"
    }
  ];

  void _playAudio(String relativePath) async {
    final fullUrl = '${ApiService.baseUrl}$relativePath';
    if (_currentlyPlayingUrl == fullUrl) {
      await _audioPlayer.pause();
      setState(() => _currentlyPlayingUrl = null);
    } else {
      await _audioPlayer.play(UrlSource(fullUrl));
      setState(() => _currentlyPlayingUrl = fullUrl);
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Widget _buildGroupSection(String title, List<Map<String, String>> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            title,
            style: const TextStyle(color: Color(0xFFE5A93C), fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        ...items.map((item) {
          final url = '${ApiService.baseUrl}${item['path']}';
          final isPlaying = _currentlyPlayingUrl == url;
          return Card(
            color: const Color(0xFF1E293B),
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: IconButton(
                icon: Icon(isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill, color: const Color(0xFFE5A93C), size: 36),
                onPressed: () => _playAudio(item['path']!),
              ),
              title: Text(item['title']!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              subtitle: Text(item['style']!, style: const TextStyle(color: Colors.white54, fontSize: 12)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(icon: const Icon(Icons.refresh, color: Colors.white70), onPressed: () {}),
                  IconButton(icon: const Icon(Icons.download, color: Colors.white70), onPressed: () {}),
                  IconButton(icon: const Icon(Icons.share, color: Colors.white70), onPressed: () {}),
                ],
              ),
            ),
          );
        }).toList()
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGroupSection('ఈరోజు (TODAY)', _todayAudio),
          const SizedBox(height: 16),
          _buildGroupSection('నిన్న (YESTERDAY)', _yesterdayAudio),
        ],
      ),
    );
  }
}
