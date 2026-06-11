import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_user.dart';
import '../repositories/salary_repository.dart';
import '../services/springboot_database_service.dart';

class AuthProvider extends ChangeNotifier {
  late final SalaryRepository _repository;
  
  AppUser? _currentUser;
  bool _isLoading = false;
  bool _isInitializing = true;
  String? _errorMessage;

  AppUser? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isInitializing => _isInitializing;
  String? get errorMessage => _errorMessage;

  bool get isAdmin => _currentUser?.role == 'admin';
  bool get isLeader => _currentUser?.role == 'leader' || isAdmin;

  AuthProvider() {
    // Initialize repository after this provider is created
    _repository = SalaryRepository();
    SpringBootDatabaseService.onSessionExpired = () {
      logout();
    };
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _repository.signIn(email, password);
      _currentUser = user;
      
      print('[AuthProvider.login] After signIn:');
      print('[AuthProvider.login] - token: ${SpringBootDatabaseService.token != null ? SpringBootDatabaseService.token!.substring(0, 30) + '...' : 'NULL'}');
      print('[AuthProvider.login] - refreshToken: ${SpringBootDatabaseService.refreshToken != null ? SpringBootDatabaseService.refreshToken!.substring(0, 30) + '...' : 'NULL'}');
      
      final prefs = await SharedPreferences.getInstance();
      
      // Only save tokens if they're not null/empty
      if (SpringBootDatabaseService.token != null && SpringBootDatabaseService.token!.isNotEmpty) {
        await prefs.setString('auth_token', SpringBootDatabaseService.token!);
        print('[AuthProvider.login] ✓ Saved access token');
      }
      if (SpringBootDatabaseService.refreshToken != null && SpringBootDatabaseService.refreshToken!.isNotEmpty) {
        await prefs.setString('auth_refresh_token', SpringBootDatabaseService.refreshToken!);
        print('[AuthProvider.login] ✓ Saved refresh token');
      } else {
        print('[AuthProvider.login] ✗ refreshToken is null/empty after login');
        _errorMessage = 'Lỗi: Không nhận được refresh token từ server';
        _isLoading = false;
        notifyListeners();
        return false;
      }
      
      await prefs.setString('auth_user_uid', _currentUser?.uid ?? '');
      await prefs.setString('auth_user_email', _currentUser?.email ?? '');
      await prefs.setString('auth_user_name', _currentUser?.name ?? '');
      await prefs.setString('auth_user_role', _currentUser?.role ?? 'leader');
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      print('[AuthProvider.login] ✗ Login failed: $_errorMessage');
      notifyListeners();
      return false;
    }
  }

  Future<void> loadSavedSession() async {
    _isInitializing = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString('auth_user_uid');
    final email = prefs.getString('auth_user_email');
    final name = prefs.getString('auth_user_name');
    final role = prefs.getString('auth_user_role');

    // Token already restored in main.dart via _initializeAuth()
    // Just restore user info to provider
    if (uid != null && email != null && name != null && role != null) {
      _currentUser = AppUser(uid: uid, email: email, name: name, role: role);
    }

    _isInitializing = false;
    notifyListeners();
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('auth_refresh_token');
    await prefs.remove('auth_user_uid');
    await prefs.remove('auth_user_email');
    await prefs.remove('auth_user_name');
    await prefs.remove('auth_user_role');
    await _repository.signOut();
    _currentUser = null;
    notifyListeners();
  }


}
