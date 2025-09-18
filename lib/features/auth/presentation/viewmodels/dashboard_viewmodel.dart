import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_router_config.dart';
import '../../../../core/services/bluetooth_service.dart';

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
  
  // Bluetooth service
  final BluetoothService _bluetoothService = BluetoothService();
  late VoidCallback _bluetoothListener;

  // Getters
  bool get isLoading => _isLoading;
  String get userName => _userName;
  int get selectedTabIndex => _selectedTabIndex;
  bool get isPlaying => _isPlaying;
  bool get showPlayerCard => _showPlayerCard;
  String? get currentPlayingProgramId => _currentPlayingProgramId;
  
  // Bluetooth getters
  BluetoothService get bluetoothService => _bluetoothService;
  bool get isBluetoothConnected => _bluetoothService.isConnected;
  String get bluetoothStatusMessage => _bluetoothService.statusMessage;
  String get bluetoothErrorMessage => _bluetoothService.errorMessage;
  int get bluetoothScanCountdown => _bluetoothService.scanCountdown;
  bool get isExecutingCommands => _bluetoothService.isExecutingCommands;
  bool get isSendingPlayCommands => _bluetoothService.isSendingPlayCommands;
  bool get isPlaySuccessful => _bluetoothService.isPlaySuccessful;
  String get selectedBcuFile => _bluetoothService.selectedBcuFile;
  List<String> get playCommandResponses => _bluetoothService.playCommandResponses;
  
  // Bluetooth program getters
  List<String> get bluetoothProgramNames => _bluetoothService.programNames;
  List<String> get bluetoothProgramIds => _bluetoothService.programIds;
  List<String> get bluetoothAvailablePrograms => _bluetoothService.availablePrograms;

  // Static methods to manage minimized state
  static void setMinimizedState(String programId) {
    _isMinimizedFromPlayer = true;
    _minimizedProgramId = programId;
    print('🎵 Dashboard: setMinimizedState called with programId: $programId');
  }

  static void clearMinimizedState() {
    _isMinimizedFromPlayer = false;
    _minimizedProgramId = null;
  }

  // Initialize the dashboard
  Future<void> initialize() async {
    print('🎵 Dashboard: initialize() called');
    _isLoading = true;
    notifyListeners();

    // Initialize Bluetooth service
    print('🎵 Dashboard: Initializing Bluetooth service...');
    await _bluetoothService.initialize();
    print('🎵 Dashboard: Bluetooth service initialized');
    
    // Listen to Bluetooth service changes
    _bluetoothListener = () {
      // Check if command sequence just completed and we haven't checked player status yet
      if (!_bluetoothService.isExecutingCommands && 
          _bluetoothService.isConnected && 
          !_showPlayerCard && 
          !_isMinimizedFromPlayer) {
        print('🎵 Dashboard: Command sequence completed, checking player status...');
        checkPlayerStatus();
      }
      notifyListeners();
    };
    _bluetoothService.addListener(_bluetoothListener);

    // Start scanning automatically if not already connected
    print('🎵 Dashboard: Checking Bluetooth connection status...');
    print('🎵 Dashboard: isConnected: ${_bluetoothService.isConnected}');
    
    if (!_bluetoothService.isConnected) {
      print('🚀 Auto-starting Bluetooth scan on dashboard load...');
      // Small delay to ensure UI is fully loaded
      await Future.delayed(const Duration(milliseconds: 500));
      await _bluetoothService.startScanning();
      print('🎵 Dashboard: Bluetooth scanning completed');
    } else {
      print('🎵 Dashboard: Already connected to Bluetooth device');
    }

    // Check if we're coming from a minimized player
    print('🎵 Dashboard: Checking minimized player state...');
    print('🎵 Dashboard: _isMinimizedFromPlayer: $_isMinimizedFromPlayer, _minimizedProgramId: $_minimizedProgramId');
    
    if (_isMinimizedFromPlayer && _minimizedProgramId != null) {
      print('🎵 Dashboard: Restoring minimized player state');
      _showPlayerCard = true;
      _isPlaying = true;
      _currentPlayingProgramId = _minimizedProgramId;
      // Set the selected BCU file so the player card shows the correct program name
      _bluetoothService.setSelectedBcuFile(_minimizedProgramId!);
      print('🎵 Dashboard: Minimized player restored with programId: $_minimizedProgramId');
      clearMinimizedState(); // Clear the static state
    } else {
      print('🎵 Dashboard: Not coming from minimized player, will check player status');
    }
    
    // Player status check will be handled automatically by the Bluetooth listener
    // when the command sequence completes

    // Simulate loading time
    await Future.delayed(const Duration(milliseconds: 500));

    _isLoading = false;
    print('🎵 Dashboard: initialize() completed');
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

  // Check if a program is currently playing when navigating to dashboard
  Future<void> checkPlayerStatus() async {
    print('🎵 Dashboard: checkPlayerStatus called');
    
    if (!_bluetoothService.isConnected) {
      print('🎵 Dashboard: Bluetooth not connected, skipping player check');
      return;
    }
    
    try {
      final playingFile = await _bluetoothService.checkPlayerCommand();
      
      if (playingFile != null) {
        print('🎵 Dashboard: Program is playing: $playingFile');
        _showPlayerCard = true;
        _isPlaying = true;
        // Set the selected BCU file so the player card shows the correct program name
        _bluetoothService.setSelectedBcuFile(playingFile);
        print('🎵 Dashboard: Player card state set to: showPlayerCard=$_showPlayerCard, isPlaying=$_isPlaying, selectedBcuFile=$playingFile');
        notifyListeners();
      } else {
        print('🎵 Dashboard: No program currently playing');
        _showPlayerCard = false;
        _isPlaying = false;
        print('🎵 Dashboard: Player card state set to: showPlayerCard=$_showPlayerCard, isPlaying=$_isPlaying');
        notifyListeners();
      }
    } catch (e) {
      print('🎵 Dashboard: Error checking player status: $e');
    }
  }

  // Play program from top picks (non-Bluetooth)
  void playProgram(String programTitle) {
    _showPlayerCard = true;
    _isPlaying = true;
    _currentPlayingProgramId = _getProgramIdFromTitle(programTitle);
    notifyListeners();
  }

  // Stop the currently playing program via Bluetooth
  Future<void> stopBluetoothProgram(BuildContext context) async {
    print('🎵 Dashboard: stopBluetoothProgram called');
    
    if (!_bluetoothService.isConnected) {
      print('🎵 Dashboard: Bluetooth not connected, cannot stop program');
      _showStopErrorSnackbar(context, 'Bluetooth not connected');
      return;
    }
    
    try {
      print('🎵 Dashboard: Sending stop command to Bluetooth device...');
      final success = await _bluetoothService.stopProgram();
      
      if (success) {
        print('🎵 Dashboard: Program stopped successfully');
        // Reset player state
        _showPlayerCard = false;
        _isPlaying = false;
        _currentPlayingProgramId = null;
        // Also reset Bluetooth service play success state
        _bluetoothService.setPlaySuccessState(false);
        print('🎵 Dashboard: Player state reset - showPlayerCard: $_showPlayerCard, isPlaySuccessful: ${_bluetoothService.isPlaySuccessful}');
        notifyListeners();
        
        // Force UI refresh on iOS with a small delay
        await Future.delayed(const Duration(milliseconds: 100));
        notifyListeners();
        
        // Show success snackbar
        _showStopSuccessSnackbar(context, 'Player stopped');
      } else {
        print('🎵 Dashboard: Failed to stop program');
        _showStopErrorSnackbar(context, 'Failed to stop program');
      }
    } catch (e) {
      print('🎵 Dashboard: Error stopping program: $e');
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

  // Map program titles to their actual IDs in ProgramsViewModel
  String _getProgramIdFromTitle(String title) {
    switch (title) {
      case 'Better Sleep':
        return 'sleep_better';
      case 'Improve Mood':
        return 'improve_mood';
      case 'Improve Focus':
        return 'focus_better';
      case 'Reduce Stress':
        return 'remove_stress';
      default:
        return 'sleep_better';
    }
  }

  // Handle help and support
  void openHelpSupport() {
    // Implement help and support logic here
    print('Help and support requested');
  }

  // Handle Bluetooth connection
  Future<void> connectBluetoothDevice() async {
    if (_bluetoothService.isConnected) {
      // If already connected, disconnect
      await _bluetoothService.disconnect();
    } else {
      // Start scanning for devices
      await _bluetoothService.startScanning();
    }
    notifyListeners();
  }

  // Disconnect Bluetooth device
  Future<void> disconnectBluetoothDevice() async {
    await _bluetoothService.disconnect();
    notifyListeners();
  }

  // Play Bluetooth program
  Future<void> playBluetoothProgram(String programName) async {
    // Get the file ID for the program name
    final programId = _bluetoothService.getProgramIdByName(programName);
    if (programId != null) {
      print('🎵 Switching to program: $programName (ID: $programId)');
      
      // Don't show player card immediately - wait for success response
      _currentPlayingProgramId = _getProgramIdFromTitle(programName);
      notifyListeners();
      
      await _bluetoothService.playProgram(programId);
    } else {
      print('Program ID not found for: $programName');
    }
  }

  @override
  void dispose() {
    _bluetoothService.removeListener(_bluetoothListener);
    super.dispose();
  }
}
