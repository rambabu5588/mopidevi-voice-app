import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/user_management_screen.dart';
import 'screens/templates_screen.dart';
import 'screens/audio_library_screen.dart';
import 'screens/settings_screen.dart';
import 'services/api_service.dart';
import 'services/biometric_service.dart';
import 'models/user_model.dart';

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
  bool _isAdmin = false;
  String _activeUserId = "operator_01";

  void _handleLogin({required bool isAdmin, required String userId}) {
    setState(() {
      _isLoggedIn = true;
      _isAdmin = isAdmin;
      _activeUserId = userId;
    });
  }

  void _handleLogout() {
    if (_activeUserId.isNotEmpty) {
      ApiService.logout(_activeUserId);
    }
    setState(() {
      _isLoggedIn = false;
      _isAdmin = false;
      _activeUserId = "operator_01";
    });
  }

  @override
  Widget build(BuildContext context) {
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
      home: _isLoggedIn
          ? DashboardScreen(
              isAdmin: _isAdmin,
              activeUserId: _activeUserId,
              onLogout: _handleLogout,
            )
          : LandingAuthScreen(
              onLoginSuccess: _handleLogin,
            ),
    );
  }
}

// ---------------------------------------------------------
// LANDING AUTH SCREEN (BIOMETRIC + NORMAL USER + ADMIN LOGIN)
// ---------------------------------------------------------
class LandingAuthScreen extends StatefulWidget {
  final Function({required bool isAdmin, required String userId}) onLoginSuccess;

  const LandingAuthScreen({Key? key, required this.onLoginSuccess}) : super(key: key);

  @override
  State<LandingAuthScreen> createState() => _LandingAuthScreenState();
}

class _LandingAuthScreenState extends State<LandingAuthScreen> {
  bool _hasLoggedInBefore = false;
  String _lastUserId = '';
  String _lastUserName = '';
  String _lastUserRole = 'operator';
  bool _lastIsAdmin = false;
  bool _isBiometricSupported = false;
  bool _isBiometricEnabled = false;
  bool _hasAttemptedAutoBio = false;

  @override
  void initState() {
    super.initState();
    _initDeviceAuthState();
  }

