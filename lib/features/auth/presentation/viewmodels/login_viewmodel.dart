import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/routing/app_router_config.dart';
import '../../../../core/utils/device_helper.dart';
import '../../domain/entities/auth_result.dart';
import '../../domain/entities/otp_response.dart';
import '../../domain/entities/otp_validation_response.dart';
import '../../domain/entities/social_login_request.dart';
import '../../domain/entities/social_login_response.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/send_otp_usecase.dart';
import '../../domain/usecases/social_login_usecase.dart';
import '../../domain/usecases/validate_otp_usecase.dart';

class LoginViewModel extends ChangeNotifier {
  final LoginUseCase loginUseCase;
  final SendOtpUseCase sendOtpUseCase;
  final ValidateOtpUseCase validateOtpUseCase;
  final SocialLoginUseCase socialLoginUseCase;
  final AuthRepository authRepository;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  LoginViewModel({
    required this.loginUseCase,
    required this.sendOtpUseCase,
    required this.validateOtpUseCase,
    required this.socialLoginUseCase,
    required this.authRepository,
  });

  // Form fields
  String _email = 'lakshmana.chimata@gmail.com';
  String _password = '';
  bool _rememberMe = false;
  bool _transactionalAlerts = true;
  bool _termsAndConditions = false;
  bool _privacyPolicyAccepted = false;
  bool _termsAndConditionsAccepted = false;
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
  bool get privacyPolicyAccepted => _privacyPolicyAccepted;
  bool get termsAndConditionsAccepted => _termsAndConditionsAccepted;
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

  void setPrivacyPolicyAccepted(bool value) {
    _privacyPolicyAccepted = value;
    notifyListeners();
  }

  void setTermsAndConditionsAccepted(bool value) {
    _termsAndConditionsAccepted = value;
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

  // Determine navigation based on user profile state
  Future<String> getNavigationRoute() async {
    try {
      final hasCompleteProfile = await authRepository.hasCompleteProfile();
      final hasBasicProfileButNoDevices = await authRepository.hasBasicProfileButNoDevices();
      
      print('🔐 LoginViewModel: Profile check - Complete: $hasCompleteProfile, Basic but no devices: $hasBasicProfileButNoDevices');
      
      if (hasCompleteProfile) {
        print('🔐 LoginViewModel: User has complete profile - navigating to dashboard');
        return 'dashboard';
      } else if (hasBasicProfileButNoDevices) {
        print('🔐 LoginViewModel: User has basic profile but no devices - navigating to onboard device');
        return 'onboardDevice';
      } else {
        print('🔐 LoginViewModel: User has incomplete profile - navigating to onboarding');
        return 'onboarding';
      }
    } catch (e) {
      print('🔐 LoginViewModel: Error checking profile: $e');
      return 'onboarding'; // Default to onboarding if there's an error
    }
  }

  // Check if user should go to onboarding or dashboard (legacy method for compatibility)
  Future<bool> shouldShowOnboarding() async {
    try {
      final route = await getNavigationRoute();
      return route == 'onboarding';
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

  Future<void> signInWithGoogle(BuildContext context) async {
    try {
      _isLoading = true;
      notifyListeners();

      print('🔐 LoginViewModel: Starting Google Sign-In');

      // Sign in with Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        print('🔐 LoginViewModel: Google Sign-In cancelled by user');
        _isLoading = false;
        notifyListeners();
        return;
      }

      print('🔐 LoginViewModel: Google Sign-In successful for: ${googleUser.email}');

      // Get device name
      final deviceName = await DeviceHelper.getDeviceName();
      
      // Split user name
      final nameParts = googleUser.displayName?.split(' ') ?? ['', ''];
      final firstName = nameParts.isNotEmpty ? nameParts[0] : '';
      final lastName = nameParts.length > 1 ? nameParts[1] : '';

      // Create social login request
      final socialLoginRequest = SocialLoginRequest(
        deviceToken: deviceName,
        emailId: googleUser.email,
        fname: firstName,
        lname: lastName,
        loginSource: 'GOOGLE',
        userKey: googleUser.id,
      );

      print('🔐 LoginViewModel: Calling social login API');

      // Call social login API
      final result = await socialLoginUseCase(socialLoginRequest);
      
      result.fold(
        (error) {
          print('🔐 LoginViewModel: Social login failed: $error');
          _errorMessage = error;
          _isLoading = false;
          notifyListeners();
          
          // Show error snackbar
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error),
              backgroundColor: Colors.red,
            ),
          );
        },
        (socialLoginResponse) {
          print('🔐 LoginViewModel: Social login successful');
          _isLoading = false;
          notifyListeners();
          
          // Navigate based on user status
          if (socialLoginResponse.data != null) {
            final userData = socialLoginResponse.data!;
            if (userData.ustatus == '0') {
              // User needs to complete profile/terms - go to onboarding
              context.go(AppRoutes.onboarding);
            } else {
              // User is active, go to dashboard
              context.go(AppRoutes.dashboard);
            }
          }
        },
      );
    } catch (e) {
      print('🔐 LoginViewModel: Google Sign-In error: $e');
      _errorMessage = 'Google Sign-In failed: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      
      // Show error snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Google Sign-In failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
