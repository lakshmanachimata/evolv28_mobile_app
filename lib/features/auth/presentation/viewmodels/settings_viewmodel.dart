import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/routing/app_router_config.dart';
import '../../domain/usecases/delete_user_usecase.dart';

class SettingsViewModel extends ChangeNotifier {
  final DeleteUserUseCase deleteUserUseCase;

  SettingsViewModel({required this.deleteUserUseCase});

  // State variables
  bool _isLoading = false;
  String _selectedLanguage = 'English (English)';
  bool _showLanguagePopup = false;
  bool _showLogoutPopup = false;
  bool _isLoggingOut = false;
  String _userName = 'User';

  // Getters
  bool get isLoading => _isLoading;
  String get selectedLanguage => _selectedLanguage;
  bool get showLanguagePopup => _showLanguagePopup;
  bool get showLogoutPopup => _showLogoutPopup;
  bool get isLoggingOut => _isLoggingOut;
  String get userName => _userName;

  // Initialize the settings
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Load user name from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final firstName = prefs.getString('user_first_name') ?? '';
      final lastName = prefs.getString('user_last_name') ?? '';
      
      if (firstName.isNotEmpty && lastName.isNotEmpty) {
        _userName = '$firstName $lastName';
      } else if (firstName.isNotEmpty) {
        _userName = firstName;
      } else {
        _userName = 'User';
      }
      
    } catch (e) {
      _userName = 'User';
    }

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
      }
    } catch (e) {
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
  Future<void> confirmLogout(BuildContext context) async {
    _isLoggingOut = true;
    _showLogoutPopup = false;
    notifyListeners();

    try {
      
      // Call the delete user API with timeout
      final result = await deleteUserUseCase().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          return const Left('Request timeout, proceeding with local logout');
        },
      );
      
      result.fold(
        (error) {
          // Error occurred - still proceed with logout
          _isLoggingOut = false;
          notifyListeners();
          
          // Show error message but still logout
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Server error: $error. Proceeding with local logout.'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 2),
            ),
          );
          
          // Navigate to login screen after showing message
          Future.delayed(const Duration(milliseconds: 1000), () {
            if (context.mounted) {
              context.go(AppRoutes.login);
            }
          });
        },
        (success) {
          // Success
          _isLoggingOut = false;
          notifyListeners();
          
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account deleted successfully'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
          
          // Navigate to login screen after a short delay
          Future.delayed(const Duration(milliseconds: 500), () {
            if (context.mounted) {
              context.go(AppRoutes.login);
            }
          });
        },
      );
    } catch (e) {
      _isLoggingOut = false;
      notifyListeners();
      
      // Show error message but still logout
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error occurred: ${e.toString()}. Proceeding with local logout.'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 2),
        ),
      );
      
      // Navigate to login screen after showing message
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (context.mounted) {
          context.go(AppRoutes.login);
        }
      });
    }
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