  Future<void> _initDeviceAuthState() async {
    final hasLogged = await BiometricService.hasLoggedInBefore();
    if (hasLogged) {
      final lastAcc = await BiometricService.getLastLoginAccount();
      final bioSupported = await BiometricService.isDeviceSupported();
      final bioEnabled = await BiometricService.isBiometricEnabled();

      if (lastAcc != null && mounted) {
        setState(() {
          _hasLoggedInBefore = true;
          _lastUserId = lastAcc['userId'] ?? '';
          _lastUserName = lastAcc['userName'] ?? _lastUserId;
          _lastUserRole = lastAcc['role'] ?? 'operator';
          _lastIsAdmin = lastAcc['isAdmin'] ?? false;
          _isBiometricSupported = bioSupported;
          _isBiometricEnabled = bioEnabled;
        });

        // 2nd time onwards: if biometric is enabled on this device, prompt directly for fingerprint
        if (bioEnabled && bioSupported && !_hasAttemptedAutoBio) {
          _hasAttemptedAutoBio = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _executeBiometricLogin();
          });
        }
      }
    }
  }

  Future<void> _executeBiometricLogin() async {
    final success = await BiometricService.authenticate(
      reason: 'మోపిదేవి ఆలయ AI యాప్ లాగిన్ కొరకు మీ వేలిముద్రను తాకండి (Touch Fingerprint sensor to Login)',
    );

    if (success && mounted) {
      await BiometricService.recordSuccessfulLogin(
        userId: _lastUserId,
        userName: _lastUserName,
        role: _lastUserRole,
        isAdmin: _lastIsAdmin,
      );
      widget.onLoginSuccess(
        isAdmin: _lastIsAdmin,
        userId: _lastUserId,
      );
    }
  }

  void _openPasswordDialogForLastUser(BuildContext context) {
    final passwordController = TextEditingController();
    bool isAuthenticating = false;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1E293B),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Icon(_lastIsAdmin ? Icons.admin_panel_settings : Icons.lock_outline, color: const Color(0xFFE5A93C)),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'పాస్‌వర్డ్ లాగిన్',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE5A93C).withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: const Color(0xFFE5A93C),
                          radius: 18,
                          child: Icon(_lastIsAdmin ? Icons.admin_panel_settings : Icons.person, color: Colors.black, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_lastUserName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                              Text('ఖాతా ID: $_lastUserId (${_lastUserRole.toUpperCase()})', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: passwordController,
                    autofocus: true,
                    obscureText: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'పాస్‌వర్డ్ (Password)',
                      labelStyle: const TextStyle(color: Colors.white70),
                      hintText: 'Enter Password',
                      hintStyle: const TextStyle(color: Colors.white24),
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      prefixIcon: const Icon(Icons.lock, color: Color(0xFFE5A93C)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.pop(dialogCtx);
                        _openResetPasswordDialog(context, _lastUserId);
                      },
                      child: const Text('పాస్‌వర్డ్ రీసెట్ (Reset Password)', style: TextStyle(color: Color(0xFFE5A93C), fontSize: 11)),
                    ),
                  ),
                  if (isAuthenticating)
                    const Center(child: CircularProgressIndicator(color: Color(0xFFE5A93C))),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('రద్దు (Cancel)', style: TextStyle(color: Colors.white54)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE5A93C),
                  foregroundColor: Colors.black,
                ),
                onPressed: isAuthenticating
                    ? null
                    : () async {
                        final pass = passwordController.text.trim();
                        if (pass.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('దయచేసి పాస్‌వర్డ్ నమోదు చేయండి')),
                          );
                          return;
                        }
                        setDialogState(() => isAuthenticating = true);

                        try {
                          if ((_lastUserId == 'sid' || _lastUserId == 'user_default') && pass == 'Siddhu\$1999') {
                            Navigator.pop(dialogCtx);
                            await BiometricService.recordSuccessfulLogin(
                              userId: _lastUserId,
                              userName: _lastUserName,
                              role: _lastUserRole,
                              isAdmin: _lastIsAdmin,
                              password: pass,
                            );
                            widget.onLoginSuccess(isAdmin: true, userId: 'sid');
                            return;
                          }

                          final user = await ApiService.login(_lastUserId, pass);
                          Navigator.pop(dialogCtx);
                          await BiometricService.recordSuccessfulLogin(
                            userId: user.id,
                            userName: user.name,
                            role: user.role,
                            isAdmin: (user.role == 'super_admin' || user.role == 'voice_manager'),
                            password: pass,
                          );
                          widget.onLoginSuccess(
                            isAdmin: (user.role == 'super_admin' || user.role == 'voice_manager'),
                            userId: user.id,
                          );
                        } catch (e) {
                          setDialogState(() => isAuthenticating = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('లాగిన్ విఫలమైంది: $e')),
                          );
                        }
                      },
                child: const Text('ప్రవేశించండి (LOGIN)', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _openResetPasswordDialog(BuildContext context, [String? initialUserId]) async {
    List<SystemUser> users = [];
    try {
      users = await ApiService.fetchUsers();
    } catch (_) {}

    final defaultUserId = (initialUserId != null && initialUserId.isNotEmpty)
        ? initialUserId
        : (_lastUserId.isNotEmpty ? _lastUserId : (users.isNotEmpty ? users.first.id : ''));

    final idController = TextEditingController(text: defaultUserId);
    final currentPassController = TextEditingController();
    final newPassController = TextEditingController();
    final confirmPassController = TextEditingController();
    bool isSaving = false;

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1E293B),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: const [
                Icon(Icons.lock_reset, color: Color(0xFFE5A93C), size: 24),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'పాస్‌వర్డ్ రీసెట్ (Reset Password)',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'మీ పాత పాస్‌వర్డ్ నమోదు చేసి కొత్త పాస్‌వర్డ్ సెట్ చేసుకోండి:',
                    style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.3),
                  ),
                  const SizedBox(height: 12),
                  if (users.isNotEmpty) ...[
                    DropdownButtonFormField<String>(
                      value: users.any((u) => u.id == idController.text) ? idController.text : users.first.id,
                      dropdownColor: const Color(0xFF0F172A),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'యూజర్ ఖాతా ఎంచుకోండి (Select User)',
                        labelStyle: const TextStyle(color: Colors.white70, fontSize: 12),
                        filled: true,
                        fillColor: const Color(0xFF0F172A),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: users.map((u) {
                        return DropdownMenuItem<String>(
                          value: u.id,
                          child: Text('${u.name} (${u.id})', style: const TextStyle(fontSize: 13)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => idController.text = val);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                  ] else ...[
                    TextField(
                      controller: idController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'యూజర్ ID / పేరు (User ID or Name)*',
                        labelStyle: const TextStyle(color: Colors.white70),
                        hintText: 'e.g. USR-00001 or sid',
                        hintStyle: const TextStyle(color: Colors.white24),
                        filled: true,
                        fillColor: const Color(0xFF0F172A),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        prefixIcon: const Icon(Icons.person_outline, color: Color(0xFFE5A93C)),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextField(
                    controller: currentPassController,
                    obscureText: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'పాత / ప్రస్తుత పాస్‌వర్డ్ (Old Password)*',
                      labelStyle: const TextStyle(color: Colors.white70),
                      hintText: 'Enter Current Password',
                      hintStyle: const TextStyle(color: Colors.white24),
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      prefixIcon: const Icon(Icons.lock_clock_outlined, color: Color(0xFFE5A93C)),
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
                      hintText: 'Enter New Password',
                      hintStyle: const TextStyle(color: Colors.white24),
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      prefixIcon: const Icon(Icons.lock_open, color: Color(0xFFE5A93C)),
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
                      hintText: 'Re-enter New Password',
                      hintStyle: const TextStyle(color: Colors.white24),
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      prefixIcon: const Icon(Icons.check_circle_outline, color: Color(0xFFE5A93C)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (isSaving)
                    const Center(child: CircularProgressIndicator(color: Color(0xFFE5A93C))),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('రద్దు (Cancel)', style: TextStyle(color: Colors.white54)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE5A93C),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                onPressed: isSaving
                    ? null
                    : () async {
                        final userId = idController.text.trim();
                        final oldPass = currentPassController.text.trim();
                        final newPass = newPassController.text.trim();
                        final confirmPass = confirmPassController.text.trim();

                        if (userId.isEmpty || oldPass.isEmpty || newPass.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('దయచేసి అన్ని ఫీల్డ్‌లను నమోదు చేయండి')),
                          );
                          return;
                        }

                        if (newPass != confirmPass) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('కొత్త పాస్‌వర్డ్ సరిపోలలేదు (Passwords do not match)')),
                          );
                          return;
                        }

                        setDialogState(() => isSaving = true);
                        try {
                          final res = await ApiService.changePassword(
                            userId: userId,
                            currentPassword: oldPass,
                            newPassword: newPass,
                          );

                          // Update local storage if this was the last remembered / biometric user
                          if (_lastUserId == userId || _lastUserId == (res['user_id'] ?? '')) {
                            await BiometricService.recordSuccessfulLogin(
                              userId: _lastUserId,
                              userName: _lastUserName,
                              role: _lastUserRole,
                              isAdmin: _lastIsAdmin,
                              password: newPass,
                            );
                          }

                          Navigator.pop(dialogCtx);
                          if (context.mounted) {
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
                            SnackBar(
                              backgroundColor: const Color(0xFF991B1B),
                              content: Text('పాస్‌వర్డ్ మార్పు విఫలమైంది: $e'),
                            ),
                          );
                        }
                      },
                child: const Text('పాస్‌వర్డ్ సేవ్ చేయండి (SAVE)', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _handleFirstTimeBiometricSetup({
    required BuildContext context,
    required String userId,
    required String userName,
    required String password,
    required String role,
    required bool isAdmin,
  }) async {
    // Record successful login on this device
    await BiometricService.recordSuccessfulLogin(
      userId: userId,
      userName: userName,
      role: role,
      isAdmin: isAdmin,
      password: password,
    );

    final isSupported = await BiometricService.isDeviceSupported();
    final isAlreadyEnabled = await BiometricService.isBiometricEnabled();

    if (!isSupported) {
      widget.onLoginSuccess(isAdmin: isAdmin, userId: userId);
      return;
    }

    if (isAlreadyEnabled) {
      await BiometricService.saveBiometricCredentials(
        userId: userId,
        userName: userName,
        role: role,
        password: password,
        isAdmin: isAdmin,
      );
      widget.onLoginSuccess(isAdmin: isAdmin, userId: userId);
      return;
    }

    // Ask user to enable Biometric Login after 1st time login on this device
    if (!context.mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.fingerprint, color: Color(0xFFE5A93C), size: 28),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'వేలిముద్ర లాగిన్ (Biometric Login)',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'నమస్కారం $userName! తదుపరిసారి పాస్‌వర్డ్ నమోదు చేయకుండా నేరుగా మీ వేలిముద్రతో వేగంగా లాగిన్ అవ్వడానికి బయోమెట్రిక్ ఎనేబుల్ చేయాలనుకుంటున్నారా?',
              style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 8),
            const Text(
              '(Enable fingerprint authentication for instant 1-touch login on this device next time?)',
              style: TextStyle(color: Colors.white54, fontSize: 11, fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              widget.onLoginSuccess(isAdmin: isAdmin, userId: userId);
            },
            child: const Text('తర్వాత (Not Now / Skip)', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE5A93C),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            icon: const Icon(Icons.fingerprint, color: Colors.black, size: 20),
            label: const Text('వేలిముద్ర సెట్ చేయండి (Enable)', style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              final success = await BiometricService.authenticate(
                reason: 'వేలిముద్రను రిజిస్టర్ చేయడానికి సెన్సార్‌ను తాకండి (Touch sensor to register fingerprint)',
              );
              if (success) {
                await BiometricService.saveBiometricCredentials(
                  userId: userId,
                  userName: userName,
                  role: role,
                  password: password,
                  isAdmin: isAdmin,
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('✓ బయోమెట్రిక్ విజయవంతంగా సెట్ చేయబడింది!')),
                  );
                }
              }
              widget.onLoginSuccess(isAdmin: isAdmin, userId: userId);
            },
          ),
        ],
      ),
    );
  }

  void _openAdminLogin(BuildContext context) {
    final idController = TextEditingController();
    final passwordController = TextEditingController();
    bool isAuthenticating = false;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E293B),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: const [
                  Icon(Icons.admin_panel_settings, color: Color(0xFFE5A93C)),
                  SizedBox(width: 10),
                  Text('అడ్మిన్ లాగిన్ (Admin Login)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: idController,
                      autofocus: true,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Admin ID',
                        labelStyle: const TextStyle(color: Colors.white70),
                        hintText: 'Enter Admin ID',
                        hintStyle: const TextStyle(color: Colors.white24),
                        filled: true,
                        fillColor: const Color(0xFF0F172A),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        prefixIcon: const Icon(Icons.badge, color: Color(0xFFE5A93C)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        labelStyle: const TextStyle(color: Colors.white70),
                        hintText: 'Enter Password',
                        hintStyle: const TextStyle(color: Colors.white24),
                        filled: true,
                        fillColor: const Color(0xFF0F172A),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        prefixIcon: const Icon(Icons.lock, color: Color(0xFFE5A93C)),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          Navigator.pop(dialogCtx);
                          _openResetPasswordDialog(context, idController.text);
                        },
                        child: const Text('పాస్‌వర్డ్ రీసెట్ (Reset Password)', style: TextStyle(color: Color(0xFFE5A93C), fontSize: 11)),
                      ),
                    ),
                    if (isAuthenticating)
                      const Center(child: CircularProgressIndicator(color: Color(0xFFE5A93C))),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('రద్దు (Cancel)', style: TextStyle(color: Colors.white54)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE5A93C),
                    foregroundColor: Colors.black,
                  ),
                  onPressed: isAuthenticating
                      ? null
                      : () async {
                          setDialogState(() => isAuthenticating = true);
                          final id = idController.text.trim();
                          final pass = passwordController.text.trim();

                          if ((id == 'sid' || id == 'user_default') && pass == 'Siddhu\$1999') {
                            Navigator.pop(dialogCtx);
                            await _handleFirstTimeBiometricSetup(
                              context: context,
                              userId: 'sid',
                              userName: 'Administrator (sid)',
                              role: 'super_admin',
                              password: pass,
                              isAdmin: true,
                            );
                            return;
                          }

                          try {
                            final user = await ApiService.login(id, pass);
                            Navigator.pop(dialogCtx);
                            await _handleFirstTimeBiometricSetup(
                              context: context,
                              userId: user.id,
                              userName: user.name,
                              role: user.role,
                              password: pass,
                              isAdmin: (user.role == 'super_admin' || user.role == 'voice_manager'),
                            );
                          } catch (e) {
                            setDialogState(() => isAuthenticating = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('లాగిన్ విఫలమైంది: $e')),
                            );
                          }
                        },
                  child: const Text('లాగిన్ (LOGIN)', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _openUserLogin(BuildContext context) async {
    List<SystemUser> users = [];
    try {
      users = await ApiService.fetchUsers();
    } catch (_) {}

    final operators = users.where((u) => u.role != 'super_admin').toList();
    final idController = TextEditingController(text: operators.isNotEmpty ? operators.first.id : '');
    final passwordController = TextEditingController();
    bool isAuthenticating = false;

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E293B),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: const [
                  Icon(Icons.person, color: Color(0xFFE5A93C)),
                  SizedBox(width: 10),
                  Text('యూజర్ లాగిన్ (User Login)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (operators.isNotEmpty) ...[
                      const Text('ఆపరేటర్ ఎంచుకోండి (Quick Select):', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        value: operators.any((u) => u.id == idController.text) ? idController.text : operators.first.id,
                        dropdownColor: const Color(0xFF0F172A),
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color(0xFF0F172A),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: operators.map((u) {
                          return DropdownMenuItem<String>(
                            value: u.id,
                            child: Text('${u.name} (${u.id})', style: const TextStyle(fontSize: 13)),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() {
                              idController.text = val;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 14),
                      const Center(child: Text('- లేదా (or enter manually) -', style: TextStyle(color: Colors.white38, fontSize: 11))),
                      const SizedBox(height: 14),
                    ],
                    TextField(
                      controller: idController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'User ID / పేరు (Name)',
                        labelStyle: const TextStyle(color: Colors.white70),
                        hintText: 'e.g. USR-00001 or Ramesh',
                        hintStyle: const TextStyle(color: Colors.white24),
                        filled: true,
                        fillColor: const Color(0xFF0F172A),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        prefixIcon: const Icon(Icons.person_outline, color: Color(0xFFE5A93C)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'పాస్‌వర్డ్ (Password)',
                        labelStyle: const TextStyle(color: Colors.white70),
                        hintText: 'Enter Password (e.g. User\$1234)',
                        hintStyle: const TextStyle(color: Colors.white24),
                        filled: true,
                        fillColor: const Color(0xFF0F172A),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFFE5A93C)),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          Navigator.pop(dialogCtx);
                          _openResetPasswordDialog(context, idController.text);
                        },
                        child: const Text('పాస్‌వర్డ్ రీసెట్ (Reset Password)', style: TextStyle(color: Color(0xFFE5A93C), fontSize: 11)),
                      ),
                    ),
                    if (isAuthenticating)
                      const Center(child: CircularProgressIndicator(color: Color(0xFFE5A93C))),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('రద్దు (Cancel)', style: TextStyle(color: Colors.white54)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE5A93C),
                    foregroundColor: Colors.black,
                  ),
                  onPressed: isAuthenticating
                      ? null
                      : () async {
                          final id = idController.text.trim();
                          final pass = passwordController.text.trim();
                          if (id.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('దయచేసి యూజర్ ID లేదా పేరు నమోదు చేయండి')),
                            );
                            return;
                          }
                          setDialogState(() => isAuthenticating = true);

                          try {
                            final user = await ApiService.login(id, pass.isEmpty ? 'User\$1234' : pass);
                            Navigator.pop(dialogCtx);
                            await _handleFirstTimeBiometricSetup(
                              context: context,
                              userId: user.id,
                              userName: user.name,
                              role: user.role,
                              password: pass.isEmpty ? 'User\$1234' : pass,
                              isAdmin: (user.role == 'super_admin' || user.role == 'voice_manager'),
                            );
                          } catch (e) {
                            setDialogState(() => isAuthenticating = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('లాగిన్ విఫలమైంది: $e')),
                            );
                          }
                        },
                  child: const Text('ప్రవేశించండి (LOGIN)', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _openServerConfigDialog(BuildContext context) {
    final controller = TextEditingController(text: ApiService.baseUrl);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.cloud, color: Color(0xFFE5A93C)),
            SizedBox(width: 10),
            Text('ఆన్‌లైన్ సర్వర్ (Cloud Server URL)', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ఆన్‌లైన్ లో మొబైల్ యాప్ పనిచేయడానికి మీ క్లౌడ్ HTTPS URL ని ఇక్కడ నమోదు చేయండి:\n(Enter your online Cloud HTTPS URL for 24/7 internet access):',
              style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'https://mopidevi-voice-app.onrender.com',
                hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
                filled: true,
                fillColor: const Color(0xFF0F172A),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                prefixIcon: const Icon(Icons.link, color: Color(0xFFE5A93C)),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE5A93C),
              foregroundColor: Colors.black,
            ),
            onPressed: () {
              final url = controller.text.trim();
              if (url.isNotEmpty) {
                ApiService.setBaseUrl(url);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('✓ సర్వర్ చిరునామా సెట్ చేయబడింది: $url')),
                );
              }
            },
            child: const Text('సేవ్ (SAVE)', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.cloud_outlined, color: Color(0xFFE5A93C)),
            tooltip: 'ఆన్‌లైన్ సర్వర్ సెట్టింగ్లు (Cloud Server URL)',
            onPressed: () => _openServerConfigDialog(context),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Card(
            color: const Color(0xFF1E293B),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(28.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.temple_hindu, size: 60, color: Color(0xFFE5A93C)),
                  const SizedBox(height: 14),
                  const Text('MOPIDEVI TEMPLE', style: TextStyle(color: Colors.white54, letterSpacing: 3, fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text('AI VOICE SYSTEM', style: TextStyle(color: Color(0xFFE5A93C), fontWeight: FontWeight.bold, fontSize: 22)),
                  const SizedBox(height: 6),
                  const Text('శ్రీ మోపిదేవి క్షేత్రం - స్వర వ్యవస్థ', style: TextStyle(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 24),

                  // ---------------------------------------------------------------------------------
                  // FROM 2ND TIME ONWARDS: DEFAULT SELECT LAST LOGIN ACCOUNT & ASK BIOMETRIC OR PASSWORD
                  // (Only shown if a user has already logged in on this device before)
                  // ---------------------------------------------------------------------------------
                  if (_hasLoggedInBefore) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFFE5A93C).withValues(alpha: 0.15),
                            const Color(0xFF0F172A),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE5A93C).withValues(alpha: 0.4), width: 1.5),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: const Color(0xFFE5A93C),
                                radius: 20,
                                child: Icon(_lastIsAdmin ? Icons.admin_panel_settings : Icons.person, color: Colors.black, size: 22),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _lastUserName,
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                                    ),
                                    Text(
                                      'ID: $_lastUserId • ${_lastUserRole.toUpperCase()}',
                                      style: const TextStyle(color: Colors.white54, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE5A93C).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text('ఖాతా (Active)', style: TextStyle(color: Color(0xFFE5A93C), fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          const Divider(color: Colors.white12, height: 1),
                          const SizedBox(height: 14),
                          const Center(
                            child: Text(
                              'ఎలా లాగిన్ చేయాలనుకుంటున్నారు?\n(Choose Login Method):',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.3),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Biometric Option (Only shown because user has logged in before on this device)
                          if (_isBiometricSupported && _isBiometricEnabled)
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.fingerprint, color: Colors.black, size: 22),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFE5A93C),
                                  foregroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onPressed: _executeBiometricLogin,
                                label: const Text('వేలిముద్రతో లాగిన్ (BIOMETRIC LOGIN)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              ),
                            ),

                          if (_isBiometricSupported && _isBiometricEnabled) const SizedBox(height: 10),

                          // Password Option for Last Selected Account
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.lock_outline, color: Color(0xFFE5A93C), size: 20),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFFE5A93C),
                                side: const BorderSide(color: Color(0xFFE5A93C), width: 1.2),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () => _openPasswordDialogForLastUser(context),
                              label: const Text('పాస్‌వర్డ్ తో లాగిన్ (PASSWORD LOGIN)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Row(
                      children: [
                        Expanded(child: Divider(color: Colors.white24)),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Text('లేదా వేరే ఖాతా (or switch account)', style: TextStyle(color: Colors.white38, fontSize: 11)),
                        ),
                        Expanded(child: Divider(color: Colors.white24)),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ---------------------------------------------------------------------------------
                  // STANDARD MANUAL LOGINS (Always accessible, and only items shown on fresh device)
                  // ---------------------------------------------------------------------------------
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.person, color: Colors.black),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _hasLoggedInBefore ? const Color(0xFF334155) : const Color(0xFFE5A93C),
                        foregroundColor: _hasLoggedInBefore ? Colors.white : Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => _openUserLogin(context),
                      label: Text(_hasLoggedInBefore ? 'వేరే యూజర్ లాగిన్ (Switch User)' : '[ NORMAL USER LOGIN ]', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Admin Login Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.admin_panel_settings, color: Color(0xFFE5A93C)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFE5A93C),
                        side: const BorderSide(color: Color(0xFFE5A93C), width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => _openAdminLogin(context),
                      label: const Text('[ ADMIN LOGIN ]', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Reset / Change Password Button
                  TextButton.icon(
                    onPressed: () => _openResetPasswordDialog(context),
                    icon: const Icon(Icons.lock_reset, color: Color(0xFFE5A93C), size: 18),
                    label: const Text(
                      'పాస్‌వర్డ్ రీసెట్ / మార్చుకోండి (Reset Password)',
                      style: TextStyle(color: Color(0xFFE5A93C), fontSize: 12, decoration: TextDecoration.underline),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '🔒 Security: Authorized Temple Staff & Administrators Only',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white38, fontSize: 11, letterSpacing: 0.5),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------
// DASHBOARD SCREEN (ADMIN vs OPERATOR VIEWS)
// ---------------------------------------------------------
class DashboardScreen extends StatefulWidget {
  final bool isAdmin;
  final String activeUserId;
  final VoidCallback onLogout;

  const DashboardScreen({
    Key? key,
    required this.isAdmin,
    required this.activeUserId,
    required this.onLogout,
  }) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  late String _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = widget.activeUserId;
  }

  @override
  Widget build(BuildContext context) {
    // Admin Views: User Management (Create/Delete) & Settings
    final List<Widget> adminScreens = [
      UserManagementScreen(activeUserId: _currentUserId),
      SettingsScreen(
        activeUserId: _currentUserId,
        onUserChanged: (newId) => setState(() => _currentUserId = newId),
      ),
    ];

    // Operator Views: Announcement Generator, Templates, Audio Library, Settings
    final List<Widget> operatorScreens = [
      HomeScreen(activeUserId: _currentUserId),
      TemplatesScreen(onSelectTemplate: (script) {
        setState(() => _currentIndex = 0);
      }),
      const AudioLibraryScreen(),
      SettingsScreen(
        activeUserId: _currentUserId,
        onUserChanged: (newId) => setState(() => _currentUserId = newId),
      ),
    ];

    final screens = widget.isAdmin ? adminScreens : operatorScreens;

    final adminNavItems = const [
      BottomNavigationBarItem(icon: Icon(Icons.manage_accounts), label: 'యూజర్లు (Users)'),
      BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'సెట్టింగ్లు (Settings)'),
    ];

    final operatorNavItems = const [
      BottomNavigationBarItem(icon: Icon(Icons.record_voice_over), label: 'ప్రకటనలు'),
      BottomNavigationBarItem(icon: Icon(Icons.description), label: 'టెంప్లేట్లు'),
      BottomNavigationBarItem(icon: Icon(Icons.library_music), label: 'ఆడియోలు'),
      BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'సెట్టింగ్లు'),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(widget.isAdmin ? Icons.admin_panel_settings : Icons.temple_hindu, color: const Color(0xFFE5A93C)),
            const SizedBox(width: 10),
            Text(
              widget.isAdmin ? '🛡️ ADMIN CONSOLE' : 'OPERATOR DASHBOARD',
              style: const TextStyle(color: Color(0xFFE5A93C), fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white70),
            tooltip: 'Logout',
            onPressed: widget.onLogout,
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
        items: widget.isAdmin ? adminNavItems : operatorNavItems,
      ),
    );
  }
}
