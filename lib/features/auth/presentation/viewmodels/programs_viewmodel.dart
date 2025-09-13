import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_router_config.dart';

class ProgramsViewModel extends ChangeNotifier {
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

  // Programs data matching the image flow
  final List<ProgramData> programs = [
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
      title: 'Improve Focus',
      recommendedTime: '1.5 hrs',
      iconPath: 'assets/images/focus_better.svg',
      isLocked: false,
      isFavorite: false,
    ),
    ProgramData(
      id: 'reduce_anxiety',
      title: 'Reduce Anxiety',
      recommendedTime: '2.5 hrs',
      iconPath: 'assets/images/reduced_anxiety.png',
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
    ProgramData(
      id: 'calm_mind',
      title: 'Calm Your Mind',
      recommendedTime: '1 hr',
      iconPath: 'assets/images/calm_mind.svg',
      isLocked: false,
      isFavorite: false,
    ),
  ];

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
    notifyListeners();
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
