import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/biometric_service.dart';
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
  bool _isBiometricSupported = false;
  bool _isBiometricEnabled = false;
  String _savedBiometricUser = '';

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    final supported = await BiometricService.isDeviceSupported();
    final enabled = await BiometricService.isBiometricEnabled();
    final creds = await BiometricService.getSavedCredentials();
    if (mounted) {
      setState(() {
        _isBiometricSupported = supported;
        _isBiometricEnabled = enabled;
        _savedBiometricUser = creds?['userName'] ?? creds?['userId'] ?? '';
      });
    }
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

  void _showChangePasswordDialog() {
    final currentPassController = TextEditingController();
    final newPassController = TextEditingController();
    final confirmPassController = TextEditingController();
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E293B),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: const [
                  Icon(Icons.lock_reset, color: Color(0xFFE5A93C)),
                  SizedBox(width: 10),
                  Text('పాస్‌వర్డ్ మార్చుకోండి', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: currentPassController,
                      obscureText: true,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'ప్రస్తుత పాస్‌వర్డ్ (Current Password)*',
                        labelStyle: const TextStyle(color: Colors.white70),
                        filled: true,
                        fillColor: const Color(0xFF0F172A),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: newPassController,
                      obscureText: true,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'కొత్త పాస్‌వర్డ్ (New Password)*',
                        labelStyle: const TextStyle(color: Colors.white70),
                        filled: true,
                        fillColor: const Color(0xFF0F172A),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: confirmPassController,
                      obscureText: true,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'కొత్త పాస్‌వర్డ్ నిర్ధారణ (Confirm New Password)*',
                        labelStyle: const TextStyle(color: Colors.white70),
                        filled: true,
                        fillColor: const Color(0xFF0F172A),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (isSaving)
                      const CircularProgressIndicator(color: Color(0xFFE5A93C)),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('రద్దు (Cancel)', style: TextStyle(color: Colors.white54)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE5A93C),
                    foregroundColor: Colors.black,
                  ),
                  onPressed: isSaving
                      ? null
                      : () async {
                          final currentPass = currentPassController.text.trim();
                          final newPass = newPassController.text.trim();
                          final confirmPass = confirmPassController.text.trim();

                          if (currentPass.isEmpty || newPass.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('దయచేసి అన్ని ఫీల్డ్‌లను నమోదు చేయండి')),
                            );
                            return;
                          }

                          if (newPass != confirmPass) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('కొత్త పాస్‌వర్డ్ సరిపోలలేదు')),
                            );
                            return;
                          }

                          setDialogState(() => isSaving = true);
                          try {
                            final res = await ApiService.changePassword(
                              userId: widget.activeUserId,
                              currentPassword: currentPass,
                              newPassword: newPass,
                            );

                            // Also update biometric credentials if active user matches saved biometric user
                            final creds = await BiometricService.getSavedCredentials();
                            if (creds != null && (creds['userId'] == widget.activeUserId || creds['userId'] == (res['user_id'] ?? ''))) {
                              await BiometricService.saveBiometricCredentials(
                                userId: creds['userId'] ?? widget.activeUserId,
                                userName: creds['userName'] ?? widget.activeUserId,
                                role: creds['role'] ?? 'operator',
                                password: newPass,
                                isAdmin: creds['isAdmin'] ?? false,
                              );
                            }

                            Navigator.pop(ctx);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  backgroundColor: Color(0xFF166534),
                                  content: Text('✓ పాస్‌వర్డ్ విజయవంతంగా డేటాబేస్ లో సేవ్ చేయబడింది!'),
                                ),
                              );
                            }
                          } catch (e) {
                            setDialogState(() => isSaving = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('పాస్‌వర్డ్ మార్పు విఫలమైంది: $e')),
                            );
                          }
                        },
                  child: const Text('సేవ్ చేయండి (Save)', style: TextStyle(fontWeight: FontWeight.bold)),
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
                  const Text('👤 వినియోగదారు ఖాతా (Active Account)', style: TextStyle(color: Color(0xFFE5A93C), fontWeight: FontWeight.bold, fontSize: 15)),
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

          // 2. Change Password Card
          Card(
            color: const Color(0xFF1E293B),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.lock_outline, color: Color(0xFFE5A93C), size: 20),
                      SizedBox(width: 8),
                      Text('🔐 పాస్‌వర్డ్ భద్రత (Password & Security)', style: TextStyle(color: Color(0xFFE5A93C), fontWeight: FontWeight.bold, fontSize: 15)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'మీ ఖాతా పాస్‌వర్డ్ మార్చుకోవడానికి మీ ప్రస్తుత పాస్‌వర్డ్ నమోదు చేసి కొత్త పాస్‌వర్డ్ సెట్ చేసుకోండి.',
                    style: TextStyle(color: Colors.white60, fontSize: 12, height: 1.4),
                  ),
                  const SizedBox(height: 14),
                  ElevatedButton.icon(
                    onPressed: _showChangePasswordDialog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F172A),
                      foregroundColor: const Color(0xFFE5A93C),
                      side: const BorderSide(color: Color(0xFFE5A93C), width: 1.2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    ),
                    icon: const Icon(Icons.password, size: 18),
                    label: const Text('పాస్‌వర్డ్ మార్చుకోండి (Change Password)', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 3. Biometric Fingerprint Security Card
          Card(
            color: const Color(0xFF1E293B),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.fingerprint, color: Color(0xFFE5A93C), size: 22),
                      SizedBox(width: 8),
                      Text('🔒 వేలిముద్ర లాగిన్ (Biometric Login)', style: TextStyle(color: Color(0xFFE5A93C), fontWeight: FontWeight.bold, fontSize: 15)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'యాప్ ప్రారంభించిన వెంటనే పాస్‌వర్డ్ లేకుండా వేలిముద్రతో నేరుగా లాగిన్ అవ్వడానికి ఈ ఆప్షన్‌ను ప్రారంభించండి.',
                    style: TextStyle(color: Colors.white60, fontSize: 12, height: 1.4),
                  ),
                  const SizedBox(height: 12),
                  if (!_isBiometricSupported)
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.amber, size: 18),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'ఈ పరికరంలో బయోమెట్రిక్ / వేలిముద్ర సెన్సార్ అందుబాటులో లేదు లేదా కాన్ఫిగర్ చేయబడలేదు.',
                              style: TextStyle(color: Colors.amber, fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('వేలిముద్ర లాగిన్ యాక్టివ్ చేయండి', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                      subtitle: Text(
                        _isBiometricEnabled
                            ? (_savedBiometricUser.isNotEmpty ? 'కనెక్ట్ చేయబడిన ఖాతా: $_savedBiometricUser' : 'యాక్టివ్ లో ఉంది (Enabled)')
                            : 'ప్రస్తుతం డిజేబుల్ చేయబడింది (Disabled)',
                        style: TextStyle(color: _isBiometricEnabled ? const Color(0xFF4ADE80) : Colors.white38, fontSize: 12),
                      ),
                      value: _isBiometricEnabled,
                      activeThumbColor: const Color(0xFFE5A93C),
                      onChanged: (val) async {
                        if (val) {
                          final authSuccess = await BiometricService.authenticate(
                            reason: 'వేలిముద్ర లాగిన్ ప్రారంభించడానికి మీ వేలిముద్రను స్కాన్ చేయండి',
                          );
                          if (authSuccess) {
                            final activeUser = _users.firstWhere(
                              (u) => u.id == widget.activeUserId,
                              orElse: () => SystemUser(
                                id: widget.activeUserId,
                                name: widget.activeUserId,
                                role: 'operator',
                                status: 'Active',
                                createdAt: 0.0,
                              ),
                            );
                            await BiometricService.saveBiometricCredentials(
                              userId: widget.activeUserId,
                              userName: activeUser.name,
                              password: 'User\$1234',
                              isAdmin: (activeUser.role == 'super_admin' || activeUser.role == 'voice_manager' || widget.activeUserId == 'sid'),
                            );
                            await _checkBiometrics();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('✓ బయోమెట్రిక్ లాగిన్ విజయవంతంగా ప్రారంభించబడింది!')),
                              );
                            }
                          } else {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('బయోమెట్రిక్ ప్రమాణీకరణ విఫలమైంది')),
                              );
                            }
                          }
                        } else {
                          await BiometricService.disableBiometrics();
                          await _checkBiometrics();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('బయోమెట్రిక్ లాగిన్ నిలిపివేయబడింది')),
                            );
                          }
                        }
                      },
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 4. Server IP Address Config
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
                      hintText: 'https://mopidevi-voice-app.onrender.com',
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
