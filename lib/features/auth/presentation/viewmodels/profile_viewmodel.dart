import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/app_router_config.dart';

class ProfileViewModel extends ChangeNotifier {
  // State variables
  bool _isLoading = false;
  String _userName = 'Jane Doe';
  String _userInitials = 'JD';
  String _dailyGoal = '2 hours (120 mins)';
  bool _googleFitConnected = true;
  bool _appleHealthConnected = true;
  final int _selectedTabIndex = 3; // Profile tab is selected

  // Getters
  bool get isLoading => _isLoading;
  String get userName => _userName;
  String get userInitials => _userInitials;
  String get dailyGoal => _dailyGoal;
  bool get googleFitConnected => _googleFitConnected;
  bool get appleHealthConnected => _appleHealthConnected;
  int get selectedTabIndex => _selectedTabIndex;

  // Initialize the profile
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    // Simulate loading time
    await Future.delayed(const Duration(milliseconds: 500));

    _isLoading = false;
    notifyListeners();
  }

  // Set user name
  void setUserName(String name) {
    _userName = name;
    _userInitials = _generateInitials(name);
    notifyListeners();
  }

  // Generate initials from name
  String _generateInitials(String name) {
    final words = name.split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    } else if (words.isNotEmpty) {
      return words[0][0].toUpperCase();
    }
    return 'U';
  }

  // Update daily goal
  void updateDailyGoal(String goal) {
    _dailyGoal = goal;
    notifyListeners();
  }

  // Toggle Google Fit connection
  void toggleGoogleFit() {
    _googleFitConnected = !_googleFitConnected;
    notifyListeners();
  }

  // Toggle Apple Health connection
  void toggleAppleHealth() {
    _appleHealthConnected = !_appleHealthConnected;
    notifyListeners();
  }

  // Handle edit profile
  void editProfile(BuildContext context) {
    context.go(AppRoutes.profileEdit);
  }

  // Handle badges and leaderboard
  void openBadgesLeaderboard() {
    // Implement badges and leaderboard logic here
    print('Badges and leaderboard requested');
  }

  // Handle add family member
  void addFamilyMember() {
    // Implement add family member logic here
    print('Add family member requested');
  }

  // Handle edit daily goal
  void editDailyGoal() {
    // Implement edit daily goal logic here
    print('Edit daily goal requested');
  }
}
