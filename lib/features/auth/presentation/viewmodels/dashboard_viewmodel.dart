import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_router_config.dart';

class DashboardViewModel extends ChangeNotifier {
  // State variables
  bool _isLoading = false;
  String _userName = 'Jane Doe'; // Default name, can be passed from previous screen
  int _selectedTabIndex = 0;

  // Getters
  bool get isLoading => _isLoading;
  String get userName => _userName;
  int get selectedTabIndex => _selectedTabIndex;

  // Initialize the dashboard
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
    notifyListeners();
  }

  // Handle tab selection
  void onTabSelected(int index, BuildContext context) {
    _selectedTabIndex = index;
    notifyListeners();

    // Handle navigation based on tab selection
    switch (index) {
      case 0: // Home
        // Already on dashboard screen
        break;
      case 1: // Programs
        context.go(AppRoutes.programs);
        break;
      case 2: // Device
        context.go(AppRoutes.deviceConnected);
        break;
      case 3: // Profile
        context.go(AppRoutes.profile);
        break;
    }
  }

  // Handle logout
  void logout() {
    // Implement logout logic here
    print('Logout requested');
  }

  // Handle profile settings
  void openProfileSettings() {
    // Implement profile settings logic here
    print('Profile settings requested');
  }

  // Handle notifications
  void openNotifications() {
    // Implement notifications logic here
    print('Notifications requested');
  }

  // Handle device management
  void openDeviceManagement() {
    // Implement device management logic here
    print('Device management requested');
  }

  // Handle help and support
  void openHelpSupport() {
    // Implement help and support logic here
    print('Help and support requested');
  }
}
