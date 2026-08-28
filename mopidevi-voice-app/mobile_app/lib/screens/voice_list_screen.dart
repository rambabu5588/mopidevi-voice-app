import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/voice_model.dart';

class VoiceListScreen extends StatefulWidget {
  final String activeUserId;
  const VoiceListScreen({Key? key, required this.activeUserId}) : super(key: key);

  @override
  State<VoiceListScreen> createState() => _VoiceListScreenState();
}

class _VoiceListScreenState extends State<VoiceListScreen> {
  List<VoiceModel> _voices = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVoices();
  }

  Future<void> _loadVoices() async {
    try {
      final list = await ApiService.fetchVoices(userId: widget.activeUserId);
      setState(() {
        _voices = list;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator(color: Color(0xFFE5A93C)))
        : ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: _voices.length,
            itemBuilder: (context, index) {
              final voice = _voices[index];
              return Card(
                color: const Color(0xFF1E293B),
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFFE5A93C),
                    child: Icon(
                      voice.voiceType == 'system' ? Icons.mic : Icons.person_pin,
                      color: Colors.black,
                    ),
                  ),
                  title: Text(voice.voiceName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: Text('రకం: ${voice.voiceType.toUpperCase()} | రికార్డు ఐడీ: ${voice.id}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  trailing: Chip(
                    label: Text(voice.qualityScore, style: const TextStyle(fontSize: 11)),
                    backgroundColor: const Color(0xFF0F172A),
                  ),
                ),
              );
            },
          );
  }
}
