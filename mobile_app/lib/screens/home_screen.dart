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
  bool _isStudioOpen = false;

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
    final voiceName = _profileSummary?['voice_name'] ?? 'తెలుగు గుడి ప్రకటన స్వరము 2';

    return RefreshIndicator(
      onRefresh: _loadInitialData,
      color: const Color(0xFFE5A93C),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // -------------------------------------------------------------
            // 1. GREETING HEADER (Good Morning, User 👋)
            // -------------------------------------------------------------
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF334155)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFBBF24), Color(0xFFE5A93C)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFE5A93C).withValues(alpha: 0.4),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.temple_hindu, color: Colors.black, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Good Morning, $operatorName 👋',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 3),
                        const Text(
                          'మోపిదేవి దేవస్థానం AI స్వర వేదిక',
                          style: TextStyle(color: Colors.white60, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // -------------------------------------------------------------
            // 2. NOTIFICATION BADGE: 🔔 NEW TASKS: X
            // -------------------------------------------------------------
            if (pendingTasks.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE5A93C).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5A93C).withValues(alpha: 0.6), width: 1.2),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.notifications_active, color: Color(0xFFE5A93C), size: 22),
                        const SizedBox(width: 10),
                        Text(
                          '🔔 NEW TASKS: ${pendingTasks.length}',
                          style: const TextStyle(
                            color: Color(0xFFE5A93C),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    if (widget.onNavigateTab != null)
                      InkWell(
                        onTap: () => widget.onNavigateTab!(1),
                        child: Row(
                          children: const [
                            Text(
                              'View All',
                              style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            Icon(Icons.chevron_right, color: Colors.white, size: 16),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // -------------------------------------------------------------
              // 3. ACTION CARD 1: 🎙 VOICE IMPROVEMENT
              // -------------------------------------------------------------
              Card(
                color: const Color(0xFF1E293B),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Color(0xFF334155)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE5A93C).withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.mic, color: Color(0xFFE5A93C), size: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '🎙 VOICE IMPROVEMENT',
                                  style: TextStyle(
                                    color: Color(0xFFE5A93C),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Record ${pendingTasks.first.totalItems} required words',
                                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F172A),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${pendingTasks.first.completedItems}/${pendingTasks.first.totalItems}',
                              style: const TextStyle(color: Color(0xFFE5A93C), fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      LinearProgressIndicator(
                        value: pendingTasks.first.progressPercent,
                        backgroundColor: const Color(0xFF0F172A),
                        color: const Color(0xFFE5A93C),
                        minHeight: 6,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
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
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 2,
                          ),
                          icon: const Icon(Icons.play_arrow, size: 20),
                          label: const Text(
                            '[ START TASK ]',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 0.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
            ] else ...[
              // -------------------------------------------------------------
              // NO PENDING TASKS CARD (🎉 No pending tasks. Your voice is ready.)
              // -------------------------------------------------------------
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.5), width: 1.2),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.celebration, color: Colors.black, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            '🎉 No pending tasks',
                            style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Your voice is ready for announcements.',
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],

            // -------------------------------------------------------------
            // 4. ACTION CARD 2: 📢 ANNOUNCEMENT
            // -------------------------------------------------------------
            Card(
              color: const Color(0xFF1E293B),
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: _isStudioOpen ? const Color(0xFFE5A93C) : const Color(0xFF334155),
                  width: _isStudioOpen ? 1.5 : 1.0,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.campaign, color: Color(0xFFE5A93C), size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                '📢 ANNOUNCEMENT',
                                style: TextStyle(
                                  color: Color(0xFFE5A93C),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                "Generate today's message",
                                style: TextStyle(color: Colors.white70, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          setState(() => _isStudioOpen = !_isStudioOpen);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isStudioOpen ? const Color(0xFF334155) : const Color(0xFFE5A93C),
                          foregroundColor: _isStudioOpen ? Colors.white : Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: Icon(_isStudioOpen ? Icons.expand_less : Icons.edit_note, size: 20),
                        label: Text(
                          _isStudioOpen ? 'CLOSE STUDIO (స్టూడియో ముగించు)' : '[ OPEN TASK ]',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 0.5),
                        ),
                      ),
                    ),

                    // -------------------------------------------------------------
                    // INLINE ANNOUNCEMENT GENERATOR STUDIO (WHEN OPENED)
                    // -------------------------------------------------------------
                    if (_isStudioOpen) ...[
                      const SizedBox(height: 18),
                      const Divider(color: Color(0xFF334155)),
                      const SizedBox(height: 10),

                      // Quick Templates
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'ఆలయ టెంప్లేట్లు (Templates):',
                            style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          TextButton(
                            onPressed: () => _scriptController.clear(),
                            style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(40, 20)),
                            child: const Text('క్లియర్', style: TextStyle(color: Colors.white38, fontSize: 11)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _templates.map((tpl) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0, bottom: 6.0),
                              child: ActionChip(
                                backgroundColor: const Color(0xFF0F172A),
                                side: const BorderSide(color: Color(0xFFE5A93C), width: 0.8),
                                label: Text(
                                  tpl['title']!,
                                  style: const TextStyle(color: Color(0xFFE5A93C), fontSize: 11, fontWeight: FontWeight.w600),
                                ),
                                onPressed: () {
                                  setState(() => _scriptController.text = tpl['script']!);
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Telugu Script Text Box
                      TextField(
                        controller: _scriptController,
                        maxLines: 3,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color(0xFF0F172A),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          hintText: 'ఆలయ వ్యాఖ్యానం ఇక్కడ నమోదు చేయండి...',
                          hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Style Selector
                      const Text(
                        'ధ్వని శైలి (Speaking Style):',
                        style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 2.5,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: _styles.length,
                        itemBuilder: (context, idx) {
                          final item = _styles[idx];
                          final isSelected = _selectedStyle == item['name'];
                          return InkWell(
                            onTap: () => setState(() => _selectedStyle = item['name']!),
                            child: Container(
                              padding: const EdgeInsets.all(6),
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
                                  Text(item['title']!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                                  Text(item['sub']!, style: const TextStyle(color: Colors.white54, fontSize: 10)),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 14),

                      // Generate Voice Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isGenerating ? null : _generateAnnouncement,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE5A93C),
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.flash_on, size: 18),
                          label: const Text('ధ్వనిని సృష్టించండి (GENERATE)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                      ),

                      // Progress / Audio Player Result
                      if (_isGenerating) ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            children: [
                              LinearProgressIndicator(value: _progress / 100.0, color: const Color(0xFFE5A93C)),
                              const SizedBox(height: 8),
                              Text(_stepText, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                              Text('$_progress%', style: const TextStyle(color: Color(0xFFE5A93C), fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],

                      if (_completedJob != null && !_isGenerating) ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.5)),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: const [
                                  Text('✓ ఆడియో సిద్ధమైంది (Generated)', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                                  Icon(Icons.check_circle, color: Colors.greenAccent, size: 18),
                                ],
                              ),
                              const SizedBox(height: 8),
                              IconButton(
                                iconSize: 46,
                                color: const Color(0xFFE5A93C),
                                icon: Icon(_isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill),
                                onPressed: _togglePlayAudio,
                              ),
                              Text(_isPlaying ? 'ప్లే అవుతోంది...' : 'ఆడియో ప్లే చేయడానికి నొక్కండి', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  TextButton.icon(
                                    onPressed: _generateAnnouncement,
                                    icon: const Icon(Icons.refresh, size: 14),
                                    label: const Text('పునఃసృష్టి (Regenerate)'),
                                    style: TextButton.styleFrom(foregroundColor: const Color(0xFFE5A93C)),
                                  ),
                                  if (widget.onNavigateTab != null)
                                    TextButton.icon(
                                      onPressed: () => widget.onNavigateTab!(2), // Audio Tab
                                      icon: const Icon(Icons.library_music, size: 14),
                                      label: const Text('లైబ్రరీలో చూడు'),
                                      style: TextButton.styleFrom(foregroundColor: Colors.white70),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // -------------------------------------------------------------
            // 5. VOICE STATUS FOOTER PILL (Voice: 🟢 Ready)
            // -------------------------------------------------------------
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.record_voice_over, color: Color(0xFFE5A93C), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Voice: $voiceName',
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.greenAccent, width: 0.8),
                    ),
                    child: Text(
                      '🟢 Ready ($voiceVersion)',
                      style: const TextStyle(
                        color: Colors.greenAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
