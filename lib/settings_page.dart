import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'theme_service.dart';
import 'auth_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _authService = AuthService();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final LocalAuthentication _auth = LocalAuthentication();
  bool _isPasswordVisible = false;
  
  bool _canCheckBiometrics = false;
  bool _hasFingerprint = false;
  bool _hasFace = false;

  @override
  void initState() {
    super.initState();
    _checkBiometricSupport();
  }

  Future<void> _checkBiometricSupport() async {
    try {
      final bool canCheck = await _auth.canCheckBiometrics;
      final bool isSupported = await _auth.isDeviceSupported();
      final List<BiometricType> available = await _auth.getAvailableBiometrics();
      
      setState(() {
        _canCheckBiometrics = canCheck && isSupported;
        _hasFingerprint = available.contains(BiometricType.fingerprint);
        _hasFace = available.contains(BiometricType.face) || available.contains(BiometricType.strong);
      });
    } catch (e) {
      debugPrint('Error checking biometrics: $e');
    }
  }

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('Change Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _newPasswordController,
                obscureText: !_isPasswordVisible,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setDialogState(() => _isPasswordVisible = !_isPasswordVisible),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _confirmPasswordController,
                obscureText: !_isPasswordVisible,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  prefixIcon: const Icon(Icons.lock_reset),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (_newPasswordController.text.isEmpty) return;
                if (_newPasswordController.text != _confirmPasswordController.text) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Passwords do not match')),
                  );
                  return;
                }
                final success = await _authService.changePassword(_newPasswordController.text);
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success ? 'Password updated successfully' : 'Failed to update password'),
                      backgroundColor: success ? Colors.green : Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader('Appearance'),
          ValueListenableBuilder<ThemeMode>(
            valueListenable: ThemeService().themeMode,
            builder: (context, mode, _) {
              return SwitchListTile(
                secondary: Icon(mode == ThemeMode.dark ? Icons.dark_mode : Icons.light_mode),
                title: const Text('Dark Mode'),
                value: mode == ThemeMode.dark,
                onChanged: (_) => ThemeService().toggleTheme(),
              );
            },
          ),
          const Divider(),
          _buildSectionHeader('Notifications'),
          ValueListenableBuilder<bool>(
            valueListenable: ThemeService().notificationsEnabled,
            builder: (context, enabled, _) {
              return SwitchListTile(
                secondary: const Icon(Icons.notifications_active_outlined),
                title: const Text('Election Updates'),
                subtitle: const Text('Notify when election starts/ends'),
                value: enabled,
                onChanged: (_) => ThemeService().toggleNotifications(),
              );
            },
          ),
          const Divider(),
          if (_canCheckBiometrics && user != null) ...[
            _buildSectionHeader('Security'),
            if (_hasFingerprint)
              SwitchListTile(
                secondary: const Icon(Icons.fingerprint),
                title: const Text('Fingerprint Authentication'),
                subtitle: const Text('Use fingerprint for login'),
                value: user.isFingerprintEnabled,
                onChanged: (val) {
                  setState(() {
                    user.isFingerprintEnabled = val;
                  });
                  // Trigger persistence
                  _authService.changePassword(user.password); 
                },
              ),
            if (_hasFace)
              SwitchListTile(
                secondary: const Icon(Icons.face_rounded),
                title: const Text('Face Recognition'),
                subtitle: const Text('Use Face ID for login'),
                value: user.isFaceEnabled,
                onChanged: (val) {
                  setState(() {
                    user.isFaceEnabled = val;
                  });
                  // Trigger persistence
                  _authService.changePassword(user.password);
                },
              ),
            const Divider(),
          ],
          _buildSectionHeader('Account'),
          ListTile(
            leading: const Icon(Icons.password),
            title: const Text('Change Password'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _showChangePasswordDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }
}
