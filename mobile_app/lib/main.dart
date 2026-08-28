import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/training_screen.dart';
import 'screens/voice_list_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/templates_screen.dart';
import 'screens/audio_library_screen.dart';

void main() {
  runApp(const MopideviVoiceApp());
}

class MopideviVoiceApp extends StatefulWidget {
  const MopideviVoiceApp({Key? key}) : super(key: key);

  @override
  State<MopideviVoiceApp> createState() => _MopideviVoiceAppState();
}

class _MopideviVoiceAppState extends State<MopideviVoiceApp> {
  bool _isLoggedIn = false;
  String _activeUserId = "operator_01";
  int _currentIndex = 0;

  void _performLogin() {
    setState(() => _isLoggedIn = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoggedIn) {
      return MaterialApp(
        title: 'మోపిదేవి ఆలయ AI స్వర వాణి',
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: const Color(0xFF0F172A),
          primaryColor: const Color(0xFFE5A93C),
        ),
        home: Scaffold(
          body: Center(
            child: Card(
              color: const Color(0xFF1E293B),
              margin: const EdgeInsets.all(24),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.temple_hindu, size: 64, color: Color(0xFFE5A93C)),
                    const SizedBox(height: 16),
                    const Text('MOPIDEVI TEMPLE', style: TextStyle(color: Colors.white54, letterSpacing: 2, fontSize: 13)),
                    const Text('AI VOICE APP', style: TextStyle(color: Color(0xFFE5A93C), fontWeight: FontWeight.bold, fontSize: 22)),
                    const SizedBox(height: 24),
                    DropdownButtonFormField<String>(
                      value: _activeUserId,
                      dropdownColor: const Color(0xFF0F172A),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFF0F172A),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'operator_01', child: Text('Temple Operator 1 (Operator)')),
                        DropdownMenuItem(value: 'operator_02', child: Text('Temple Operator 2 (Operator)')),
                        DropdownMenuItem(value: 'manager_01', child: Text('Voice Manager (Admin)')),
                        DropdownMenuItem(value: 'user_default', child: Text('Super Admin (Admin)')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _activeUserId = val);
                      },
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE5A93C),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: _performLogin,
                        child: const Text('[ LOGIN ]', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    final isOperator = _activeUserId.startsWith('operator');

    final List<Widget> operatorScreens = [
      HomeScreen(activeUserId: _activeUserId),
      TemplatesScreen(onSelectTemplate: (script) {
        setState(() => _currentIndex = 0);
      }),
      const AudioLibraryScreen(),
      SettingsScreen(
        activeUserId: _activeUserId,
        onUserChanged: (newId) => setState(() => _activeUserId = newId),
      ),
    ];

    final List<Widget> adminScreens = [
      HomeScreen(activeUserId: _activeUserId),
      TrainingScreen(activeUserId: _activeUserId),
      VoiceListScreen(activeUserId: _activeUserId),
      const AudioLibraryScreen(),
      SettingsScreen(
        activeUserId: _activeUserId,
        onUserChanged: (newId) => setState(() => _activeUserId = newId),
      ),
    ];

    final screens = isOperator ? operatorScreens : adminScreens;

    final operatorItems = const [
      BottomNavigationBarItem(icon: Icon(Icons.record_voice_over), label: 'ప్రకటనలు'),
      BottomNavigationBarItem(icon: Icon(Icons.description), label: 'టెంప్లేట్లు'),
      BottomNavigationBarItem(icon: Icon(Icons.library_music), label: 'ఆడియోలు'),
      BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'సెట్టింగ్లు'),
    ];

    final adminItems = const [
      BottomNavigationBarItem(icon: Icon(Icons.record_voice_over), label: 'ప్రకటనలు'),
      BottomNavigationBarItem(icon: Icon(Icons.psychology), label: 'శిక్షణ'),
      BottomNavigationBarItem(icon: Icon(Icons.graphic_eq), label: 'స్వరాలు'),
      BottomNavigationBarItem(icon: Icon(Icons.library_music), label: 'ఆడియోలు'),
      BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'సెట్టింగ్లు'),
    ];

    return MaterialApp(
      title: 'మోపిదేవి ఆలయ AI స్వర వాణి',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        primaryColor: const Color(0xFFE5A93C),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E293B),
          elevation: 4,
        ),
      ),
      home: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              const Icon(Icons.temple_hindu, color: Color(0xFFE5A93C)),
              const SizedBox(width: 10),
              Text(
                isOperator ? 'OPERATOR DASHBOARD' : 'ADMIN DASHBOARD',
                style: const TextStyle(color: Color(0xFFE5A93C), fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white70),
              onPressed: () => setState(() => _isLoggedIn = false),
            )
          ],
        ),
        body: IndexedStack(
          index: _currentIndex < screens.length ? _currentIndex : 0,
          children: screens,
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex < screens.length ? _currentIndex : 0,
          onTap: (index) => setState(() => _currentIndex = index),
          backgroundColor: const Color(0xFF1E293B),
          selectedItemColor: const Color(0xFFE5A93C),
          unselectedItemColor: Colors.white54,
          type: BottomNavigationBarType.fixed,
          items: isOperator ? operatorItems : adminItems,
        ),
      ),
    );
  }
}
