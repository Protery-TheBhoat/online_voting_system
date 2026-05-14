import 'package:flutter/material.dart';
import 'voting_service.dart';
import 'auth_service.dart';
import 'candidate.dart';
import 'dart:async';

class AdminPanel extends StatefulWidget {
  const AdminPanel({super.key});

  @override
  State<AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> with TickerProviderStateMixin {
  int _mainTabIndex = 0;
  late TabController _mgmtTabController;
  final VotingService _votingService = VotingService();
  final AuthService _authService = AuthService();
  StreamSubscription? _updateSubscription;

  final _nameController = TextEditingController();
  final _categoryController = TextEditingController();
  
  DateTime? _tempStart;
  DateTime? _tempEnd;

  @override
  void initState() {
    super.initState();
    // Sub-tabs for Management: Candidates and Poll Hub
    _mgmtTabController = TabController(length: 2, vsync: this);
    
    // Auto-clear session if it ended before opening the panel
    if (_votingService.isVotingEnded) {
      _votingService.clearSession();
    }

    _updateSubscription = _votingService.onUpdate.listen((_) {
      if (mounted) {
        final currentlyEnded = _votingService.isVotingEnded;

        if (currentlyEnded) {
          // Requirement: When election ends, management should be reopened empty and fresh
          _votingService.clearSession();
          setState(() {
            _tempStart = null;
            _tempEnd = null;
            _mainTabIndex = 1; // Reopen Management tab at the bottom
          });
          _mgmtTabController.animateTo(0); // Set to first sub-tab (Candidates)
          _showSessionEndAlert();
        }
        setState(() {});
      }
    });
  }

  void _showSessionEndAlert() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.auto_awesome_rounded, color: Colors.blueAccent),
            SizedBox(width: 12),
            Text('Session Reset'),
          ],
        ),
        content: const Text('The election has ended. The management panel has been reset for a fresh session.'),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _updateSubscription?.cancel();
    _mgmtTabController.dispose();
    _nameController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  void _publishSlip() {
    if (_tempStart == null || _tempEnd == null) {
      _showSnackBar('Please set election duration in Poll Hub', Colors.orange);
      setState(() => _mainTabIndex = 1);
      _mgmtTabController.animateTo(1);
      return;
    }
    if (_votingService.categoryList.isEmpty) {
      _showSnackBar('Please create at least one category first', Colors.orange);
      setState(() => _mainTabIndex = 1);
      _mgmtTabController.animateTo(0);
      return;
    }
    if (_votingService.candidates.isEmpty) {
      _showSnackBar('Please add candidates in Candidate Management', Colors.orange);
      setState(() => _mainTabIndex = 1);
      _mgmtTabController.animateTo(0);
      return;
    }

    _votingService.publishChanges(_tempStart, _tempEnd);
    
    // Requirement: Show "Slip published, View progress at dashboard"
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1), 
                shape: BoxShape.circle
              ),
              child: const Icon(Icons.rocket_launch_rounded, size: 64, color: Colors.blueAccent),
            ),
            const SizedBox(height: 24),
            const Text('Slip published', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text(
              'View progress at dashboard', 
              textAlign: TextAlign.center, 
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () {
                Navigator.pop(context);
                setState(() => _mainTabIndex = 0); // Switch to Dashboard tab at bottom
              },
              child: const Text('Go to Dashboard'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        title: Text(
          _mainTabIndex == 0 ? 'ADMIN DASHBOARD' : 'MANAGEMENT HUB',
          style: const TextStyle(color: Color(0xFF1A73E8), fontWeight: FontWeight.w900, letterSpacing: 1.2, fontSize: 18),
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
      body: IndexedStack(
        index: _mainTabIndex,
        children: [
          _buildDashboardTab(),
          _buildManagementTab(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 16, offset: const Offset(0, -4))],
        ),
        child: BottomNavigationBar(
          currentIndex: _mainTabIndex,
          onTap: (index) => setState(() => _mainTabIndex = index),
          selectedItemColor: const Color(0xFF1A73E8),
          unselectedItemColor: Colors.grey,
          backgroundColor: Colors.white,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard_rounded),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_suggest_outlined),
              activeIcon: Icon(Icons.settings_suggest_rounded),
              label: 'Management',
            ),
          ],
        ),
      ),
    );
  }

  // --- DASHBOARD TAB ---
  Widget _buildDashboardTab() {
    bool isVotingActive = _votingService.isVotingActive;
    bool isVotingEnded = _votingService.isVotingEnded;
    bool isPublished = _votingService.isPublished;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusBanner(isVotingActive, isVotingEnded, isPublished),
          const SizedBox(height: 24),
          _buildElectionPeriodCard(),
          const SizedBox(height: 32),
          if (isPublished) ...[
            const Row(
              children: [
                Icon(Icons.analytics_rounded, color: Color(0xFF1A73E8)),
                SizedBox(width: 12),
                Text('Live Results Progress', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 20),
            if (_votingService.categoryList.isEmpty)
              const Center(child: Text('No categories defined.'))
            else
              ..._votingService.categoryList.map((cat) => _buildLiveProgressCard(cat)),
          ] else
            _buildEmptyState(Icons.dashboard_customize_outlined, 'Dashboard Idle', 'Configure and publish an election slip in the Management tab.'),
        ],
      ),
    );
  }

  Widget _buildStatusBanner(bool active, bool ended, bool published) {
    Color color = Colors.orange;
    String text = 'PENDING SETUP';
    IconData icon = Icons.pending_rounded;

    if (active) {
      color = Colors.green;
      text = 'VOTING IS LIVE';
      icon = Icons.sensors_rounded;
    } else if (published && !ended) {
      color = Colors.blue;
      text = 'SESSION SCHEDULED';
      icon = Icons.schedule_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(text, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 0.5)),
                const SizedBox(height: 4),
                Text(published ? 'Election process in progress' : 'Awaiting session configuration.', style: TextStyle(color: Colors.grey.shade600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildElectionPeriodCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.grey.shade200)),
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
                    _votingService.isPublished 
                      ? '${_formatDateTime(_votingService.startTime)} - ${_formatDateTime(_votingService.endTime)}'
                      : 'Duration not set',
                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveProgressCard(String category) {
    final candidates = _votingService.getCandidatesByCategory(category);
    final int maxVotes = candidates.fold(0, (max, c) => c.votes > max ? c.votes : max);
    final int totalVotes = candidates.fold(0, (sum, c) => sum + c.votes);

    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: BorderSide(color: Colors.grey.shade100)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(category, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1A73E8))),
                Text('$totalVotes total votes', style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 24),
            if (candidates.isEmpty)
              const Text('No candidates in this category.', style: TextStyle(color: Colors.grey))
            else
              ...candidates.map((c) {
                final double ratio = maxVotes == 0 ? 0 : c.votes / maxVotes;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                          Text('${c.votes} votes', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: ratio,
                          minHeight: 10,
                          backgroundColor: Colors.grey.shade50,
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

  // --- MANAGEMENT TAB ---
  Widget _buildManagementTab() {
    bool isVotingActive = _votingService.isVotingActive;

    if (isVotingActive) {
      // Requirement: Disable access during active election with specific message
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: const Icon(Icons.lock_person_rounded, size: 80, color: Colors.orange),
            ),
            const SizedBox(height: 32),
            const Text(
              'Election not Ended',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'View progress at Dashboard tab',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 48),
            OutlinedButton.icon(
              onPressed: () => setState(() => _mainTabIndex = 0),
              icon: const Icon(Icons.dashboard_rounded),
              label: const Text('Go to Dashboard'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _mgmtTabController,
            labelColor: const Color(0xFF1A73E8),
            unselectedLabelColor: Colors.grey,
            indicatorSize: TabBarIndicatorSize.tab,
            indicatorWeight: 3,
            tabs: const [
              Tab(icon: Icon(Icons.person_add_alt_1_rounded), text: 'Candidates'),
              Tab(icon: Icon(Icons.how_to_vote_rounded), text: 'Poll Hub'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _mgmtTabController,
            children: [
              _buildCandidateMgmtSubTab(),
              _buildPollHubSubTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCandidateMgmtSubTab() {
    final categories = _votingService.categoryList;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Election Setup', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Row(
              children: [
                TextButton.icon(
                  onPressed: _showAddCategoryDialog, 
                  icon: const Icon(Icons.category_rounded, size: 18),
                  label: const Text('Category'),
                  style: TextButton.styleFrom(foregroundColor: Colors.blueGrey),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: categories.isEmpty ? null : _showAddCandidateDialog, 
                  icon: const Icon(Icons.add_rounded), 
                  label: const Text('Candidate'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A73E8),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),
        if (categories.isEmpty)
          _buildEmptyState(Icons.category_outlined, 'No Categories Created', 'Start by defining election categories (e.g. President).')
        else
          ...categories.map((cat) => _buildCategoryTile(cat)),
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildCategoryTile(String category) {
    final candidates = _votingService.getCandidatesByCategory(category);
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ExpansionTile(
        initiallyExpanded: true,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: const Color(0xFF1A73E8).withValues(alpha: 0.1), shape: BoxShape.circle),
          child: const Icon(Icons.folder_shared_rounded, color: Color(0xFF1A73E8), size: 20),
        ),
        title: Text(category, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Text('${candidates.length} candidates', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
              onPressed: () => _confirmDeleteCategory(category),
            ),
            const Icon(Icons.expand_more_rounded),
          ],
        ),
        childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          if (candidates.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text('No candidates added to this category.', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic, fontSize: 13)),
            )
          else
            ...candidates.map((c) => _buildCandidateItem(c)),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _showAddCandidateWithCategory(category),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Candidate'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 44),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildCandidateItem(Candidate c) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF1A73E8).withValues(alpha: 0.1),
          child: Text(c.name[0].toUpperCase(), style: const TextStyle(color: Color(0xFF1A73E8), fontWeight: FontWeight.bold)),
        ),
        title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: Colors.blueGrey, size: 20),
              onPressed: () => _showEditCandidateDialog(c),
            ),
            IconButton(
              icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 20),
              onPressed: () => setState(() => _votingService.removeCandidate(c.id)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPollHubSubTab() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Session Configuration', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                _buildTimePickerCard(),
                const SizedBox(height: 48),
                const Row(
                  children: [
                    Icon(Icons.assignment_rounded, color: Colors.blueGrey),
                    SizedBox(width: 12),
                    Text('Digital Ballot Preview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 16),
                _buildSlipPreview(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
        _buildBottomPublishBar(),
      ],
    );
  }

  Widget _buildTimePickerCard() {
    return InkWell(
      onTap: _pickDateTimeRange,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white, 
          borderRadius: BorderRadius.circular(24), 
          border: Border.all(color: const Color(0xFF1A73E8).withValues(alpha: 0.1)), 
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 12)]
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16), 
              decoration: BoxDecoration(color: const Color(0xFF1A73E8).withValues(alpha: 0.05), borderRadius: BorderRadius.circular(16)), 
              child: const Icon(Icons.timer_outlined, color: Color(0xFF1A73E8), size: 28)
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Set Session Duration', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                  Text(
                    _tempStart == null ? 'Tap to configure start/end' : '${_formatDateTime(_tempStart)} to ${_formatDateTime(_tempEnd)}', 
                    style: TextStyle(color: _tempStart == null ? Colors.grey : const Color(0xFF1A73E8), fontWeight: FontWeight.w600)
                  ),
                ],
              ),
            ),
            const Icon(Icons.edit_calendar_rounded, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildSlipPreview() {
    final categories = _votingService.categoryList;
    if (categories.isEmpty) return _buildEmptyState(Icons.pending_rounded, 'No Data for Slip', 'Setup categories and candidates in the previous tab.');
    
    return Column(
      children: [
        // Information Banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.blue.withValues(alpha: 0.1)),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline_rounded, color: Colors.blue, size: 20),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'This preview shows exactly what voters will see on their devices.',
                  style: TextStyle(color: Color(0xFF0D47A1), fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        // Digital Ballot Sheet
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 40,
                offset: const Offset(0, 12),
              )
            ],
          ),
          child: Column(
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FF),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                  border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)
                        ],
                      ),
                      child: const Icon(Icons.how_to_vote_rounded, color: Color(0xFF1A73E8), size: 32),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'OFFICIAL BALLOT',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                        letterSpacing: 2.5,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'VOTING SESSION · ${DateTime.now().year}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade500,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              // Body
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final cat = categories[index];
                  final candidates = _votingService.getCandidatesByCategory(cat);
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 32, 24, 20),
                        child: Row(
                          children: [
                            Text(
                              cat.toUpperCase(),
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                                letterSpacing: 1.2,
                                color: Color(0xFF1A73E8),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(child: Container(height: 1, color: Colors.grey.shade50)),
                            const SizedBox(width: 8),
                            const Text(
                              'CHOOSE 1',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      if (candidates.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 24),
                          child: Text('No candidates added.', style: TextStyle(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic)),
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            children: candidates.map((c) => Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.grey.shade100, width: 1.5),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1A73E8).withValues(alpha: 0.05),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Center(
                                      child: Text(
                                        c.name[0].toUpperCase(),
                                        style: const TextStyle(color: Color(0xFF1A73E8), fontWeight: FontWeight.bold, fontSize: 18),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Text(
                                      c.name,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                  ),
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.grey.shade300, width: 2),
                                    ),
                                  ),
                                ],
                              ),
                            )).toList(),
                          ),
                        ),
                    ],
                  );
                },
              ),
              // Footer
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 40),
                decoration: const BoxDecoration(
                  color: Color(0xFFFAFBFF),
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.verified_user_rounded, color: Colors.green, size: 24),
                    SizedBox(height: 12),
                    Text(
                      'SECURE PREVIEW MODE',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.black26, letterSpacing: 2),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildBottomPublishBar() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white, 
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 15, offset: const Offset(0, -5))]
      ),
      child: ElevatedButton(
        onPressed: _publishSlip,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1A73E8), 
          foregroundColor: Colors.white, 
          minimumSize: const Size(double.infinity, 64), 
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)), 
          elevation: 0
        ),
        child: const Text('PUBLISH SLIP TO LIVE', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
      ),
    );
  }

  // --- HELPERS ---
  Widget _buildEmptyState(IconData icon, String title, String sub) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60), 
        child: Column(
          children: [
            Icon(icon, size: 72, color: Colors.grey.shade200), 
            const SizedBox(height: 20), 
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)), 
            Text(sub, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey))
          ]
        )
      )
    );
  }

  void _showAddCategoryDialog() {
    _categoryController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Create Category'),
        content: TextField(
          controller: _categoryController, 
          decoration: const InputDecoration(labelText: 'Name (e.g. Secretary)', border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14))))
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () { 
              if (_categoryController.text.isNotEmpty) { 
                setState(() => _votingService.addCategory(_categoryController.text.trim())); 
                Navigator.pop(context); 
              } 
            }, 
            child: const Text('Create')
          ),
        ],
      ),
    );
  }

  void _confirmDeleteCategory(String category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Delete Category?'),
        content: Text('This will also remove all candidates in "$category". This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              setState(() => _votingService.removeCategory(category));
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showAddCandidateDialog() {
    _showAddCandidateWithCategory(null);
  }

  void _showAddCandidateWithCategory(String? preselectedCategory) {
    _nameController.clear();
    String? selectedCat = preselectedCategory ?? (_votingService.categoryList.isNotEmpty ? _votingService.categoryList[0] : null);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('New Candidate'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController, 
                decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person_outline), border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14))))
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: selectedCat,
                decoration: const InputDecoration(labelText: 'Respective Category', border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14)))),
                items: _votingService.categoryList.map((String value) {
                  return DropdownMenuItem<String>(value: value, child: Text(value));
                }).toList(),
                onChanged: (newValue) => setDialogState(() => selectedCat = newValue),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () { 
                if (_nameController.text.isNotEmpty && selectedCat != null) { 
                  setState(() => _votingService.addCandidate(_nameController.text.trim(), selectedCat!)); 
                  Navigator.pop(context); 
                } 
              }, 
              child: const Text('Add to Roster')
            ),
          ],
        ),
      ),
    );
  }

  void _showEditCandidateDialog(Candidate candidate) {
    _nameController.text = candidate.name;
    String? selectedCat = candidate.category;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('Edit Candidate'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14))),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: selectedCat,
                decoration: const InputDecoration(
                  labelText: 'Respective Category',
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14))),
                ),
                items: _votingService.categoryList.map((String value) {
                  return DropdownMenuItem<String>(value: value, child: Text(value));
                }).toList(),
                onChanged: (newValue) => setDialogState(() => selectedCat = newValue),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (_nameController.text.isNotEmpty && selectedCat != null) {
                  setState(() {
                    _votingService.updateCandidate(candidate.id, _nameController.text.trim(), selectedCat!);
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDateTimeRange() async {
    final DateTime now = DateTime.now();
    final DateTime? start = await showDatePicker(context: context, initialDate: now, firstDate: now, lastDate: now.add(const Duration(days: 365)));
    if (!mounted || start == null) return;
    
    final TimeOfDay? startTime = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (!mounted || startTime == null) return;
    
    final DateTime? end = await showDatePicker(context: context, initialDate: start, firstDate: start, lastDate: start.add(const Duration(days: 365)));
    if (!mounted || end == null) return;
    
    final TimeOfDay? endTime = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 23, minute: 59));
    if (!mounted || endTime == null) return;

    setState(() {
      _tempStart = DateTime(start.year, start.month, start.day, startTime.hour, startTime.minute);
      _tempEnd = DateTime(end.year, end.month, end.day, endTime.hour, endTime.minute);
    });
  }

  String _formatDateTime(DateTime? dt) {
    if (dt == null) return '--/--';
    return "${dt.day}/${dt.month} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
  }
}
