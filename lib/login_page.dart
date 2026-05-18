import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'auth_service.dart';
import 'registration_page.dart';
import 'admin_panel.dart';
import 'voting_service.dart';
import 'main.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _idController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  final _votingService = VotingService();
  final LocalAuthentication auth = LocalAuthentication();
  String _selectedRole = 'Student';
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  Future<bool> _authenticateBiometrically() async {
    try {
      final bool canCheckBiometrics = await auth.canCheckBiometrics;
      final bool isDeviceSupported = await auth.isDeviceSupported();

      if (!canCheckBiometrics && !isDeviceSupported) {
        _showSnackBar('Biometric authentication not supported', Colors.orange);
        return false;
      }

      final List<BiometricType> availableBiometrics = await auth.getAvailableBiometrics();
      
      bool hasFace = availableBiometrics.contains(BiometricType.face);
      bool hasFingerprint = availableBiometrics.contains(BiometricType.fingerprint);

      String? selectedMethod;
      
      if (hasFace && hasFingerprint) {
        if (!mounted) return false;
        selectedMethod = await showDialog<String>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: const Text('Identity Verification', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Choose your preferred authentication method:', textAlign: TextAlign.center),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _biometricChoiceItem(context, 'Fingerprint', Icons.fingerprint_rounded),
                    _biometricChoiceItem(context, 'Face ID', Icons.face_rounded),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
              ),
            ],
          ),
        );
        if (selectedMethod == null) return false;
      } else if (hasFace) {
        selectedMethod = 'Face ID';
      } else if (hasFingerprint) {
        selectedMethod = 'Fingerprint';
      } else if (availableBiometrics.isNotEmpty) {
        selectedMethod = 'Biometric';
      }

      return await auth.authenticate(
        localizedReason: selectedMethod != null 
            ? 'Please authenticate using $selectedMethod to login'
            : 'Please authenticate to securely access your account',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } catch (e) {
      debugPrint('Biometric Error: $e');
      return false;
    }
  }

  Widget _biometricChoiceItem(BuildContext context, String label, IconData icon) {
    return InkWell(
      onTap: () => Navigator.pop(context, label),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 110,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: const Color(0xFF1A73E8).withOpacity(0.05),
          border: Border.all(color: const Color(0xFF1A73E8).withOpacity(0.1)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, size: 40, color: const Color(0xFF1A73E8)),
            const SizedBox(height: 12),
            Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1A73E8))),
          ],
        ),
      ),
    );
  }

  Future<void> _handleLogin() async {
    final id = _idController.text.trim();
    final password = _passwordController.text;

    if (id.isEmpty || password.isEmpty) {
      _showSnackBar('Please fill in all fields', Colors.orange);
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_selectedRole == 'Student') {
        final success = await _authService.login(id, password);
        if (success) {
          final authenticated = await _authenticateBiometrically();
          if (authenticated) {
            _navigateToDashboard('Poll Station');
          } else {
            await _authService.logout();
            _showSnackBar('Security verification failed or cancelled', Colors.orange);
          }
        } else {
          _showSnackBar('Invalid student credentials', Colors.redAccent);
        }
      } else {
        final success = await _authService.adminLogin(id, password);
        if (success) {
          if (!mounted) return;
          if (_votingService.startTime != null && _votingService.endTime != null) {
            _navigateToDashboard('Admin Results Dashboard');
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const AdminPanel()),
            );
          }
        } else {
          _showSnackBar('Invalid admin credentials', Colors.redAccent);
        }
      }
    } catch (e) {
      _showSnackBar('An error occurred during login', Colors.red);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _navigateToDashboard(String title) {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => VotingDashboard(title: title),
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  void dispose() {
    _idController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          if (MediaQuery.of(context).size.width > 800)
            Expanded(
              child: Container(
                color: const Color(0xFF1A73E8),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.how_to_vote_rounded, size: 120, color: Colors.white),
                      const SizedBox(height: 24),
                      const Text(
                        'Poll Station',
                        style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Your Choice, Protected & Counted',
                        style: TextStyle(fontSize: 18, color: Colors.white.withOpacity(0.8)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(40.0),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A73E8).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.how_to_vote_rounded, color: Color(0xFF1A73E8), size: 32),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Center(
                        child: Text(
                          'Welcome Back',
                          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF202124)),
                        ),
                      ),
                      const Center(
                        child: Text(
                          'Select your role to continue',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      Row(
                        children: [
                          Expanded(child: _buildRoleTab('Student', Icons.person_outline)),
                          const SizedBox(width: 16),
                          Expanded(child: _buildRoleTab('Admin', Icons.admin_panel_settings_outlined)),
                        ],
                      ),
                      const SizedBox(height: 32),
                      
                      TextField(
                        controller: _idController,
                        enabled: !_isLoading,
                        decoration: InputDecoration(
                          labelText: _selectedRole == 'Student' ? 'Student ID' : 'Admin ID',
                          prefixIcon: const Icon(Icons.badge_outlined),
                          filled: true,
                          fillColor: const Color(0xFFF8F9FA),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF1A73E8), width: 2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _passwordController,
                        obscureText: !_isPasswordVisible,
                        enabled: !_isLoading,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_open_rounded),
                          filled: true,
                          fillColor: const Color(0xFFF8F9FA),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF1A73E8), width: 2),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off, size: 20),
                            onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1A73E8),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: _isLoading 
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('Login', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      if (_selectedRole == 'Student') ...[
                        const SizedBox(height: 24),
                        Center(
                          child: Wrap(
                            children: [
                              const Text("New to Station? ", style: TextStyle(color: Colors.grey)),
                              GestureDetector(
                                onTap: _isLoading ? null : () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RegistrationPage())),
                                child: const Text(
                                  'Register',
                                  style: TextStyle(color: Color(0xFF1A73E8), fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleTab(String role, IconData icon) {
    final isSelected = _selectedRole == role;
    return GestureDetector(
      onTap: _isLoading ? null : () => setState(() => _selectedRole = role),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1A73E8) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? const Color(0xFF1A73E8) : Colors.grey.shade300),
          boxShadow: isSelected ? [BoxShadow(color: const Color(0xFF1A73E8).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))] : [],
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? Colors.white : Colors.grey.shade600),
            const SizedBox(height: 8),
            Text(
              role,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade600,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
