import 'dart:async';
import 'candidate.dart';

class VotingService {
  static final VotingService _instance = VotingService._internal();
  factory VotingService() => _instance;
  VotingService._internal();

  // Start with empty lists as requested
  final List<Candidate> _candidates = [];
  final List<String> _categories = [];

  DateTime? _startTime;
  DateTime? _endTime;
  Timer? _refreshTimer;
  bool _isPublished = false;

  final _updateController = StreamController<void>.broadcast();
  Stream<void> get onUpdate => _updateController.stream;

  List<Candidate> get candidates => List.unmodifiable(_candidates);
  List<String> get categoryList => List.unmodifiable(_categories);
  bool get isPublished => _isPublished;
  
  bool get isVotingActive {
    final start = _startTime;
    final end = _endTime;
    if (start == null || end == null || !_isPublished) return false;
    final now = DateTime.now();
    return now.isAfter(start) && now.isBefore(end);
  }

  bool get isVotingEnded {
    final end = _endTime;
    if (end == null || !_isPublished) return false;
    return DateTime.now().isAfter(end);
  }

  DateTime? get startTime => _startTime;
  DateTime? get endTime => _endTime;

  Set<String> get categories => _categories.toSet();

  void addCategory(String category) {
    if (!_categories.contains(category)) {
      _categories.add(category);
      _updateController.add(null);
    }
  }

  void removeCategory(String category) {
    _categories.remove(category);
    _candidates.removeWhere((c) => c.category == category);
    _updateController.add(null);
  }

  List<Candidate> getCandidatesByCategory(String category) {
    return _candidates.where((c) => c.category == category).toList();
  }

  List<Candidate> getWinnersByCategory(String category) {
    final catCandidates = getCandidatesByCategory(category);
    if (catCandidates.isEmpty) return [];
    
    int maxVotes = catCandidates.fold(0, (max, c) => c.votes > max ? c.votes : max);
    if (maxVotes == 0) return []; 
    
    return catCandidates.where((c) => c.votes == maxVotes).toList();
  }

  void _scheduleAutoRefresh() {
    _refreshTimer?.cancel();
    final now = DateTime.now();

    DateTime? nextTarget;
    final start = _startTime;
    final end = _endTime;

    if (start != null && start.isAfter(now)) {
      nextTarget = start;
    } else if (end != null && end.isAfter(now)) {
      nextTarget = end;
    }

    if (nextTarget != null) {
      final duration = nextTarget.difference(now);
      _refreshTimer = Timer(duration + const Duration(milliseconds: 500), () {
        _updateController.add(null);
        _scheduleAutoRefresh();
      });
    }
  }

  void addCandidate(String name, String category) {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    _candidates.add(Candidate(id: id, name: name, category: category));
    _updateController.add(null);
  }

  void removeCandidate(String id) {
    _candidates.removeWhere((c) => c.id == id);
    _updateController.add(null);
  }

  void updateCandidate(String id, String newName, String newCategory) {
    final index = _candidates.indexWhere((c) => c.id == id);
    if (index != -1) {
      final oldVotes = _candidates[index].votes;
      _candidates[index] = Candidate(id: id, name: newName, category: newCategory, votes: oldVotes);
      _updateController.add(null);
    }
  }

  void publishChanges(DateTime? start, DateTime? end) {
    _startTime = start;
    _endTime = end;
    _isPublished = true;
    _scheduleAutoRefresh();
    _updateController.add(null);
  }

  void castVotes(Map<String, String> selectedVotes) {
    if (!isVotingActive) return;
    selectedVotes.forEach((category, candidateId) {
      final index = _candidates.indexWhere((c) => c.id == candidateId);
      if (index != -1) {
        _candidates[index].votes++;
      }
    });
    _updateController.add(null);
  }

  void clearSession() {
    _candidates.clear();
    _categories.clear();
    _startTime = null;
    _endTime = null;
    _isPublished = false;
    _refreshTimer?.cancel();
    _updateController.add(null);
  }
}
