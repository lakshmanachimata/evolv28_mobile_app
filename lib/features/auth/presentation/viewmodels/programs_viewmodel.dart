import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_router_config.dart';
import '../../../../core/services/bluetooth_service.dart';
import 'dashboard_viewmodel.dart';

class ProgramsViewModel extends ChangeNotifier {
  // Static variable to track navigation from dashboard player card
  static String? _programIdFromDashboard;
  
  // Getter for the static variable (for external access)
  static String? get programIdFromDashboard => _programIdFromDashboard;
  
  // Bluetooth service
  final BluetoothService _bluetoothService = BluetoothService();

  String? _selectedProgramId;
  int _selectedTabIndex = 1; // Programs tab is selected by default
  Map<String, bool> _favorites = {};
  
  // Player state
  bool _isPlaying = false;
  String? _currentPlayingProgramId;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = const Duration(minutes: 3);
  
  // Feedback state
  bool _isInFeedbackMode = false;
  FeedbackType? _selectedFeedback;
  bool _showSuccessPopup = false;

  // Programs data - dynamically generated from BLE programs
  List<ProgramData> get programs {
    final bluetoothPrograms = _bluetoothService.programNames;
    final bluetoothIds = _bluetoothService.programIds;
    
    // If no BLE programs available, use default programs
    if (bluetoothPrograms.isEmpty) {
      return _getDefaultPrograms();
    }
    
    // Convert BLE programs to ProgramData
    return bluetoothPrograms.asMap().entries.map((entry) {
      final index = entry.key;
      final programName = entry.value;
      final programId = bluetoothIds.length > index ? bluetoothIds[index] : '';
      
      return ProgramData(
        id: programId,
        title: programName,
        recommendedTime: _getRecommendedTime(programName),
        iconPath: _getIconPath(programName),
        isLocked: false,
        isFavorite: index == 0, // First program is favorite by default
      );
    }).toList();
  }
  
  // Default programs fallback
  List<ProgramData> _getDefaultPrograms() {
    return [
      ProgramData(
        id: 'sleep_better',
        title: 'Sleep Better',
        recommendedTime: '3 hrs',
        iconPath: 'assets/images/sleep_better.svg',
        isLocked: false,
        isFavorite: true,
      ),
      ProgramData(
        id: 'improve_mood',
        title: 'Improve Mood',
        recommendedTime: '2 hrs',
        iconPath: 'assets/images/improve_mood.svg',
        isLocked: false,
        isFavorite: false,
      ),
      ProgramData(
        id: 'focus_better',
        title: 'Focus Better',
        recommendedTime: '1.5 hrs',
        iconPath: 'assets/images/focus_better.svg',
        isLocked: false,
        isFavorite: false,
      ),
      ProgramData(
        id: 'remove_stress',
        title: 'Remove Stress',
        recommendedTime: '2 hrs',
        iconPath: 'assets/images/remove_stress.svg',
        isLocked: false,
        isFavorite: false,
      ),
    ];
  }
  
  // Get recommended time based on program name
  String _getRecommendedTime(String programName) {
    switch (programName) {
      case 'Sleep Better':
        return '3 hrs';
      case 'Improve Mood':
        return '2 hrs';
      case 'Focus Better':
        return '1.5 hrs';
      case 'Remove Stress':
        return '2 hrs';
      case 'Calm Mind':
        return '1 hr';
      default:
        return '2 hrs';
    }
  }
  
  // Get icon path based on program name
  String _getIconPath(String programName) {
    switch (programName) {
      case 'Sleep Better':
        return 'assets/images/sleep_better.svg';
      case 'Improve Mood':
        return 'assets/images/improve_mood.svg';
      case 'Focus Better':
        return 'assets/images/focus_better.svg';
      case 'Remove Stress':
        return 'assets/images/remove_stress.svg';
      case 'Calm Mind':
        return 'assets/images/calm_mind.svg';
      default:
        return 'assets/images/sleep_better.svg';
    }
  }

  String? get selectedProgramId => _selectedProgramId;
  int get selectedTabIndex => _selectedTabIndex;
  Map<String, bool> get favorites => _favorites;
  
