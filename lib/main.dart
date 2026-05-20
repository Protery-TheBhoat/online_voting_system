import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'splash_page.dart';
import 'login_page.dart';
import 'voting_service.dart';
import 'auth_service.dart';
import 'theme_service.dart';
import 'settings_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ThemeService().init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeService().themeMode,
      builder: (context, mode, child) {
        return MaterialApp(
          title: 'Poll Station',
          debugShowCheckedModeBanner: false,
          themeMode: mode,
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF1A73E8),
              primary: const Color(0xFF1A73E8),
              secondary: const Color(0xFF34A853),
              surface: Colors.white,
            ),
            textTheme: const TextTheme(
              headlineMedium: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF202124)),
              titleLarge: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF202124)),
              bodyLarge: TextStyle(color: Color(0xFF3C4043)),
            ),
            cardTheme: CardThemeData(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              color: Colors.white,
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A73E8),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF1A73E8),
              brightness: Brightness.dark,
              primary: const Color(0xFF1A73E8),
              secondary: const Color(0xFF34A853),
            ),
            cardTheme: CardThemeData(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A73E8),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          home: const SplashPage(),
          routes: {
            '/login': (context) => const LoginPage(),
          },
        );
      },
    );
  }
}

class VotingDashboard extends StatefulWidget {
  const VotingDashboard({super.key, required this.title});
  final String title;

  @override
  State<VotingDashboard> createState() => _VotingDashboardState();
}

class _VotingDashboardState extends State<VotingDashboard> {
  int _selectedIndex = 0;
  final VotingService _votingService = VotingService();
  final AuthService _authService = AuthService();
  StreamSubscription? _updateSubscription;
  final Map<String, String> _selectedCandidates = {};
  Timer? _refreshTimer;
  bool _wasVotingEnded = false;

