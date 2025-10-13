import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/routing/app_router_config.dart';
import '../../../../core/services/bluetooth_service.dart';

class ProfileViewModel extends ChangeNotifier {
  // Bluetooth service
  final BluetoothService _bluetoothService = BluetoothService();
  
  // Bluetooth listener
  late VoidCallback _bluetoothListener;

  // State variables
  bool _isLoading = false;
  String _userName = 'Jane Doe';
  String _userInitials = 'JD';
  String _dailyGoal = '2 hours (120 mins)';
  bool _googleFitConnected = true;
  bool _appleHealthConnected = true;
  final int _selectedTabIndex = 3; // Profile tab is selected

  // Device disconnection state
  bool _showDeviceDisconnectedPopup = false;
  String _disconnectedDeviceName = '';

  // Getters
  bool get isLoading => _isLoading;
  String get userName => _userName;
  String get userInitials => _userInitials;
  String get dailyGoal => _dailyGoal;
  bool get googleFitConnected => _googleFitConnected;
  bool get appleHealthConnected => _appleHealthConnected;
  int get selectedTabIndex => _selectedTabIndex;

  // Device disconnection getters
  bool get showDeviceDisconnectedPopup => _showDeviceDisconnectedPopup;
  String get disconnectedDeviceName => _disconnectedDeviceName;

  // Initialize the profile
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Initialize Bluetooth service
      await _bluetoothService.initialize();

      // Set up Bluetooth listener
      _bluetoothListener = () {
        notifyListeners();
      };
      _bluetoothService.addListener(_bluetoothListener);

      // Set up device disconnection callback
      _bluetoothService.setOnDeviceDisconnectedCallback((deviceName) {
        print('🎵 Profile: Device disconnected: $deviceName');
        _handleDeviceDisconnection(deviceName);
      });

      // Load user data from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      
      // Get user data
      final firstName = prefs.getString('user_first_name')?.trim() ?? '';
      final lastName = prefs.getString('user_last_name')?.trim() ?? '';
      final userName = prefs.getString('user_name')?.trim() ?? '';
      final emailId = prefs.getString('user_email_id')?.trim() ?? '';
      final gender = prefs.getString('user_gender')?.trim() ?? '';
      final country = prefs.getString('user_country')?.trim() ?? '';
      final age = prefs.getString('user_age')?.trim() ?? '';
      
      // Set user name - use userName if available, otherwise combine first and last name
      if (userName.isNotEmpty) {
        _userName = userName;
      } else if (firstName.isNotEmpty && lastName.isNotEmpty) {
        _userName = '$firstName $lastName';
      } else if (firstName.isNotEmpty) {
        _userName = firstName;
      } else if (lastName.isNotEmpty) {
        _userName = lastName;
      } else {
        _userName = 'User'; // Default fallback
      }
      
      // Generate initials
      _userInitials = _generateInitials(_userName);
      
      print('🔐 ProfileViewModel: Loaded user data - Name: "$_userName", Email: "$emailId", Gender: "$gender", Country: "$country", Age: "$age"');
      
    } catch (e) {
      print('🔐 ProfileViewModel: Error loading user data: $e');
      // Keep default values if loading fails
    }

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

  // Handle device disconnection
  void _handleDeviceDisconnection(String deviceName) {
    print('🎵 Profile: Handling device disconnection for: $deviceName');
    
    // Show disconnection popup
    _showDeviceDisconnectedPopup = true;
    _disconnectedDeviceName = deviceName;
    notifyListeners();
  }

  void closeDeviceDisconnectedPopup() {
    _showDeviceDisconnectedPopup = false;
    _disconnectedDeviceName = '';
    notifyListeners();
  }

  @override
  void dispose() {
    _bluetoothService.removeListener(_bluetoothListener);
    super.dispose();
  }
}
