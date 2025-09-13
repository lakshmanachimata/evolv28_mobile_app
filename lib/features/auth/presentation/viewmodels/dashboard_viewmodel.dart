import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_router_config.dart';

class DashboardViewModel extends ChangeNotifier {
  // Static variables to track minimized state
  static bool _isMinimizedFromPlayer = false;
  static String? _minimizedProgramId;

  // State variables
  bool _isLoading = false;
  String _userName = 'Jane Doe'; // Default name, can be passed from previous screen
  int _selectedTabIndex = 0;
  bool _isPlaying = false; // Track if a program is currently playing
  bool _showPlayerCard = false; // Track if player card should be shown
  String? _currentPlayingProgramId; // Track which program is playing

  // Getters
  bool get isLoading => _isLoading;
  String get userName => _userName;
  int get selectedTabIndex => _selectedTabIndex;
  bool get isPlaying => _isPlaying;
  bool get showPlayerCard => _showPlayerCard;
  String? get currentPlayingProgramId => _currentPlayingProgramId;

  // Static methods to manage minimized state
  static void setMinimizedState(String programId) {
    _isMinimizedFromPlayer = true;
    _minimizedProgramId = programId;
  }

  static void clearMinimizedState() {
    _isMinimizedFromPlayer = false;
    _minimizedProgramId = null;
  }

  // Initialize the dashboard
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    // Check if we're coming from a minimized player
    if (_isMinimizedFromPlayer && _minimizedProgramId != null) {
      _showPlayerCard = true;
      _isPlaying = true;
      _currentPlayingProgramId = _minimizedProgramId;
      clearMinimizedState(); // Clear the static state
    }

    // Simulate loading time
    await Future.delayed(const Duration(milliseconds: 500));

    _isLoading = false;
    notifyListeners();
  }

  // Initialize with minimized player state
  void initializeWithMinimizedPlayer(String programId) {
    _showPlayerCard = true;
    _isPlaying = true;
    _currentPlayingProgramId = programId;
    notifyListeners();
  }

  // Set user name
  void setUserName(String name) {
    _userName = name;
    notifyListeners();
  }

  // Set playing state
  void setPlayingState(bool playing) {
    _isPlaying = playing;
    notifyListeners();
  }

  // Show player card (called when minimizing from programs)
  void showPlayerCardFromMinimize(String programId) {
    _showPlayerCard = true;
    _isPlaying = true;
    _currentPlayingProgramId = programId;
    notifyListeners();
  }

  // Hide player card (called when navigating via bottom menu)
  void hidePlayerCard() {
    _showPlayerCard = false;
    _isPlaying = false;
    _currentPlayingProgramId = null;
    notifyListeners();
  }

  // Handle tab selection
  void onTabSelected(int index, BuildContext context) {
    _selectedTabIndex = index;
    
    // Hide player card when navigating via bottom menu
    hidePlayerCard();

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
