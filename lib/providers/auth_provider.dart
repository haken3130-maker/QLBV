import 'package:flutter/material.dart';
import '../models/app_user.dart';
import '../repositories/salary_repository.dart';

class AuthProvider extends ChangeNotifier {
  final SalaryRepository _repository = SalaryRepository();
  
  AppUser? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  AppUser? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool get isAdmin => _currentUser?.role == 'admin';
  bool get isLeader => _currentUser?.role == 'leader' || isAdmin;

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _repository.signIn(email, password);
      _currentUser = user;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _repository.signOut();
    _currentUser = null;
    notifyListeners();
  }


}
