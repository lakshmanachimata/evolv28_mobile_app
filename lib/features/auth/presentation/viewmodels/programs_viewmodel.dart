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

  // Bluetooth listener
  late VoidCallback _bluetoothListener;

  String? _selectedProgramId;
  int _selectedTabIndex = 1; // Programs tab is selected by default
  Map<String, bool> _favorites = {};

  // Player state
  bool _isPlaying = false;
  String? _currentPlayingProgramId;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = const Duration(minutes: 3);

  // Bluetooth play state
  bool _isSendingPlayCommands = false;
  bool _isPlaySuccessful = false;
  String? _selectedBcuFile;

  // Feedback state
  bool _isInFeedbackMode = false;
  FeedbackType? _selectedFeedback;
  bool _showSuccessPopup = false;

  // View state tracking for animations
  String _currentView = 'programs'; // 'programs', 'player', 'feedback'

  // Getter for current view
  String get currentView => _currentView;

  // Programs data - dynamically generated from filtered programs (union of music data and BLE programs)
  List<ProgramData> get programs {
    // Get filtered programs from DashboardViewModel
    final dashboardViewModel = DashboardViewModel();
    final filteredPrograms = dashboardViewModel.filteredPrograms;

    // If no filtered programs available, use default programs
    if (filteredPrograms.isEmpty) {
      return _getDefaultPrograms();
    }

    // Convert filtered programs to ProgramData
    return filteredPrograms
        .map((program) {
          if (program is Map<String, dynamic>) {
            final programName =
                program['bluetoothProgramName'] ??
                program['name'] ??
                program['title'] ??
                'Unknown Program';
            final programId =
                program['bluetoothProgramId'] ??
                program['id']?.toString() ??
                '';

            return ProgramData(
              id: programId,
              title: programName,
              recommendedTime: _getRecommendedTime(programName),
              iconPath: _getIconPath(programName),
              isLocked: false,
              isFavorite:
                  false, // No favorites by default for filtered programs
            );
          }
          return null;
        })
        .where((program) => program != null)
        .cast<ProgramData>()
        .toList();
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
  bool get isInPlayerMode =>
      _currentPlayingProgramId != null || _isPlaySuccessful;

  // Bluetooth play getters
  bool get isSendingPlayCommands => _isSendingPlayCommands;
  bool get isPlaySuccessful => _isPlaySuccessful;
  String? get selectedBcuFile => _selectedBcuFile;

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
    _currentView = 'player'; // Update view state for animation
    print('🎬 View changed to: $_currentView');
    notifyListeners();
  }

  void togglePlayPause() {
    _isPlaying = !_isPlaying;
    notifyListeners();
  }

  // Stop the currently playing program via Bluetooth
  Future<void> stopBluetoothProgram(BuildContext context) async {
    print('🎵 Programs: stopBluetoothProgram called');

    if (!_bluetoothService.isConnected) {
      print('🎵 Programs: Bluetooth not connected, cannot stop program');
      _showStopErrorSnackbar(context, 'Bluetooth not connected');
      return;
    }

    try {
      print('🎵 Programs: Sending stop command to Bluetooth device...');
      final success = await _bluetoothService.stopProgram();

      if (success) {
        print('🎵 Programs: Program stopped successfully');
        // Reset player state
        _isPlaying = false;
        _currentPlayingProgramId = null;
        _currentPosition = Duration.zero;
        _isPlaySuccessful = false;
        _selectedBcuFile = null;
        _currentView = 'programs'; // Update view state for animation
        print('🎬 View changed to: $_currentView');
        notifyListeners();

        // Show success snackbar
        _showStopSuccessSnackbar(context, 'Player stopped');

        // Navigate back to programs list
        await Future.delayed(const Duration(milliseconds: 500));
        // The UI will automatically show the programs list since _isPlaying is now false
      } else {
        print('🎵 Programs: Failed to stop program');
        _showStopErrorSnackbar(context, 'Failed to stop program');
      }
    } catch (e) {
      print('🎵 Programs: Error stopping program: $e');
      _showStopErrorSnackbar(context, 'Error stopping program: $e');
    }
  }

  void _showStopSuccessSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showStopErrorSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
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
    _currentView = 'feedback'; // Update view state for animation
    print('🎬 View changed to: $_currentView');
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
    _currentView = 'programs'; // Update view state for animation
    notifyListeners();
    // Stay on programs screen to show the list
  }

  void repeatProgram(BuildContext context) {
    // Go back to player mode
    _isInFeedbackMode = false;
    _isPlaying = true;
    _currentPosition = Duration.zero;
    _currentView = 'player'; // Update view state for animation
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

  void minimizeToDashboard(BuildContext context) async {
    print('🎵 Programs: minimizeToDashboard called');

    // Set navigation state to preserve connection
    final wasConnected = _bluetoothService.isConnected;
    DashboardViewModel.setNavigationState(wasConnected);

    // Check actual player status from Bluetooth device
    if (_bluetoothService.isConnected) {
      print('🎵 Programs: Checking player status before minimizing...');
      try {
        final playingFile = await _bluetoothService.checkPlayerCommand();
        if (playingFile != null) {
          print(
            '🎵 Programs: Program is playing: $playingFile, setting minimized state',
          );
          // Set the minimized state with the actual playing file
          DashboardViewModel.setMinimizedState(playingFile);
        } else {
          print(
            '🎵 Programs: No program currently playing, clearing minimized state',
          );
          DashboardViewModel.clearMinimizedState();
        }
      } catch (e) {
        print('🎵 Programs: Error checking player status: $e');
        // Fallback to current program ID if available
        if (_currentPlayingProgramId != null) {
          DashboardViewModel.setMinimizedState(_currentPlayingProgramId!);
        }
      }
    } else {
      print('🎵 Programs: Bluetooth not connected, using current program ID');
      // Fallback to current program ID if Bluetooth not connected
      if (_currentPlayingProgramId != null) {
        DashboardViewModel.setMinimizedState(_currentPlayingProgramId!);
      }
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

  // Initialize Bluetooth listener
  Future<void> initialize() async {
    print('🎵 Programs: Initializing Bluetooth service...');

    // Initialize Bluetooth service
    await _bluetoothService.initialize();

    _bluetoothListener = () {
      // Update Bluetooth play state from service
      _isSendingPlayCommands = _bluetoothService.isSendingPlayCommands;
      _isPlaySuccessful = _bluetoothService.isPlaySuccessful;
      _selectedBcuFile = _bluetoothService.selectedBcuFile;
      notifyListeners();
    };

    // Add listener to Bluetooth service
    _bluetoothService.addListener(_bluetoothListener);

    print(
      '🎵 Programs: Bluetooth service initialized. Connected: ${_bluetoothService.isConnected}',
    );
  }

  // Check if a program is currently playing when navigating to programs screen
  Future<void> checkPlayerStatus() async {
    print('🎵 Programs: checkPlayerStatus called');

    if (!_bluetoothService.isConnected) {
      print('🎵 Programs: Bluetooth not connected, skipping player check');
      return;
    }

    try {
      final playingFile = await _bluetoothService.checkPlayerCommand();

      if (playingFile != null) {
        print('🎵 Programs: Program is playing: $playingFile');
        _selectedBcuFile = playingFile;
        _isPlaySuccessful = true;
        _isPlaying = true;
        notifyListeners();
      } else {
        print('🎵 Programs: No program currently playing');
        _isPlaySuccessful = false;
        _isPlaying = false;
        notifyListeners();
      }
    } catch (e) {
      print('🎵 Programs: Error checking player status: $e');
    }
  }

  // Dispose method to remove listener
  @override
  void dispose() {
    _bluetoothService.removeListener(_bluetoothListener);
    super.dispose();
  }

  // Play program with Bluetooth commands
  void playBluetoothProgram(String programId) {
    print('🎵 Programs: playBluetoothProgram called with ID: $programId');

    // Check if Bluetooth is connected
    print('🎵 Programs: Bluetooth connected: ${_bluetoothService.isConnected}');
    if (!_bluetoothService.isConnected) {
      print(
        '🎵 Programs: Bluetooth not connected, falling back to regular play',
      );
      // Fallback to regular play
      playProgram(programId);
      return;
    }

    // Get the program and use its ID directly (it's already the BCU filename)
    print(
      '🎵 Programs: Available programs: ${programs.map((p) => '${p.id}: ${p.title}').join(', ')}',
    );
    final program = programs.firstWhere((p) => p.id == programId);
    final programName = program.title;
    print('🎵 Programs: Found program: $programName');

    // Use the program ID directly as it's already the BCU filename
    final bcuFileId =
        programId; // programId is already the BCU filename like "Alleviate_Stress.bcu"
    print('🎵 Programs: Using BCU file ID: $bcuFileId');

    print('🎵 Programs: Starting play program: $bcuFileId');
    _bluetoothService.playProgram(bcuFileId);
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

enum FeedbackType { amazing, good, okay }
