import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingViewModel extends ChangeNotifier {
  int _currentStep = 0;
  bool _agreedToPrivacyPolicy = false;
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  // Getters
  int get currentStep => _currentStep;
  bool get agreedToPrivacyPolicy => _agreedToPrivacyPolicy;
  TextEditingController get firstNameController => _firstNameController;
  TextEditingController get lastNameController => _lastNameController;
  TextEditingController get otpController => _otpController;

  // Computed properties
  bool get canProceedFromStep0 => _agreedToPrivacyPolicy;
  bool get isLastStep => _currentStep == 3;
  String get nextButtonText => isLastStep ? 'Finish' : 'Next';

  OnboardingViewModel() {
    _initializeControllers();
  }

  void _initializeControllers() async {
    // Load existing user data if available
    final prefs = await SharedPreferences.getInstance();
    final existingFirstName = prefs.getString('user_first_name')?.trim() ?? '';
    final existingLastName = prefs.getString('user_last_name')?.trim() ?? '';
    
    _firstNameController.text = existingFirstName;
    _lastNameController.text = existingLastName;
    _otpController.text = '';
    
    print('🔐 OnboardingViewModel: Initialized with existing data - FirstName: "$existingFirstName", LastName: "$existingLastName"');
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

  // Save user profile data
  Future<bool> saveUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Save first name and last name
      await prefs.setString('user_first_name', _firstNameController.text.trim());
      await prefs.setString('user_last_name', _lastNameController.text.trim());
      
      print('🔐 OnboardingViewModel: Saved user profile - FirstName: "${_firstNameController.text.trim()}", LastName: "${_lastNameController.text.trim()}"');
      
      return true;
    } catch (e) {
      print('🔐 OnboardingViewModel: Error saving user profile: $e');
      return false;
    }
  }

  // Get navigation route after saving profile
  Future<String> getNavigationRouteAfterProfileSave() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final devicesCount = prefs.getInt('user_devices_count') ?? 0;
      
      print('🔐 OnboardingViewModel: Checking devices count after profile save: $devicesCount');
      
      if (devicesCount > 0) {
        print('🔐 OnboardingViewModel: User has devices - navigating to dashboard');
        return 'dashboard';
      } else {
        print('🔐 OnboardingViewModel: User has no devices - navigating to onboard device');
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