  // Player getters
  bool get isPlaying => _isPlaying;
  String? get currentPlayingProgramId => _currentPlayingProgramId;
  Duration get currentPosition => _currentPosition;
  Duration get totalDuration => _totalDuration;
  bool get isInPlayerMode => _currentPlayingProgramId != null;
  
  // Feedback getters
  bool get isInFeedbackMode => _isInFeedbackMode;
  FeedbackType? get selectedFeedback => _selectedFeedback;
  bool get showSuccessPopup => _showSuccessPopup;

  void selectProgram(String programId) {
    _selectedProgramId = programId;
    notifyListeners();
  }

  void toggleFavorite(String programId) {
    _favorites[programId] = !(_favorites[programId] ?? false);
    notifyListeners();
  }

  void playProgram(String programId) {
    _currentPlayingProgramId = programId;
    _isPlaying = true;
    _currentPosition = Duration.zero;
    notifyListeners();
  }

  void togglePlayPause() {
    _isPlaying = !_isPlaying;
    notifyListeners();
  }

  void stopProgram() {
    _currentPlayingProgramId = null;
    _isPlaying = false;
    _currentPosition = Duration.zero;
    notifyListeners();
  }

  void updatePosition(Duration position) {
    _currentPosition = position;
    notifyListeners();
  }

  void finishProgram(BuildContext context) {
    // Show feedback screen
    _isInFeedbackMode = true;
    _isPlaying = false;
    notifyListeners();
  }

  void selectFeedback(FeedbackType feedbackType) {
    _selectedFeedback = feedbackType;
    _showSuccessPopup = true;
    notifyListeners();
  }

  void hideSuccessPopup() {
    _showSuccessPopup = false;
    notifyListeners();
  }

  void onSuccessPopupOk(BuildContext context) {
    // Hide popup and go to programs list
    _showSuccessPopup = false;
    _isInFeedbackMode = false;
    _currentPlayingProgramId = null;
    _isPlaying = false;
    _currentPosition = Duration.zero;
    notifyListeners();
    // Stay on programs screen to show the list
  }

  void repeatProgram(BuildContext context) {
    // Go back to player mode
    _isInFeedbackMode = false;
    _isPlaying = true;
    _currentPosition = Duration.zero;
    notifyListeners();
  }

  void closeFeedback(BuildContext context) {
    // Go to dashboard
    _isInFeedbackMode = false;
    _currentPlayingProgramId = null;
    _isPlaying = false;
    _currentPosition = Duration.zero;
    notifyListeners();
    context.go(AppRoutes.dashboard);
  }

  void minimizeToDashboard(BuildContext context) {
    // Set the minimized state in dashboard viewmodel
    if (_currentPlayingProgramId != null) {
      DashboardViewModel.setMinimizedState(_currentPlayingProgramId!);
    }
    
    // Navigate to dashboard
    context.go(AppRoutes.dashboard);
  }

  // Static methods to manage dashboard navigation
  static void setProgramIdFromDashboard(String programId) {
    _programIdFromDashboard = programId;
  }

  static void clearProgramIdFromDashboard() {
    _programIdFromDashboard = null;
  }

  // Handle navigation from dashboard player card
  void navigateFromDashboardPlayer(String programId) {
    _currentPlayingProgramId = programId;
    _isPlaying = true;
    _currentPosition = Duration.zero;
    notifyListeners();
  }

  void onTabSelected(int index, BuildContext context) {
    _selectedTabIndex = index;
    notifyListeners();

    // Handle navigation based on tab selection
    switch (index) {
      case 0: // Home
        context.go(AppRoutes.dashboard);
        break;
      case 1: // Programs
        // Already on programs screen
        break;
      case 2: // Device
        context.go(AppRoutes.deviceConnected);
        break;
      case 3: // Profile
        context.go(AppRoutes.profile);
        break;
    }
  }

  bool isFavorite(String programId) {
    return _favorites[programId] ?? false;
  }
}

class ProgramData {
  final String id;
  final String title;
  final String recommendedTime;
  final String iconPath;
  final bool isLocked;
  final bool isFavorite;

  ProgramData({
    required this.id,
    required this.title,
    required this.recommendedTime,
    required this.iconPath,
    required this.isLocked,
    required this.isFavorite,
  });
}

enum FeedbackType {
  amazing,
  good,
  okay,
}
