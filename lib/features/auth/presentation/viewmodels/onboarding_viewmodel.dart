import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/di/injection_container.dart';
import '../../domain/entities/create_profile_request.dart';
import '../../domain/usecases/create_profile_usecase.dart';

class OnboardingViewModel extends ChangeNotifier {
  int _currentStep = 0;
  bool _agreedToPrivacyPolicy = false;
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  String _userEmail = '';
  late CreateProfileUseCase _createProfileUseCase;

  // Getters
  int get currentStep => _currentStep;
  bool get agreedToPrivacyPolicy => _agreedToPrivacyPolicy;
  TextEditingController get firstNameController => _firstNameController;
  TextEditingController get lastNameController => _lastNameController;
  TextEditingController get otpController => _otpController;
  String get userEmail => _userEmail;

  // Computed properties
  bool get canProceedFromStep0 => _agreedToPrivacyPolicy;
  bool get isLastStep => _currentStep == 3;
  String get nextButtonText => isLastStep ? 'Finish' : 'Next';

  OnboardingViewModel() {
    _createProfileUseCase = sl<CreateProfileUseCase>();
    _initializeControllers();
  }

  void _initializeControllers() async {
    // Load existing user data if available
    final prefs = await SharedPreferences.getInstance();
    final existingFirstName = prefs.getString('user_first_name')?.trim() ?? '';
    final existingLastName = prefs.getString('user_last_name')?.trim() ?? '';
    final existingEmail = prefs.getString('user_email_id')?.trim() ?? '';

    _firstNameController.text = existingFirstName;
    _lastNameController.text = existingLastName;
    _userEmail = existingEmail;
    _otpController.text = '';

    print(
      '🔐 OnboardingViewModel: Initialized with existing data - FirstName: "$existingFirstName", LastName: "$existingLastName", Email: "$existingEmail"',
    );
    
    // Debug: Check all stored keys
    final keys = prefs.getKeys();
    print('🔐 OnboardingViewModel: All stored keys: $keys');
    for (final key in keys) {
      final value = prefs.getString(key);
      print('🔐 OnboardingViewModel: Key: "$key" = Value: "$value"');
    }
  }

  // Refresh email data from SharedPreferences
  Future<void> refreshEmailData() async {
    final prefs = await SharedPreferences.getInstance();
    final existingEmail = prefs.getString('user_email_id')?.trim() ?? '';
    _userEmail = existingEmail;
    print('🔐 OnboardingViewModel: Refreshed email data: "$existingEmail"');
    notifyListeners();
  }

  void togglePrivacyPolicyAgreement() {
    _agreedToPrivacyPolicy = !_agreedToPrivacyPolicy;
    notifyListeners();
  }

  void nextStep() {
    if (_currentStep < 3) {
      // Hide keyboard when navigating to next step
      SystemChannels.textInput.invokeMethod('TextInput.hide');
      _currentStep++;
      notifyListeners();
    }
  }

  void previousStep() {
    if (_currentStep > 0) {
      // Hide keyboard when navigating to previous step
      SystemChannels.textInput.invokeMethod('TextInput.hide');
      _currentStep--;
      notifyListeners();
    }
  }

  void goToStep(int step) {
    if (step >= 0 && step <= 3) {
      // Hide keyboard when navigating to any step
      SystemChannels.textInput.invokeMethod('TextInput.hide');
      _currentStep = step;
      notifyListeners();
    }
  }

  bool canProceedFromCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _agreedToPrivacyPolicy;
      case 1:
        return _firstNameController.text.isNotEmpty &&
            _lastNameController.text.isNotEmpty;
      case 2:
        return true; // Connect device step - always proceed
      case 3:
        return _otpController.text.isNotEmpty;
      default:
        return false;
    }
  }

  void handlePrivacyPolicyLinkTap() {
    // TODO: Implement privacy policy link handling
    debugPrint('Privacy policy link tapped');
  }

  void handleResendOtp() {
    // TODO: Implement resend OTP functionality
    debugPrint('Resend OTP tapped');
  }

  void handleBuyNow() {
    // TODO: Implement buy now functionality
    debugPrint('Buy now tapped');
  }

  void handleContactSupport() {
    // TODO: Implement contact support functionality
    debugPrint('Contact support tapped');
  }

  void hideKeyboard() {
    SystemChannels.textInput.invokeMethod('TextInput.hide');
  }

  // Save user profile data using API
  Future<bool> saveUserProfile() async {
    try {
      // Get user email from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final userEmail = prefs.getString('user_email_id') ?? '';

      if (userEmail.isEmpty) {
        print('🔐 OnboardingViewModel: No user email found');
        return false;
      }

      // Create the profile request
      final request = CreateProfileRequest(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        emailId: userEmail,
      );

      print(
        '🔐 OnboardingViewModel: Creating profile with API - FirstName: "${request.firstName}", LastName: "${request.lastName}", Email: "${request.emailId}"',
      );

      // Call the API
      final result = await _createProfileUseCase(request);

        return result.fold(
          (error) {
            print('🔐 OnboardingViewModel: Profile creation failed: $error');
            return false;
          },
          (response) {
            print(
              '🔐 OnboardingViewModel: Profile created successfully: ${response.message}',
            );
            // Return true if error is false or null (success), false otherwise
            return response.error == false;
          },
        );
    } catch (e) {
      print('🔐 OnboardingViewModel: Error creating profile: $e');
      return false;
    }
  }

  // Get navigation route after saving profile
  Future<String> getNavigationRouteAfterProfileSave() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final devicesCount = prefs.getInt('user_devices_count') ?? 0;

      print(
        '🔐 OnboardingViewModel: Checking devices count after profile save: $devicesCount',
      );

      if (devicesCount > 0) {
        print(
          '🔐 OnboardingViewModel: User has devices - navigating to dashboard',
        );
        return 'dashboard';
      } else {
        print(
          '🔐 OnboardingViewModel: User has no devices - navigating to onboard device',
        );
        return 'onboardDevice';
      }
    } catch (e) {
      print('🔐 OnboardingViewModel: Error checking devices count: $e');
      return 'onboardDevice'; // Default to onboard device if there's an error
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _otpController.dispose();
    super.dispose();
  }
}
