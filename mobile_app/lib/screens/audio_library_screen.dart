import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../services/api_service.dart';
import '../models/history_model.dart';

class AudioLibraryScreen extends StatefulWidget {
  final String activeUserId;
  const AudioLibraryScreen({Key? key, required this.activeUserId}) : super(key: key);

  @override
  State<AudioLibraryScreen> createState() => _AudioLibraryScreenState();
}

class _AudioLibraryScreenState extends State<AudioLibraryScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _currentlyPlayingUrl;
  bool _isLoading = true;
  List<AnnouncementHistoryItem> _historyItems = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _audioPlayer.onPlayerComplete.listen((_) {
      setState(() => _currentlyPlayingUrl = null);
    });
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    try {
      final items = await ApiService.fetchAnnouncementHistory(widget.activeUserId);
      setState(() {
        _historyItems = items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _playAudio(String relativePath) async {
    final fullUrl = relativePath.startsWith('http') ? relativePath : '${ApiService.baseUrl}$relativePath';
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

  Widget _buildGroupSection(String title, List<AnnouncementHistoryItem> items) {
    if (items.isEmpty) return const SizedBox.shrink();

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
          final fullUrl = item.outputAudioPath.startsWith('http')
              ? item.outputAudioPath
              : '${ApiService.baseUrl}${item.outputAudioPath}';
          final isPlaying = _currentlyPlayingUrl == fullUrl;

          return Card(
            color: const Color(0xFF1E293B),
            margin: const EdgeInsets.only(bottom: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: IconButton(
                icon: Icon(
                  isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
                  color: const Color(0xFFE5A93C),
                  size: 38,
                ),
                onPressed: () => _playAudio(item.outputAudioPath),
              ),
              title: Text(
                item.title,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                '${item.style} • ${item.voiceName}',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: const Text(
                  '▶ WAV',
                  style: TextStyle(color: Color(0xFFE5A93C), fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          );
        }).toList(),
        const SizedBox(height: 10),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final todayItems = _historyItems.where((i) => i.dateGroup == 'Today').toList();
    final yesterdayItems = _historyItems.where((i) => i.dateGroup == 'Yesterday').toList();
    final olderItems = _historyItems.where((i) => i.dateGroup == 'Older').toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('నా ఆడియోలు (My Audio History)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFE5A93C)))
          : RefreshIndicator(
              onRefresh: _loadHistory,
              color: const Color(0xFFE5A93C),
              child: _historyItems.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.library_music, color: Colors.white24, size: 64),
                          SizedBox(height: 12),
                          Text('ఆడియోలు లేవు (No announcement audio generated yet)', style: TextStyle(color: Colors.white54, fontSize: 14)),
                        ],
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.all(16.0),
                      children: [
                        _buildGroupSection('ఈరోజు (Today)', todayItems),
                        _buildGroupSection('నిన్న (Yesterday)', yesterdayItems),
                        _buildGroupSection('గతంలో (Older)', olderItems),
                      ],
                    ),
            ),
    );
  }
}
