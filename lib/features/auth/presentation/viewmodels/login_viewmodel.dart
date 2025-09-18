import 'package:flutter/material.dart';

import '../../domain/entities/auth_result.dart';
import '../../domain/entities/otp_response.dart';
import '../../domain/entities/otp_validation_response.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/send_otp_usecase.dart';
import '../../domain/usecases/validate_otp_usecase.dart';

class LoginViewModel extends ChangeNotifier {
  final LoginUseCase loginUseCase;
  final SendOtpUseCase sendOtpUseCase;
  final ValidateOtpUseCase validateOtpUseCase;
  final AuthRepository authRepository;

  LoginViewModel({
    required this.loginUseCase,
    required this.sendOtpUseCase,
    required this.validateOtpUseCase,
    required this.authRepository,
  });

  // Form fields
  String _email = 'lakshmana.chimata@gmail.com';
  String _password = '';
  bool _rememberMe = false;
  bool _transactionalAlerts = false;
  bool _termsAndConditions = false;
  bool _isPasswordVisible = false;

  // State
  bool _isLoading = false;
  String? _errorMessage;
  bool _userDoesNotExist = false;

  // Getters
  String get email => _email;
  String get password => _password;
  bool get rememberMe => _rememberMe;
  bool get transactionalAlerts => _transactionalAlerts;
  bool get termsAndConditions => _termsAndConditions;
  bool get isPasswordVisible => _isPasswordVisible;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get userDoesNotExist => _userDoesNotExist;

  // Setters
  void setEmail(String value) {
    _email = value;
    _clearError();
    _userDoesNotExist = false; // Reset user existence flag when email changes
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

  void setTermsAndConditions(bool value) {
    _termsAndConditions = value;
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

  // Validate email and return validation result
  String? validateEmail() {
    if (_email.isEmpty) {
      return 'Please enter your email address';
    }

    if (!_isValidEmail(_email)) {
      return 'Please enter a valid email address';
    }

    return null; // No error
  }

  // Check if email is valid for enabling continue button
  bool get isEmailValid {
    return _email.isNotEmpty && _isValidEmail(_email);
  }

  // Send OTP to email
  Future<OtpResponse?> sendOtp() async {
    if (_email.isEmpty) {
      _setError('Please enter your email address');
      return null;
    }

    if (!_isValidEmail(_email)) {
      _setError('Please enter a valid email address');
      return null;
    }

    _setLoading(true);

    try {
      final result = await sendOtpUseCase(_email);

      return result.fold(
        (error) {
          _setError(error);
          return null;
        },
        (otpResponse) {
          _setLoading(false);
          return otpResponse;
        },
      );
    } catch (e) {
      _setError('An unexpected error occurred');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // Validate OTP
  Future<OtpValidationResponse?> validateOtp(String otp) async {
    if (_email.isEmpty) {
      _setError('Email is required for OTP validation');
      return null;
    }

    if (otp.isEmpty) {
      _setError('Please enter the OTP');
      return null;
    }

    _setLoading(true);

    try {
      final result = await validateOtpUseCase(_email, otp);

      return result.fold(
        (error) {
          _setError(error);
          // Check if the error indicates user doesn't exist
          if (error.contains('User does not exist') || error.contains('Please register')) {
            _userDoesNotExist = true;
          }
          return null;
        },
        (otpValidationResponse) {
          _setLoading(false);
          _userDoesNotExist = false; // Reset flag on success
          return otpValidationResponse;
        },
      );
    } catch (e) {
      _setError('An unexpected error occurred');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // Check if user should go to onboarding or dashboard
  Future<bool> shouldShowOnboarding() async {
    try {
      final hasCompleteProfile = await authRepository.hasCompleteProfile();
      print(
        '🔐 LoginViewModel: Should show onboarding: ${!hasCompleteProfile}',
      );
      return !hasCompleteProfile; // Show onboarding if profile is incomplete
    } catch (e) {
      print('🔐 LoginViewModel: Error checking profile: $e');
      return true; // Default to onboarding if there's an error
    }
  }

  // Get stored user data
  Future<Map<String, String>> getStoredUserData() async {
    try {
      return await authRepository.getStoredUserData();
    } catch (e) {
      print('🔐 LoginViewModel: Error getting stored user data: $e');
      return {};
    }
  }

  void clearForm() {
    _email = '';
    _password = '';
    _rememberMe = false;
    _transactionalAlerts = false;
    _termsAndConditions = false;
    _isPasswordVisible = false;
    _errorMessage = null;
    _userDoesNotExist = false;
    notifyListeners();
  }
}