  @override
  void initState() {
    super.initState();
    _wasVotingEnded = _votingService.isVotingEnded;
    _updateSubscription = _votingService.onUpdate.listen((_) {
      if (mounted) {
        final currentlyEnded = _votingService.isVotingEnded;
        if (currentlyEnded && !_wasVotingEnded) {
          _showWinnerAnnouncement();
        }
        _wasVotingEnded = currentlyEnded;
        setState(() {});
      }
    });
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _updateSubscription?.cancel();
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _showWinnerAnnouncement() {
    _showSnackBar('Voting has officially ended! Final results are now being announced.', Colors.green.shade800);
    setState(() {
      _selectedIndex = 0;
    });
  }

  void _submitVotes() {
    if (!_votingService.isVotingActive) {
      _showSnackBar('Voting is currently closed.', Colors.red);
      return;
    }

    if (_selectedCandidates.length < _votingService.categories.length) {
      _showSnackBar('Please select a candidate for each category.', Colors.orange);
      return;
    }

    setState(() {
      _votingService.castVotes(_selectedCandidates);
      _authService.syncUserVote();
      _selectedCandidates.clear();
      _selectedIndex = 0;
    });
    
    _showSnackBar('Votes cast successfully!', Colors.green);
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  String _formatDateTime(DateTime? dt) {
    if (dt == null) return 'Not set';
    return "${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    final isVotingActive = _votingService.isVotingActive;
    final isVotingEnded = _votingService.isVotingEnded;
    final isPublished = _votingService.isPublished;
    final categories = _votingService.categories.toList();
    final hasVoted = _authService.currentUser?.hasVoted ?? false;
    final isAdmin = _authService.isAdmin;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final List<Widget> pages = [
      _buildHome(isVotingActive, isVotingEnded, isAdmin),
    ];

    if (!isAdmin) {
      pages.add(_buildVotingInterface(hasVoted, isVotingActive, isVotingEnded, isPublished, categories));
    }

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDark ? Colors.black : Colors.white,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.settings_outlined),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsPage())),
        ),
        title: Text(
          _selectedIndex == 0 ? 'POLL STATION' : 'CAST HUB',
          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A73E8), fontSize: 16),
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            onPressed: () async {
              final navigator = Navigator.of(context);
              await _authService.logout();
              navigator.pushReplacementNamed('/login');
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: pages.length > _selectedIndex ? pages[_selectedIndex] : pages[0],
      ),
      bottomNavigationBar: isAdmin ? null : Container(
        decoration: BoxDecoration(
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5))],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          elevation: 0,
          selectedItemColor: const Color(0xFF1A73E8),
          unselectedItemColor: Colors.grey,
          onTap: (index) => setState(() => _selectedIndex = index),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'Status'),
            BottomNavigationBarItem(icon: Icon(Icons.ballot_outlined), activeIcon: Icon(Icons.ballot_rounded), label: 'Vote'),
          ],
        ),
      ),
    );
  }

  Widget _buildHome(bool isVotingActive, bool isVotingEnded, bool isAdmin) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusBanner(isVotingActive, isVotingEnded),
          const SizedBox(height: 24),
          Text(
            isAdmin ? 'Hello, Administrator' : 'Hello, ${_authService.currentUser?.stuID ?? "Voter"}',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const Text('Secure Online Voting Platform', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),
          _buildElectionPeriodCard(),
          const SizedBox(height: 32),
          if (isVotingActive) ...[
            const Row(
              children: [
                Icon(Icons.analytics_outlined, color: Color(0xFF1A73E8)),
                SizedBox(width: 8),
                Text('Live Results Progress', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            ..._votingService.categories.map((category) => _buildResultCard(category)),
          ] else if (isVotingEnded) ...[
            const Row(
              children: [
                Icon(Icons.emoji_events_outlined, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  'Final Election Winners', 
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ..._votingService.categories.map((category) => _buildWinnerCard(category)),
          ] else 
            Center(
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  Icon(Icons.event_busy_outlined, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  const Text('Voting is currently closed', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const Text('Results will appear once voting time begins.', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusBanner(bool isActive, bool isEnded) {
    Color bgColor = Colors.red.withValues(alpha: 0.1);
    Color borderColor = Colors.red.withValues(alpha: 0.3);
    Color textColor = Colors.red.shade700;
    IconData icon = Icons.stop_circle;
    String text = 'VOTING SESSION CLOSED';

    if (isActive) {
      bgColor = Colors.green.withValues(alpha: 0.1);
      borderColor = Colors.green.withValues(alpha: 0.3);
      textColor = Colors.green.shade700;
      icon = Icons.circle;
      text = 'VOTING SESSION ACTIVE';
    } else if (isEnded) {
      bgColor = const Color(0xFFC0C0C0).withValues(alpha: 0.1);
      borderColor = const Color(0xFFC0C0C0).withValues(alpha: 0.3);
      textColor = Colors.blue.shade700;
      icon = Icons.emoji_events;
      text = 'VOTING SESSION ENDED';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildElectionPeriodCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFF1A73E8).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.calendar_today_rounded, color: Color(0xFF1A73E8)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Election Period', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    '${_formatDateTime(_votingService.startTime)} - ${_formatDateTime(_votingService.endTime)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(String category) {
    final catCandidates = _votingService.getCandidatesByCategory(category);
    final int totalVotes = catCandidates.fold(0, (sum, c) => sum + c.votes);
    final int maxVotes = catCandidates.fold(0, (max, c) => c.votes > max ? c.votes : max);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(category, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1A73E8))),
            const SizedBox(height: 16),
            ...catCandidates.map((c) {
              final double percentage = totalVotes == 0 ? 0 : (c.votes / totalVotes) * 100;
              final double progressValue = maxVotes == 0 ? 0 : c.votes / maxVotes;
              
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 30,
                                backgroundColor: const Color(0xFF1A73E8).withValues(alpha: 0.1),
                                backgroundImage: c.imagePath != null ? FileImage(File(c.imagePath!)) : null,
                                child: c.imagePath == null ? Text(c.name[0].toUpperCase(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)) : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(c.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                    Text(c.program, style: const TextStyle(fontSize: 11)),
                                    Text('Level ${c.level}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                    Text(c.academicYear, style: const TextStyle(fontSize: 11, color: Colors.blueAccent, fontWeight: FontWeight.bold)),
                                    Text('${c.votes} votes', style: const TextStyle(fontSize: 10, color: Colors.blue, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text('${percentage.toStringAsFixed(1)}%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: progressValue,
                        minHeight: 8,
                        backgroundColor: Colors.grey.withValues(alpha: 0.2),
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1A73E8)),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildWinnerCard(String category) {
    final winners = _votingService.getWinnersByCategory(category);
    final candidates = _votingService.getCandidatesByCategory(category);
    final int totalVotes = candidates.fold(0, (sum, c) => sum + c.votes);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: Colors.grey.withValues(alpha: 0.1), 
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Colors.green, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(category.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue)),
                const Icon(Icons.workspace_premium, color: Colors.green),
              ],
            ),
            const SizedBox(height: 16),
            if (winners.isEmpty)
              const Text('No votes cast for this category', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey))
            else
              ...winners.map((w) {
                final double percentage = totalVotes == 0 ? 0 : (w.votes / totalVotes) * 100;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green, size: 20),
                      const SizedBox(width: 8),
                      CircleAvatar(
                        radius: 35,
                        backgroundColor: Colors.white,
                        backgroundImage: w.imagePath != null ? FileImage(File(w.imagePath!)) : null,
                        child: w.imagePath == null ? Text(w.name[0].toUpperCase(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)) : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              w.name,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            Text(w.program, style: const TextStyle(fontSize: 12)),
                            Text('Level ${w.level}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            Text(w.academicYear, style: const TextStyle(fontSize: 12, color: Colors.blueAccent, fontWeight: FontWeight.bold)),
                            Text('${w.votes} votes (${percentage.toStringAsFixed(1)}%)', style: const TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      Text('${percentage.toStringAsFixed(0)}%', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 18)),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildVotingInterface(bool hasVoted, bool isVotingActive, bool isVotingEnded, bool isPublished, List<String> categories) {
    if (!isPublished) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: const Icon(Icons.ballot_outlined, size: 80, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            const Text('No Election Published', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Awaiting a new election slip from the admin.', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    if (isVotingEnded) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: const Icon(Icons.history_toggle_off_rounded, size: 80, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            const Text('Session Completed', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('This voting session has officially ended.', style: TextStyle(color: Colors.grey)),
            const Text('Awaiting the next election slip from the administrator.', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
            const SizedBox(height: 32),
            OutlinedButton.icon(
              onPressed: () => setState(() => _selectedIndex = 0),
              icon: const Icon(Icons.analytics_outlined),
              label: const Text('View Final Results'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
              ),
            ),
          ],
        ),
      );
    }

    // Message displayed only when student already voted and session NOT ended
    if (hasVoted) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: const Icon(Icons.check_circle_rounded, size: 80, color: Colors.green),
            ),
            const SizedBox(height: 24),
            const Text('Vote Recorded!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('You have already cast your ballot.', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    if (!isVotingActive) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: const Icon(Icons.timer_outlined, size: 80, color: Colors.orange),
            ),
            const SizedBox(height: 24),
            const Text('Voting is Closed', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('The election session has not started yet.', style: TextStyle(color: Colors.grey)),
            const Text('Please check back during the election period.', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(20.0),
            itemCount: categories.length,
            itemBuilder: (context, catIndex) {
              final category = categories[catIndex];
              final candidates = _votingService.getCandidatesByCategory(category);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                    child: Text(category, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  RadioGroup<String>(
                    groupValue: _selectedCandidates[category],
                    onChanged: (String? value) {
                      if (value != null) {
                        setState(() => _selectedCandidates[category] = value);
                      }
                    },
                    child: Column(
                      children: candidates.map((candidate) {
                        final isSelected = _selectedCandidates[category] == candidate.id;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF1A73E8).withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: isSelected ? const Color(0xFF1A73E8) : Colors.grey.shade400, width: isSelected ? 2 : 1),
                          ),
                          child: RadioListTile<String>(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            title: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    image: candidate.imagePath != null ? DecorationImage(image: FileImage(File(candidate.imagePath!)), fit: BoxFit.cover) : null,
                                  ),
                                  child: candidate.imagePath == null ? Center(child: Text(candidate.name[0].toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 32, color: Colors.black))) : null,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(candidate.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                      const SizedBox(height: 4),
                                      Text(candidate.program, style: const TextStyle(fontSize: 12)),
                                      Text('Level ${candidate.level}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                      Text(candidate.academicYear, style: const TextStyle(fontSize: 12, color: Colors.blueAccent, fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            value: candidate.id,
                            activeColor: const Color(0xFF1A73E8),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5))],
          ),
          child: ElevatedButton(
            onPressed: _submitVotes,
            child: const Text('Cast Vote'),
          ),
        ),
      ],
    );
  }
}
