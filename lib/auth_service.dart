<<<<<<< HEAD
import 'dart:convert';
=======
>>>>>>> 5d074f00a8e499b2509714de8876352566b6470d
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'user.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final List<User> _users = [];
  User? _currentUser;
  bool _isAdmin = false;
  bool _isInitialized = false;

  User? get currentUser => _currentUser;
  bool get isAdmin => _isAdmin;
  bool get isInitialized => _isInitialized;

  Future<void> init() async {
    if (_isInitialized) return;
    
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
<<<<<<< HEAD
      
      // Load all registered users
      final String? allUsersJson = prefs.getString('all_users');
      if (allUsersJson != null) {
        final List<dynamic> list = json.decode(allUsersJson);
        _users.clear();
        for (var item in list) {
          _users.add(User(
            stuID: item['stuID'],
            password: item['password'],
            hasVoted: item['hasVoted'] ?? false,
            isFingerprintEnabled: item['isFingerprintEnabled'] ?? false,
          ));
        }
      }

=======
>>>>>>> 5d074f00a8e499b2509714de8876352566b6470d
      final String? stuID = prefs.getString('stuID');
      final bool isAdminFlag = prefs.getBool('isAdmin') ?? false;

      if (isAdminFlag) {
        _isAdmin = true;
        _currentUser = null;
      } else if (stuID != null) {
<<<<<<< HEAD
        final userIndex = _users.indexWhere((u) => u.stuID == stuID);
        if (userIndex != -1) {
          _currentUser = _users[userIndex];
        } else {
          _currentUser = User(stuID: stuID, password: '');
        }
=======
        _currentUser = User(stuID: stuID, password: ''); 
>>>>>>> 5d074f00a8e499b2509714de8876352566b6470d
        _isAdmin = false;
      }
    } catch (e) {
      debugPrint('AuthService initialization failed: $e');
    }
    
    _isInitialized = true;
  }

<<<<<<< HEAD
  Future<void> _persistUsers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usersData = _users.map((u) => {
        'stuID': u.stuID,
        'password': u.password,
        'hasVoted': u.hasVoted,
        'isFingerprintEnabled': u.isFingerprintEnabled,
      }).toList();
      await prefs.setString('all_users', json.encode(usersData));
    } catch (e) {
      debugPrint('AuthService persist users failed: $e');
    }
  }

=======
>>>>>>> 5d074f00a8e499b2509714de8876352566b6470d
  bool register(String stuID, String password) {
    if (_users.any((u) => u.stuID == stuID)) {
      return false;
    }
    _users.add(User(
      stuID: stuID, 
      password: password,
    ));
<<<<<<< HEAD
    _persistUsers();
=======
>>>>>>> 5d074f00a8e499b2509714de8876352566b6470d
    return true;
  }

  Future<bool> login(String stuID, String password) async {
<<<<<<< HEAD
=======
    // Validate against registered users
>>>>>>> 5d074f00a8e499b2509714de8876352566b6470d
    final userIndex = _users.indexWhere((u) => u.stuID == stuID && u.password == password);
    
    if (userIndex != -1) {
      _currentUser = _users[userIndex];
      _isAdmin = false;
      
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('stuID', stuID);
        await prefs.setBool('isAdmin', false);
      } catch (e) {
        debugPrint('Login storage error: $e');
      }
      return true;
    }
    return false;
  }

<<<<<<< HEAD
  Future<void> syncUserVote() async {
    if (_currentUser != null) {
      _currentUser!.hasVoted = true;
      await _persistUsers();
    }
  }

=======
>>>>>>> 5d074f00a8e499b2509714de8876352566b6470d
  Future<bool> adminLogin(String username, String password) async {
    if (username == 'admin' && password == 'admin123') {
      _isAdmin = true;
      _currentUser = null;
      
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('stuID');
        await prefs.setBool('isAdmin', true);
      } catch (_) {}
      
      return true;
    }
    return false;
  }

  Future<void> logout() async {
    _currentUser = null;
    _isAdmin = false;
    try {
<<<<<<< HEAD
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove('stuID');
      await prefs.remove('isAdmin');
=======
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
>>>>>>> 5d074f00a8e499b2509714de8876352566b6470d
    } catch (_) {}
  }
}
