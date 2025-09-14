import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/app_router_config.dart';

class SettingsViewModel extends ChangeNotifier {
  // State variables
  bool _isLoading = false;
  String _selectedLanguage = 'English (English)';
  bool _showLanguagePopup = false;

  // Getters
  bool get isLoading => _isLoading;
  String get selectedLanguage => _selectedLanguage;
  bool get showLanguagePopup => _showLanguagePopup;

  // Initialize the settings
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    // Simulate loading time
    await Future.delayed(const Duration(milliseconds: 500));

    _isLoading = false;
    notifyListeners();
  }

  // Handle profile navigation
  void navigateToProfile(BuildContext context) {
    context.go(AppRoutes.profileEdit);
  }

  // Handle about navigation
  void navigateToAbout(BuildContext context) {
    context.go(AppRoutes.about);
  }

  // Handle FAQ navigation
  void navigateToFAQ(BuildContext context) {
    context.go(AppRoutes.faq);
  }

  // Handle privacy navigation
  void navigateToPrivacy(BuildContext context) {
    context.go(AppRoutes.privacy);
  }

  // Handle help navigation
  void navigateToHelp(BuildContext context) {
    context.go(AppRoutes.help);
  }

  // Handle bulk download
  void handleBulkDownload(BuildContext context) {
    context.go(AppRoutes.bulkDownload);
  }

  // Show language popup
  void showLanguageSelection() {
    _showLanguagePopup = true;
    notifyListeners();
  }

  // Hide language popup
  void hideLanguageSelection() {
    _showLanguagePopup = false;
    notifyListeners();
  }

  // Select language
  void selectLanguage(String language) {
    _selectedLanguage = language;
    _showLanguagePopup = false;
    notifyListeners();
  }

  // Handle rate app
  void rateApp() {
    print('Rate App');
  }

  // Handle share app
  void shareApp() {
    print('Share App');
  }

  // Handle logout
  void logout() {
    print('Logout');
  }

  // Close settings
  void closeSettings(BuildContext context) {
    context.go(AppRoutes.profile);
  }
}
