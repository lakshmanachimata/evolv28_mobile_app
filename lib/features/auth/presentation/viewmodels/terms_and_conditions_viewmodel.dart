import 'package:flutter/foundation.dart';

class TermsAndConditionsViewModel extends ChangeNotifier {
  bool _privacyPolicyAccepted = false;
  bool _termsAndConditionsAccepted = false;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  bool get privacyPolicyAccepted => _privacyPolicyAccepted;
  bool get termsAndConditionsAccepted => _termsAndConditionsAccepted;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  // Check if both terms are accepted
  bool get areTermsAccepted => _privacyPolicyAccepted && _termsAndConditionsAccepted;

  // Initialize the view model
  void initialize() {
    // Reset all values to initial state
    _privacyPolicyAccepted = false;
    _termsAndConditionsAccepted = false;
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }

  // Set privacy policy acceptance
  void setPrivacyPolicyAccepted(bool accepted) {
    _privacyPolicyAccepted = accepted;
    notifyListeners();
  }

  // Set terms and conditions acceptance
  void setTermsAndConditionsAccepted(bool accepted) {
    _termsAndConditionsAccepted = accepted;
    notifyListeners();
  }

  // Set loading state
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Set error message
  void setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Accept all terms
  void acceptAllTerms() {
    _privacyPolicyAccepted = true;
    _termsAndConditionsAccepted = true;
    notifyListeners();
  }

  // Decline all terms
  void declineAllTerms() {
    _privacyPolicyAccepted = false;
    _termsAndConditionsAccepted = false;
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
