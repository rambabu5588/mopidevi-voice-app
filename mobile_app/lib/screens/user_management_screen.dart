import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/biometric_service.dart';
import '../models/user_model.dart';

class UserManagementScreen extends StatefulWidget {
  final String activeUserId;
  const UserManagementScreen({Key? key, required this.activeUserId}) : super(key: key);

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  List<SystemUser> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final list = await ApiService.fetchUsers();
      setState(() {
        _users = list;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('వినియోగదారుల జాబితా లోడ్ విఫలమైంది: $e')),
        );
      }
    }
  }

  // Admin Change Password Dialog for ANY user or Admin's own account
  Future<void> _showAdminChangeUserPasswordDialog(SystemUser user) async {
    final newPassController = TextEditingController();
    final confirmPassController = TextEditingController();
    final currentPassController = TextEditingController();
    final isOwnAccount = user.id == widget.activeUserId || user.id == 'sid';
    bool isSaving = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: const [
              Icon(Icons.lock_reset, color: Color(0xFFE5A93C)),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'పాస్‌వర్డ్ మార్చండి (Change Password)',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
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
                        radius: 16,
                        child: Icon(user.role == 'super_admin' ? Icons.admin_panel_settings : Icons.person, color: Colors.black, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                            Text('ID: ${user.id} • ${user.role.toUpperCase()}', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                            const SizedBox(height: 2),
                            Text('ప్రస్తుత పాస్‌వర్డ్: ${user.password}', style: const TextStyle(color: Color(0xFFE5A93C), fontSize: 11, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                if (isOwnAccount) ...[
                  TextField(
                    controller: currentPassController,
                    obscureText: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'ప్రస్తుత పాస్‌వర్డ్ (Current Password)*',
                      labelStyle: const TextStyle(color: Colors.white70),
                      hintText: 'Enter Current Password',
                      hintStyle: const TextStyle(color: Colors.white24),
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      prefixIcon: const Icon(Icons.lock_clock, color: Color(0xFFE5A93C)),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

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
                const SizedBox(height: 12),
                if (isSaving)
                  const Center(child: CircularProgressIndicator(color: Color(0xFFE5A93C))),
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              onPressed: isSaving
                  ? null
                  : () async {
                      final newPass = newPassController.text.trim();
                      final confirmPass = confirmPassController.text.trim();
                      final currentPass = currentPassController.text.trim();

                      if (newPass.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('దయచేసి కొత్త పాస్‌వర్డ్ నమోదు చేయండి')),
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
                        if (isOwnAccount && currentPass.isNotEmpty) {
                          await ApiService.changePassword(
                            userId: user.id,
                            currentPassword: currentPass,
                            newPassword: newPass,
                          );
                        } else {
                          await ApiService.adminSetPassword(
                            userId: user.id,
                            newPassword: newPass,
                          );
                        }

                        // Update local biometric credentials if matching user
                        final creds = await BiometricService.getSavedCredentials();
                        if (creds != null && (creds['userId'] == user.id || creds['userId'] == widget.activeUserId)) {
                          await BiometricService.saveBiometricCredentials(
                            userId: user.id,
                            userName: user.name,
                            role: user.role,
                            password: newPass,
                            isAdmin: user.role == 'super_admin' || user.role == 'voice_manager',
                          );
                        }

                        Navigator.pop(ctx);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: const Color(0xFF166534),
                              content: Text('✓ ${user.name} (${user.id}) పాస్‌వర్డ్ విజయవంతంగా డేటాబేస్ లో సేవ్ చేయబడింది!'),
                            ),
                          );
                        }
                        _loadUsers();
                      } catch (e) {
                        setDialogState(() => isSaving = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: const Color(0xFF991B1B),
                            content: Text('పాస్‌వర్డ్ సేవ్ విఫలమైంది: $e'),
                          ),
                        );
                      }
                    },
              child: const Text('పాస్‌వర్డ్ సేవ్ చేయండి (SAVE)', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  // Clean Dialog: Name, Initial Password & Role. No personal details required.
  Future<void> _showCreateUserDialog() async {
    final nameController = TextEditingController();
    final passwordController = TextEditingController();
    String selectedRole = 'operator';

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
                  Icon(Icons.person_add, color: Color(0xFFE5A93C)),
                  SizedBox(width: 10),
                  Text('కొత్త వ్యక్తిని చేర్చండి (Add Person)', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
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
                      child: const Text(
                        '💡 కేవలం పేరు మరియు పాస్‌వర్డ్ నమోదు చేయండి. వ్యక్తిగత వివరాలు అవసరం లేదు.\nబ్యాకెండ్ స్వయంచాలకంగా User ID, Auth ID, Profile ID లను సృష్టిస్తుంది.',
                        style: TextStyle(color: Color(0xFFE5A93C), fontSize: 12, height: 1.4),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameController,
                      autofocus: true,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'వ్యక్తి పేరు (Person Name)*',
                        hintText: 'e.g. Ramesh or Sri Venkateswara Rao',
                        hintStyle: const TextStyle(color: Colors.white24),
                        labelStyle: const TextStyle(color: Colors.white70),
                        filled: true,
                        fillColor: const Color(0xFF0F172A),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        prefixIcon: const Icon(Icons.person, color: Color(0xFFE5A93C)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: passwordController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'పాస్‌వర్డ్ (Password)*',
                        hintText: 'Enter password for this user',
                        hintStyle: const TextStyle(color: Colors.white24),
                        labelStyle: const TextStyle(color: Colors.white70),
                        filled: true,
                        fillColor: const Color(0xFF0F172A),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFFE5A93C)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      value: selectedRole,
                      dropdownColor: const Color(0xFF0F172A),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'పాత్ర (Role)',
                        labelStyle: const TextStyle(color: Colors.white70),
                        filled: true,
                        fillColor: const Color(0xFF0F172A),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'operator', child: Text('Operator (ఆలయ ఆపరేటర్)')),
                        DropdownMenuItem(value: 'voice_manager', child: Text('Voice Manager (స్వర నిర్వాహకుడు)')),
                        DropdownMenuItem(value: 'viewer', child: Text('Viewer (వీక్షకుడు)')),
                      ],
                      onChanged: (val) {
                        if (val != null) setDialogState(() => selectedRole = val);
                      },
                    ),
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
                  onPressed: () async {
                    final name = nameController.text.trim();
                    final pass = passwordController.text.trim();
                    if (name.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('దయచేసి పేరు నమోదు చేయండి')),
                      );
                      return;
                    }
                    if (pass.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('దయచేసి పాస్‌వర్డ్ నమోదు చేయండి')),
                      );
                      return;
                    }
                    Navigator.pop(ctx);
                    try {
                      final newUser = await ApiService.createUser(
                        name: name,
                        password: pass,
                        role: selectedRole,
                        status: 'Active',
                      );
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('✓ ${newUser.name} ఖాతా సృష్టించబడింది (ID: ${newUser.id})')),
                        );
                      }
                      _loadUsers();
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('ఖాతా సృష్టి విఫలమైంది: $e')),
                        );
                      }
                    }
                  },
                  child: const Text('సృష్టించండి (Create)', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _confirmDeleteUser(SystemUser user) async {
    if (user.id == 'sid' || user.id == 'user_default') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ రూట్ అడ్మిన్ ఖాతాను తొలగించలేరు')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('ఖాతాను తొలగించాలా? (Delete User)', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
        content: Text('వ్యక్తి: ${user.name}\nఖాతా ID: ${user.id}\nఈ ఖాతాను శాశ్వతంగా తొలగించాలనుకుంటున్నారా?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('వద్దు (Cancel)', style: TextStyle(color: Colors.white70))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('తొలగించండి (Delete)', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ApiService.deleteUser(user.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('ఖాతా ${user.id} తొలగించబడింది')),
          );
        }
        _loadUsers();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('తొలగింపు విఫలమైంది: $e')),
          );
        }
      }
    }
  }

  String _formatTimestamp(double? epochSeconds) {
    if (epochSeconds == null || epochSeconds == 0) return 'ఎప్పుడూ లేదు (Never)';
    final dt = DateTime.fromMillisecondsSinceEpoch((epochSeconds * 1000).toInt());
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    final minuteStr = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}, $hour:$minuteStr $ampm';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFE5A93C)))
          : RefreshIndicator(
              color: const Color(0xFFE5A93C),
              onRefresh: _loadUsers,
              child: ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: _users.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    final myUser = _users.firstWhere(
                      (u) => u.id == widget.activeUserId,
                      orElse: () => _users.firstWhere((u) => u.id == 'sid', orElse: () => _users.first),
                    );
                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF1E293B), Color(0xFF0F172A)]),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE5A93C).withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.security, color: Color(0xFFE5A93C), size: 22),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('అడ్మిన్ డాష్‌బోర్డ్ (Admin Console)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                Text('పాస్‌వర్డ్ మార్పు & ఖాతా నిర్వహణ', style: TextStyle(color: Colors.white54, fontSize: 11)),
                              ],
                            ),
                          ),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFE5A93C),
                              side: const BorderSide(color: Color(0xFFE5A93C), width: 1),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: const Icon(Icons.lock_reset, size: 16),
                            label: const Text('నా పాస్‌వర్డ్', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            onPressed: () => _showAdminChangeUserPasswordDialog(myUser),
                          ),
                        ],
                      ),
                    );
                  }

                  final user = _users[index - 1];
                  final isRootAdmin = user.id == 'sid' || user.id == 'user_default';

                  return Card(
                    color: const Color(0xFF1E293B),
                    margin: const EdgeInsets.only(bottom: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(
                        color: isRootAdmin ? Colors.redAccent.withValues(alpha: 0.4) : const Color(0xFFE5A93C).withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header: Name & Role Badge
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 18,
                                      backgroundColor: isRootAdmin ? Colors.redAccent.withValues(alpha: 0.2) : const Color(0xFFE5A93C).withValues(alpha: 0.2),
                                      child: Icon(
                                        isRootAdmin ? Icons.admin_panel_settings : Icons.person,
                                        color: isRootAdmin ? Colors.redAccent : const Color(0xFFE5A93C),
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        user.name,
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Chip(
                                label: Text(
                                  user.role.toUpperCase(),
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black),
                                ),
                                backgroundColor: isRootAdmin ? Colors.redAccent : const Color(0xFFE5A93C),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Credentials Container (User ID & Password with Edit Option)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F172A),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white12),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('USER ID', style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                                      const SizedBox(height: 2),
                                      Text(user.id, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                                Container(width: 1, height: 30, color: Colors.white12),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text('🔑 PASSWORD', style: TextStyle(color: Color(0xFFE5A93C), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                                            const SizedBox(height: 2),
                                            Text(
                                              user.password,
                                              style: const TextStyle(color: Color(0xFFE5A93C), fontSize: 13, fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.edit, color: Color(0xFFE5A93C), size: 18),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        tooltip: 'పాస్‌వర్డ్ మార్చండి (Change Password)',
                                        onPressed: () => _showAdminChangeUserPasswordDialog(user),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Login and Logout Timings
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F172A).withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white10),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.login, color: Colors.greenAccent, size: 16),
                                    const SizedBox(width: 8),
                                    const Text('లాగిన్ సమయం (Last Login): ', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                    Expanded(
                                      child: Text(
                                        _formatTimestamp(user.lastLoginAt),
                                        style: const TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.w600),
                                        textAlign: TextAlign.end,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(Icons.logout, color: Colors.orangeAccent, size: 16),
                                    const SizedBox(width: 8),
                                    const Text('లాగౌట్ సమయం (Last Logout): ', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                    Expanded(
                                      child: Text(
                                        _formatTimestamp(user.lastLogoutAt),
                                        style: const TextStyle(color: Colors.orangeAccent, fontSize: 12, fontWeight: FontWeight.w600),
                                        textAlign: TextAlign.end,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Badges: Auth ID, Profile ID & Action
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Wrap(
                                spacing: 6,
                                children: [
                                  _buildBadge('Auth ID', user.authId, Colors.indigo),
                                  _buildBadge('Status', user.status, user.status == 'Active' ? Colors.green : Colors.grey),
                                ],
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.lock_reset, color: Color(0xFFE5A93C), size: 20),
                                    onPressed: () => _showAdminChangeUserPasswordDialog(user),
                                    tooltip: 'Change Password',
                                  ),
                                  if (!isRootAdmin)
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                      onPressed: () => _confirmDeleteUser(user),
                                      tooltip: 'Delete Account',
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFE5A93C),
        foregroundColor: Colors.black,
        icon: const Icon(Icons.person_add),
        label: const Text('కొత్త వ్యక్తిని చేర్చండి (Add Person)', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: _showCreateUserDialog,
      ),
    );
  }

  Widget _buildBadge(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 0.8),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w600),
      ),
    );
  }
}

