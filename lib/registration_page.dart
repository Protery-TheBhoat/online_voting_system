import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'auth_service.dart';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final _regController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();
  final LocalAuthentication _auth = LocalAuthentication();
  
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  
  bool _isFingerprintEnabled = false;
  bool _isFaceEnabled = false;
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

  void _register() {
    final regNum = _regController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (regNum.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      _showSnackBar('Please fill in all fields', Colors.orange);
      return;
    }

    if (password != confirmPassword) {
      _showSnackBar('Passwords do not match', Colors.redAccent);
      return;
    }

    if (password.length < 4) {
      _showSnackBar('Password must be at least 4 characters long', Colors.redAccent);
      return;
    }

    if (_authService.register(
      regNum, 
      password, 
      isFingerprintEnabled: _isFingerprintEnabled,
      isFaceEnabled: _isFaceEnabled,
    )) {
      _showSnackBar('Registration successful! Please login.', Colors.green);
      Navigator.pop(context);
    } else {
      _showSnackBar('Student ID already exists', Colors.redAccent);
    }
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
    _regController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : const Color(0xFF202124)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Row(
        children: [
          if (MediaQuery.of(context).size.width > 800)
            Expanded(
              child: Container(
                color: const Color(0xFF34A853),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.person_add_rounded, size: 120, color: Colors.white),
                      const SizedBox(height: 24),
                      const Text(
                        'Join the Election',
                        style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Register today to cast your secure vote.',
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
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF34A853).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.person_add_rounded, color: Color(0xFF34A853), size: 32),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Self Registration',
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF202124)),
                      ),
                      const Text(
                        'Register to Station',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                      const SizedBox(height: 32),
                      
                      TextField(
                        controller: _regController,
                        decoration: InputDecoration(
                          labelText: 'Student ID',
                          prefixIcon: const Icon(Icons.badge_outlined),
                          filled: true,
                          fillColor: isDark ? Colors.white10 : const Color(0xFFF8F9FA),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF34A853), width: 2)),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _passwordController,
                        obscureText: !_isPasswordVisible,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          helperText: 'At least 4 characters',
                          filled: true,
                          fillColor: isDark ? Colors.white10 : const Color(0xFFF8F9FA),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF34A853), width: 2)),
                          suffixIcon: IconButton(
                            icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off, size: 20),
                            onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _confirmPasswordController,
                        obscureText: !_isConfirmPasswordVisible,
                        decoration: InputDecoration(
                          labelText: 'Confirm Password',
                          prefixIcon: const Icon(Icons.lock_clock_outlined),
                          filled: true,
                          fillColor: isDark ? Colors.white10 : const Color(0xFFF8F9FA),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF34A853), width: 2)),
                          suffixIcon: IconButton(
                            icon: Icon(_isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off, size: 20),
                            onPressed: () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
                          ),
                        ),
                      ),
                      
                      if (_canCheckBiometrics) ...[
                        const SizedBox(height: 24),
                        const Text('Biometric Security (Optional)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey)),
                        const SizedBox(height: 8),
                        if (_hasFingerprint)
                          CheckboxListTile(
                            title: const Text('Enable Fingerprint'),
                            value: _isFingerprintEnabled,
                            onChanged: (val) => setState(() => _isFingerprintEnabled = val ?? false),
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: EdgeInsets.zero,
                          ),
                        if (_hasFace)
                          CheckboxListTile(
                            title: const Text('Enable Face Recognition'),
                            value: _isFaceEnabled,
                            onChanged: (val) => setState(() => _isFaceEnabled = val ?? false),
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: EdgeInsets.zero,
                          ),
                      ],

                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _register,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF34A853),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: const Text('Save Credentials', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Center(
                        child: Wrap(
                          children: [
                            const Text("Already registered? ", style: TextStyle(color: Colors.grey)),
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: const Text(
                                'Login',
                                style: TextStyle(color: Color(0xFF34A853), fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
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
}
