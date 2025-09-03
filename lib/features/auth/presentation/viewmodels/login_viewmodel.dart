import 'package:flutter/material.dart';
import '../../domain/entities/auth_result.dart';
import '../../domain/usecases/login_usecase.dart';

class LoginViewModel extends ChangeNotifier {
  final LoginUseCase loginUseCase;

  LoginViewModel({required this.loginUseCase});

  // Form fields
  String _email = '';
  String _password = '';
  bool _rememberMe = false;
  bool _transactionalAlerts = false;
  bool _isPasswordVisible = false;

  // State
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  String get email => _email;
  String get password => _password;
  bool get rememberMe => _rememberMe;
  bool get transactionalAlerts => _transactionalAlerts;
  bool get isPasswordVisible => _isPasswordVisible;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Setters
  void setEmail(String value) {
    _email = value;
    _clearError();
    notifyListeners();
  }

  void setPassword(String value) {
    _password = value;
    _clearError();
    notifyListeners();
  }

  void setRememberMe(bool value) {
    _rememberMe = value;
    notifyListeners();
  }

  void setTransactionalAlerts(bool value) {
    _transactionalAlerts = value;
    notifyListeners();
  }

  void togglePasswordVisibility() {
    _isPasswordVisible = !_isPasswordVisible;
    notifyListeners();
  }

  void _clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  Future<AuthResult?> login() async {
    if (_email.isEmpty || _password.isEmpty) {
      _setError('Please fill in all fields');
      return null;
    }

    if (!_isValidEmail(_email)) {
      _setError('Please enter a valid email');
      return null;
    }

    _setLoading(true);

    try {
      final result = await loginUseCase(_email, _password, _rememberMe);
      
      return result.fold(
        (error) {
          _setError(error);
          return null;
        },
        (authResult) {
          _setLoading(false);
          return authResult;
        },
      );
    } catch (e) {
      _setError('An unexpected error occurred');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  void clearForm() {
    _email = '';
    _password = '';
    _rememberMe = false;
    _transactionalAlerts = false;
    _isPasswordVisible = false;
    _errorMessage = null;
    notifyListeners();
  }
}
