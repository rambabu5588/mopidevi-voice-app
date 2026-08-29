import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/biometric_service.dart';

class ProfileScreen extends StatefulWidget {
  final String activeUserId;
  final VoidCallback onLogout;

  const ProfileScreen({
    Key? key,
    required this.activeUserId,
    required this.onLogout,
  }) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiService.fetchUserProfileSummary(widget.activeUserId);
      setState(() {
        _profile = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _showChangePasswordDialog() {
    final curCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confCtrl = TextEditingController();
    bool isChanging = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDlgState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E293B),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: const [
                  Icon(Icons.lock_reset, color: Color(0xFFE5A93C)),
                  SizedBox(width: 10),
                  Text('పాస్‌వర్డ్ మార్చుకోండి', style: TextStyle(color: Color(0xFFE5A93C), fontSize: 16)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: curCtrl,
                    obscureText: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'పాత పాస్‌వర్డ్ (Current)',
                      labelStyle: const TextStyle(color: Colors.white70),
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: newCtrl,
                    obscureText: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'కొత్త పాస్‌వర్డ్ (New Password)',
                      labelStyle: const TextStyle(color: Colors.white70),
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: confCtrl,
                    obscureText: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'నిర్ధారణ (Confirm New Password)',
                      labelStyle: const TextStyle(color: Colors.white70),
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('రద్దు (Cancel)', style: TextStyle(color: Colors.white54)),
                ),
                ElevatedButton(
                  onPressed: isChanging
                      ? null
                      : () async {
                          final current = curCtrl.text.trim();
                          final newP = newCtrl.text.trim();
                          final conf = confCtrl.text.trim();

                          if (current.isEmpty || newP.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('దయచేసి అన్ని ఫీల్డులను నమోదు చేయండి')),
                            );
                            return;
                          }
                          if (newP != conf) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('కొత్త పాస్‌వర్డ్ సరిపోలడం లేదు')),
                            );
                            return;
                          }

                          setDlgState(() => isChanging = true);
                          try {
                            await ApiService.changePassword(
                              userId: widget.activeUserId,
                              currentPassword: current,
                              newPassword: newP,
                            );

                            final saved = await BiometricService.getSavedCredentials();
                            if (saved != null && saved['userId'] == widget.activeUserId) {
                              await BiometricService.saveBiometricCredentials(
                                userId: widget.activeUserId,
                                userName: _profile?['name'] ?? widget.activeUserId,
                                password: newP,
                                isAdmin: false,
                                role: 'operator',
                              );
                            }

                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('✓ పాస్‌వర్డ్ విజయవంతంగా మార్చబడింది!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          } catch (e) {
                            setDlgState(() => isChanging = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('మార్పు విఫలమైంది: $e'), backgroundColor: Colors.red),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE5A93C),
                    foregroundColor: Colors.black,
                  ),
                  child: const Text('సేవ్ చేయండి (SAVE)', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('నా ప్రొఫైల్ (My Profile)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFE5A93C)))
          : RefreshIndicator(
              onRefresh: _loadProfile,
              color: const Color(0xFFE5A93C),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Avatar & Name Card
                    Card(
                      color: const Color(0xFF1E293B),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          children: [
                            const CircleAvatar(
                              radius: 36,
                              backgroundColor: Color(0xFFE5A93C),
                              child: Icon(Icons.person, size: 44, color: Colors.black),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _profile?['name'] ?? 'Mopidevi Operator',
                              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.greenAccent, width: 1),
                              ),
                              child: Text(
                                'ఖాతా స్థితి: ${_profile?['status'] ?? 'Active 🟢'}',
                                style: const TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Details Card
                    Card(
                      color: const Color(0xFF1E293B),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            _buildInfoTile(
                              icon: Icons.record_voice_over,
                              label: 'కేటాయించిన స్వరం (Voice)',
                              value: _profile?['voice_name'] ?? 'తెలుగు గుడి ప్రకటన స్వరము',
                            ),
                            const Divider(color: Color(0xFF334155)),
                            _buildInfoTile(
                              icon: Icons.auto_awesome,
                              label: 'స్వర నమూనా వెర్షన్ (Model Version)',
                              value: '${_profile?['active_version'] ?? 'v1.0'} (${_profile?['voice_status'] ?? '🟢 Ready'})',
                              valueColor: Colors.greenAccent,
                            ),
                            const Divider(color: Color(0xFF334155)),
                            _buildInfoTile(
                              icon: Icons.assignment_late,
                              label: 'పెండింగ్ టాస్క్‌లు (Pending Tasks)',
                              value: '${_profile?['pending_tasks_count'] ?? 0} కార్యం(లు)',
                              valueColor: const Color(0xFFE5A93C),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Change Password Action
                    Card(
                      color: const Color(0xFF1E293B),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: const Icon(Icons.lock_reset, color: Color(0xFFE5A93C)),
                        title: const Text('పాస్‌వర్డ్ మార్చుకోండి (Change Password)', style: TextStyle(color: Colors.white, fontSize: 14)),
                        trailing: const Icon(Icons.chevron_right, color: Colors.white54),
                        onTap: _showChangePasswordDialog,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Logout Action
                    Card(
                      color: const Color(0xFF1E293B),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: const Icon(Icons.logout, color: Colors.redAccent),
                        title: const Text('లాగౌట్ (Logout)', style: TextStyle(color: Colors.redAccent, fontSize: 14, fontWeight: FontWeight.bold)),
                        trailing: const Icon(Icons.chevron_right, color: Colors.white54),
                        onTap: widget.onLogout,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
    Color valueColor = Colors.white,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFE5A93C), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
          ),
          Text(value, style: TextStyle(color: valueColor, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }
}
