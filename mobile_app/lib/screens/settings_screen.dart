import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/user_model.dart';

class SettingsScreen extends StatefulWidget {
  final String activeUserId;
  final Function(String) onUserChanged;

  const SettingsScreen({
    Key? key,
    required this.activeUserId,
    required this.onUserChanged,
  }) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _urlController = TextEditingController(text: ApiService.baseUrl);
  List<SystemUser> _users = [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      final list = await ApiService.fetchUsers();
      setState(() => _users = list);
    } catch (e) {
      debugPrint('Failed to load users: $e');
    }
  }

  void _saveServerUrl() {
    final url = _urlController.text.trim();
    if (url.isNotEmpty) {
      ApiService.setBaseUrl(url);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('సర్వర్ చిరునామా సేవ్ చేయబడింది: $url')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Account Switcher Card
          Card(
            color: const Color(0xFF1E293B),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('👤 వినియోగదారు ఖాతా మార్పు (Select Account)', style: TextStyle(color: Color(0xFFE5A93C), fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: widget.activeUserId,
                    dropdownColor: const Color(0xFF0F172A),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    items: _users.map((u) {
                      return DropdownMenuItem<String>(
                        value: u.id,
                        child: Text('${u.name} (${u.role.toUpperCase()})'),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) widget.onUserChanged(val);
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 2. Server IP Address Config
          Card(
            color: const Color(0xFF1E293B),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('🌐 బ్యాకెండ్ సర్వర్ IP చిరునామా (Backend Server URL)', style: TextStyle(color: Color(0xFFE5A93C), fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _urlController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      hintText: 'http://192.168.1.5:8000',
                      hintStyle: const TextStyle(color: Colors.white38),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _saveServerUrl,
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE5A93C), foregroundColor: Colors.black),
                    child: const Text('చిరునామా సేవ్ చేయండి'),
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
