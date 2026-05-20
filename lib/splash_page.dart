import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'login_page.dart';
import 'auth_service.dart';
import 'voting_service.dart';
import 'admin_panel.dart';
import 'main.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _textFadeAnimation;
  final _authService = AuthService();
  final _votingService = VotingService();
  final LocalAuthentication auth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _textFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.7, curve: Curves.easeIn),
      ),
    );

    _controller.forward();
    _handleRouting();
  }

  Future<bool> _authenticateBiometrically() async {
    try {
      final bool canCheckBiometrics = await auth.canCheckBiometrics;
      final bool isDeviceSupported = await auth.isDeviceSupported();

      if (!canCheckBiometrics && !isDeviceSupported) return true;

      final List<BiometricType> availableBiometrics = await auth.getAvailableBiometrics();
      bool hasFace = availableBiometrics.contains(BiometricType.face);
      bool hasFingerprint = availableBiometrics.contains(BiometricType.fingerprint);

      if (availableBiometrics.isEmpty && isDeviceSupported) {
        return await auth.authenticate(
          localizedReason: 'Please authenticate to resume your session securely',
          options: const AuthenticationOptions(stickyAuth: true),
        );
      }

      String? selectedMethod;
      if (hasFace && hasFingerprint) {
        if (!mounted) return false;
        selectedMethod = await showDialog<String>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Column(
              children: [
                Icon(Icons.security, size: 48, color: Color(0xFF1A73E8)),
                SizedBox(height: 16),
                Text('Secure Verification', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            content: const Text(
              'Please select your preferred biometric method to continue.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            actionsAlignment: MainAxisAlignment.spaceEvenly,
            actions: [
              _buildBiometricChoice(context, 'Face ID', Icons.face_retouching_natural_rounded),
              _buildBiometricChoice(context, 'Fingerprint', Icons.fingerprint_rounded),
            ],
            contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            actionsPadding: const EdgeInsets.only(bottom: 24),
          ),
        );
        if (selectedMethod == null) return false;
      } else if (hasFace) {
        selectedMethod = 'Face ID';
      } else if (hasFingerprint) {
        selectedMethod = 'Fingerprint';
      }

      return await auth.authenticate(
        localizedReason: 'Authenticating with ${selectedMethod ?? "biometrics"}',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } catch (e) {
      return false;
    }
  }

  Widget _buildBiometricChoice(BuildContext context, String label, IconData icon) {
    return InkWell(
      onTap: () => Navigator.pop(context, label),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: const Color(0xFF1A73E8)),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleRouting() async {
    await Future.wait([
      _authService.init(),
      _votingService.init(),
      Future.delayed(const Duration(seconds: 2)),
    ]);

    if (!mounted) return;

    Widget nextScreen = const LoginPage();
    
    if (_authService.currentUser != null) {
      final authenticated = await _authenticateBiometrically();
      if (authenticated) {
        nextScreen = const VotingDashboard(title: 'Poll Station');
      } else {
        await _authService.logout();
        nextScreen = const LoginPage();
      }
    } else if (_authService.isAdmin) {
      nextScreen = const AdminPanel();
    }

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => nextScreen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A73E8), Color(0xFF0D47A1)],
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.how_to_vote_rounded,
                  size: 150,
                  color: Colors.white,
                ),
              ),
            ),
            Positioned(
              bottom: 80,
              left: 0,
              right: 0,
              child: FadeTransition(
                opacity: _textFadeAnimation,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Poll Station',
                      style: TextStyle(
                        fontSize: 36,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Secure • Transparent • Reliable',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.8),
                        fontWeight: FontWeight.w300,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 40),
                    const ThreeDotsIndicator(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ThreeDotsIndicator extends StatefulWidget {
  const ThreeDotsIndicator({super.key});

  @override
  State<ThreeDotsIndicator> createState() => _ThreeDotsIndicatorState();
}

class _ThreeDotsIndicatorState extends State<ThreeDotsIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            double delay = index * 0.2;
            double value = (_controller.value + delay) % 1.0;
            double opacity = 0.3 + (0.7 * (1.0 - (value - 0.5).abs() * 2));
            double scale = 0.8 + (0.4 * (1.0 - (value - 0.5).abs() * 2));

            return Transform.scale(
              scale: scale,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(opacity.clamp(0.3, 1.0)),
                  shape: BoxShape.circle,
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
