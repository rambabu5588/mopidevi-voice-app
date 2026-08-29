import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../services/api_service.dart';
import '../models/voice_model.dart';
import '../models/job_model.dart';
import '../models/task_model.dart';
import 'task_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  final String activeUserId;
  final Function(int)? onNavigateTab;

  const HomeScreen({
    Key? key,
    required this.activeUserId,
    this.onNavigateTab,
  }) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _scriptController = TextEditingController(
    text: "ఉదయం 10:30 AM గంటలకు సర్పదోష నివారణ అభిషేకం మరియు సహస్రనామార్చన పూజ ప్రారంభమగును.",
  );

  List<VoiceModel> _voices = [];
  String? _selectedVoiceId;
  String _selectedStyle = "Devotional";
  bool _isGenerating = false;
  int _progress = 0;
  String _stepText = "";
  AnnouncementJob? _completedJob;

  Map<String, dynamic>? _profileSummary;
  List<UserTask> _userTasks = [];

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;

  final List<Map<String, String>> _styles = [
    {"name": "Devotional", "title": "🙏 భక్తిపూర్వక", "sub": "ప్రశాంత దైవిక శైలి"},
    {"name": "Announcement", "title": "📢 ప్రకటనా శైలి", "sub": "స్పష్టమైన మైక్ శైలి"},
    {"name": "Warm", "title": "❤️ ఆప్యాయత", "sub": "ఆత్మీయ మృదువైన శైలి"},
    {"name": "Important", "title": "⚠️ ముఖ్యమైన", "sub": "గంభీర హెచ్చరిక శైలి"},
    {"name": "Festival", "title": "🎉 ఉత్సవ శైలి", "sub": "ఆనందకర పండుగ శైలి"},
    {"name": "Spiritual", "title": "🕉️ వేద శైలి", "sub": "పండిత వేద శైలి"},
  ];

  final List<Map<String, String>> _templates = [
    {
      "title": "🐍 సర్పదోష పూజ",
      "script": "ఉదయం 10:30 AM గంటలకు సర్పదోష నివారణ అభిషేకం మరియు సహస్రనామార్చన పూజ ప్రారంభమగును."
    },
    {
      "title": "🙏 స్వాగతం",
      "script": "శ్రీ మోపిదేవి సుబ్రహ్మణ్యేశ్వర స్వామి వారి దివ్య క్షేత్రానికి విచ్చేసిన భక్తులందరికీ హృదయపూర్వక స్వాగతం."
    },
    {
      "title": "🛕 దర్శనం సమాచారం",
      "script": "భక్తులు అందరూ లైనులో ప్రశాంతంగా వెళ్ళి నాగేంద్రస్వామి వారి దివ్య దర్శనం చేసుకోవాల్సిందిగా మనవి."
    },
    {
      "title": "🍚 ప్రసాదం వితరణ",
      "script": "స్వామివారి పవిత్ర తీర్థప్రసాదములు ప్రాంగణము వెనుక భాగాన వితరణ చేయబడుచున్నవి."
    },
    {
      "title": "🎉 ఉత్సవ ప్రకటన",
      "script": "శ్రీ సుబ్రహ్మణ్య షష్ఠి మహోత్సవాల సందర్భంగా ప్రత్యేక హారతి మరియు కళ్యాణం నిర్వహించబడును."
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _audioPlayer.onPlayerStateChanged.listen((state) {
      setState(() => _isPlaying = state == PlayerState.playing);
    });
  }

  Future<void> _loadInitialData() async {
    try {
      final voices = await ApiService.fetchVoices(userId: widget.activeUserId);
      final assignedData = await ApiService.fetchUserAssignedVoice(widget.activeUserId);
      final profile = await ApiService.fetchUserProfileSummary(widget.activeUserId);
      final tasks = await ApiService.fetchUserTasks(widget.activeUserId);

      setState(() {
        _voices = voices;
        _selectedVoiceId = assignedData['assigned_voice_id'] ?? (_voices.isNotEmpty ? _voices.first.id : null);
        _profileSummary = profile;
        _userTasks = tasks;
      });
    } catch (e) {
      debugPrint('Failed to load initial data: $e');
    }
  }

  Future<void> _generateAnnouncement() async {
    final script = _scriptController.text.trim();
    if (script.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('దయచేసి తెలుగు వ్యాఖ్యానం నమోదు చేయండి!')),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
      _progress = 5;
      _stepText = "ప్రకటన రికార్డు సృష్టించబడుతోంది...";
      _completedJob = null;
    });

    try {
      final job = await ApiService.generateAnnouncement(
        userId: widget.activeUserId,
        voiceId: _selectedVoiceId ?? 'voice_te_male_1',
        teluguScript: script,
        style: _selectedStyle,
      );

      _pollProgress(job.id);
    } catch (e) {
      setState(() => _isGenerating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Generation failed: $e')),
      );
    }
  }

  Future<void> _pollProgress(String jobId) async {
    bool done = false;
    while (!done) {
      await Future.delayed(const Duration(seconds: 1));
      try {
        final job = await ApiService.getJobStatus(jobId);
        setState(() {
          _progress = job.progressPercent;
          _stepText = job.currentStep;
        });

        if (job.status == 'COMPLETED' || job.status == 'FAILED') {
          done = true;
          setState(() {
            _isGenerating = false;
            _completedJob = job;
          });
        }
      } catch (e) {
        done = true;
        setState(() => _isGenerating = false);
      }
    }
  }

  void _togglePlayAudio() async {
    if (_completedJob?.outputAudioPath == null) return;
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      final url = '${ApiService.baseUrl}${_completedJob!.outputAudioPath}';
      await _audioPlayer.play(UrlSource(url));
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _scriptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pendingTasks = _userTasks.where((t) => t.status != 'COMPLETED').toList();
    final operatorName = _profileSummary?['name'] ?? 'Mopidevi User';
    final voiceVersion = _profileSummary?['active_version'] ?? 'v1.1';

    return RefreshIndicator(
      onRefresh: _loadInitialData,
      color: const Color(0xFFE5A93C),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // User Greeting Banner & Voice Pill
            Card(
              color: const Color(0xFF1E293B),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: Color(0xFFE5A93C),
                      radius: 22,
                      child: Icon(Icons.person, color: Colors.black, size: 26),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'శుభోదయం, $operatorName 👋',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Text('స్వరం (Voice): ', style: TextStyle(color: Colors.white60, fontSize: 12)),
                              Text(
                                '🟢 Ready ($voiceVersion)',
                                style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Task Notification Banner
            if (pendingTasks.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE5A93C).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5A93C).withOpacity(0.5)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.notifications_active, color: Color(0xFFE5A93C), size: 20),
                        const SizedBox(width: 8),
                        Text(
                          '🔔 కొత్త టాస్క్‌లు (NEW TASKS): ${pendingTasks.length}',
                          style: const TextStyle(color: Color(0xFFE5A93C), fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
                    if (widget.onNavigateTab != null)
                      TextButton(
                        onPressed: () => widget.onNavigateTab!(1), // Go to Tasks Tab
                        style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(60, 24)),
                        child: const Text('అన్నీ చూడు (View All) →', style: TextStyle(color: Colors.white, fontSize: 12)),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Task Action Card (e.g. 12-Word Voice Improvement)
              Card(
                color: const Color(0xFF1E293B),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              pendingTasks.first.title,
                              style: const TextStyle(color: Color(0xFFE5A93C), fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F172A),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${pendingTasks.first.completedItems}/${pendingTasks.first.totalItems} పదాలు',
                              style: const TextStyle(color: Colors.white70, fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        pendingTasks.first.description ?? 'మీ స్వర నాణ్యత మెరుగుపరచడానికి పదాలను రికార్డ్ చేయండి.',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TaskDetailScreen(
                                taskId: pendingTasks.first.id,
                                activeUserId: widget.activeUserId,
                                onTaskCompleted: _loadInitialData,
                              ),
                            ),
                          ).then((_) => _loadInitialData());
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE5A93C),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: const Icon(Icons.mic, size: 18),
                        label: const Text('START TASK (ప్రారంభించు)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
            ] else ...[
              // No pending tasks card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.greenAccent.withOpacity(0.4)),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.check_circle, color: Colors.greenAccent, size: 22),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '🎉 పెండింగ్ టాస్క్‌లు లేవు. మీ వాయిస్ సిద్ధంగా ఉంది (Voice Ready).',
                        style: TextStyle(color: Colors.greenAccent, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],

            // 1. Script Input Card with Quick Templates
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
                        const Text(
                          '1. తెలుగు వ్యాఖ్యానం (Telugu Announcement)',
                          style: TextStyle(color: Color(0xFFE5A93C), fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        TextButton(
                          onPressed: () => _scriptController.clear(),
                          style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(50, 30)),
                          child: const Text('క్లియర్ (Clear)', style: TextStyle(color: Colors.white38, fontSize: 11)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Quick Template Pills
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _templates.map((tpl) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0, bottom: 8.0),
                            child: ActionChip(
                              backgroundColor: const Color(0xFF0F172A),
                              side: const BorderSide(color: Color(0xFFE5A93C), width: 0.8),
                              label: Text(tpl['title']!, style: const TextStyle(color: Color(0xFFE5A93C), fontSize: 11, fontWeight: FontWeight.w600)),
                              onPressed: () {
                                setState(() {
                                  _scriptController.text = tpl['script']!;
                                });
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _scriptController,
                      maxLines: 4,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFF0F172A),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        hintText: 'ఆలయ వ్యాఖ్యానం ఇక్కడ నమోదు చేయండి...',
                        hintStyle: const TextStyle(color: Colors.white38),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // 2. Style Selector Card
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
                        const Text(
                          '2. ధ్వని శైలి (Select Delivery Style)',
                          style: TextStyle(color: Color(0xFFE5A93C), fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        Text(
                          'లభ్యమైన స్వరాలు: ${_voices.length}',
                          style: const TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 2.3,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: _styles.length,
                      itemBuilder: (context, idx) {
                        final item = _styles[idx];
                        final isSelected = _selectedStyle == item['name'];
                        return InkWell(
                          onTap: () => setState(() => _selectedStyle = item['name']!),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFF334155) : const Color(0xFF0F172A),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected ? const Color(0xFFE5A93C) : Colors.transparent,
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(item['title']!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                Text(item['sub']!, style: const TextStyle(color: Colors.white54, fontSize: 11)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 3. Generate Button
            ElevatedButton.icon(
              onPressed: _isGenerating ? null : _generateAnnouncement,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE5A93C),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.flash_on),
              label: const Text('ధ్వనిని సృష్టించండి (GENERATE VOICE)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ),
            const SizedBox(height: 16),

            // 4. Progress or Completed Audio Player
            if (_isGenerating)
              Card(
                color: const Color(0xFF1E293B),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      LinearProgressIndicator(value: _progress / 100.0, color: const Color(0xFFE5A93C)),
                      const SizedBox(height: 12),
                      Text(_stepText, style: const TextStyle(color: Colors.white70)),
                      Text('$_progress%', style: const TextStyle(color: Color(0xFFE5A93C), fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),

            if (_completedJob != null && !_isGenerating)
              Card(
                color: const Color(0xFF1E293B),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Text('✓ ఆడియో సిద్ధమైంది (Voice Generated)', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 15)),
                          Icon(Icons.check_circle, color: Colors.greenAccent, size: 20),
                        ],
                      ),
                      const SizedBox(height: 12),
                      IconButton(
                        iconSize: 52,
                        color: const Color(0xFFE5A93C),
                        icon: Icon(_isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill),
                        onPressed: _togglePlayAudio,
                      ),
                      Text(_isPlaying ? 'ప్లే అవుతోంది...' : 'ఆడియో ప్లే చేయడానికి నొక్కండి', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          TextButton.icon(
                            onPressed: _generateAnnouncement,
                            icon: const Icon(Icons.refresh, size: 16),
                            label: const Text('పునఃసృష్టి (Regenerate)'),
                            style: TextButton.styleFrom(foregroundColor: const Color(0xFFE5A93C)),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('వ్యాఖ్యానాన్ని సవరించడానికి పై టెక్స్ట్‌బాక్స్ వాడండి.')),
                              );
                            },
                            icon: const Icon(Icons.edit, size: 16),
                            label: const Text('సవరణ (Edit)'),
                            style: TextButton.styleFrom(foregroundColor: Colors.white70),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
