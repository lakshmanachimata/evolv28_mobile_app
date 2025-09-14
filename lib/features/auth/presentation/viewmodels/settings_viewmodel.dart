import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/routing/app_router_config.dart';

class SettingsViewModel extends ChangeNotifier {
  // State variables
  bool _isLoading = false;
  String _selectedLanguage = 'English (English)';
  bool _showLanguagePopup = false;
  bool _showLogoutPopup = false;

  // Getters
  bool get isLoading => _isLoading;
  String get selectedLanguage => _selectedLanguage;
  bool get showLanguagePopup => _showLanguagePopup;
  bool get showLogoutPopup => _showLogoutPopup;

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
  Future<void> rateApp() async {
    String url;
    
    if (Platform.isAndroid) {
      // Android Play Store
      url = 'https://play.google.com/store/apps/details?id=com.evolv28.app';
    } else if (Platform.isIOS) {
      // iOS App Store
      url = 'https://apps.apple.com/in/app/evolv28/id6464107491';
    } else {
      // Fallback for other platforms
      url = 'https://apps.apple.com/in/app/evolv28/id6464107491';
    }
    
    try {
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        print('Could not launch $url');
      }
    } catch (e) {
      print('Error launching URL: $e');
    }
  }

  // Handle share app
  void shareApp() {
    Share.share(
      'Check out Curie - the amazing wellness app! Download it from the App Store or Google Play Store.',
      subject: 'Curie - Wellness App',
    );
  }

  // Show logout popup
  void showLogoutConfirmation() {
    _showLogoutPopup = true;
    notifyListeners();
  }

  // Hide logout popup
  void hideLogoutConfirmation() {
    _showLogoutPopup = false;
    notifyListeners();
  }

  // Handle logout confirmation
  void confirmLogout(BuildContext context) {
    _showLogoutPopup = false;
    notifyListeners();
    // Navigate to login screen
    context.go(AppRoutes.login);
  }

  // Handle logout (now shows popup)
  void logout() {
    showLogoutConfirmation();
  }

  // Close settings
  void closeSettings(BuildContext context) {
    context.go(AppRoutes.profile);
  }
}
