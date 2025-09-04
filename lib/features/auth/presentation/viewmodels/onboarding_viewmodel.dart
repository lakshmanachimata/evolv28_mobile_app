import 'package:flutter/material.dart';

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

  void _initializeControllers() {
    _firstNameController.text = 'Jane';
    _lastNameController.text = 'Doe';
    _otpController.text = '9876543210';
  }

  void togglePrivacyPolicyAgreement() {
    _agreedToPrivacyPolicy = !_agreedToPrivacyPolicy;
    notifyListeners();
  }

  void nextStep() {
    if (_currentStep < 3) {
      _currentStep++;
      notifyListeners();
    }
  }

  void previousStep() {
    if (_currentStep > 0) {
      _currentStep--;
      notifyListeners();
    }
  }

  void goToStep(int step) {
    if (step >= 0 && step <= 3) {
      _currentStep = step;
      notifyListeners();
    }
  }

  bool canProceedFromCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _agreedToPrivacyPolicy;
      case 1:
        return _firstNameController.text.isNotEmpty && _lastNameController.text.isNotEmpty;
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

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _otpController.dispose();
    super.dispose();
  }
}
