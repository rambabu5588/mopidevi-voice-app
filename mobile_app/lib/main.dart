import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/training_screen.dart';
import 'screens/voice_list_screen.dart';
import 'screens/settings_screen.dart';

void main() {
  runApp(const MopideviVoiceApp());
}

class MopideviVoiceApp extends StatefulWidget {
  const MopideviVoiceApp({Key? key}) : super(key: key);

  @override
  State<MopideviVoiceApp> createState() => _MopideviVoiceAppState();
}

class _MopideviVoiceAppState extends State<MopideviVoiceApp> {
  String _activeUserId = "operator_01";
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      HomeScreen(activeUserId: _activeUserId),
      TrainingScreen(activeUserId: _activeUserId),
      VoiceListScreen(activeUserId: _activeUserId),
      SettingsScreen(
        activeUserId: _activeUserId,
        onUserChanged: (newId) => setState(() => _activeUserId = newId),
      ),
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
            children: const [
              Icon(Icons.temple_hindu, color: Color(0xFFE5A93C)),
              SizedBox(width: 10),
              Text('మోపిదేవి AI స్వర వాణి', style: TextStyle(color: Color(0xFFE5A93C), fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
        ),
        body: IndexedStack(
          index: _currentIndex,
          children: screens,
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          backgroundColor: const Color(0xFF1E293B),
          selectedItemColor: const Color(0xFFE5A93C),
          unselectedItemColor: Colors.white54,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.record_voice_over), label: 'ప్రకటనలు'),
            BottomNavigationBarItem(icon: Icon(Icons.psychology), label: 'శిక్షణ'),
            BottomNavigationBarItem(icon: Icon(Icons.graphic_eq), label: 'స్వరాలు'),
            BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'సెట్టింగ్లు'),
          ],
        ),
      ),
    );
  }
}
