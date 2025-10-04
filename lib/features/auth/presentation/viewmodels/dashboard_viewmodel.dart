import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as ble;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/routing/app_router_config.dart';
import '../../../../core/services/bluetooth_service.dart';
import '../../../../core/services/logging_service.dart';
import '../../../../core/di/injection_container.dart';

class DashboardViewModel extends ChangeNotifier {
  // Static variables to track minimized state
  static bool _isMinimizedFromPlayer = false;
  static String? _minimizedProgramId;

  // Services
  final BluetoothService _bluetoothService = BluetoothService();
  final LoggingService _loggingService = sl<LoggingService>();

  // State variables
  bool _isLoading = false;
  String _userName = 'Jane Doe'; // Default name, can be passed from previous screen
  int _selectedTabIndex = 0;
  bool _isPlaying = false; // Track if a program is currently playing
  bool _showPlayerCard = false; // Track if player card should be shown
  String? _currentPlayingProgramId; // Track which program is playing
  late VoidCallback _bluetoothListener;

  // Permission state variables
  bool _isBluetoothEnabled = false;
  bool _isBluetoothScanPermissionGranted = false;
  bool _isLocationPermissionGranted = false;
  
  // Permission dialog state
  bool _showBluetoothEnableDialog = false;
  bool _showBluetoothScanPermissionDialog = false;
  bool _showLocationPermissionErrorDialog = false;
  bool _showBluetoothPermissionErrorDialog = false;
  
  // Permission dialog flags to prevent multiple dialogs
  bool _bluetoothDialogShown = false;
  bool _bluetoothScanPermissionDialogShown = false;
  bool _locationPermissionDialogShown = false;
  bool _permissionFlowInitiated = false;
  bool _bluetoothPermissionPermanentlyDenied = false;
  bool _bluetoothStatusChecked = false;

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
  bool get isBluetoothScanning => _bluetoothService.isScanning;
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

  // Permission getters
  bool get isBluetoothEnabled => _isBluetoothEnabled;
  bool get isBluetoothScanPermissionGranted => _isBluetoothScanPermissionGranted;
  bool get isLocationPermissionGranted => _isLocationPermissionGranted;
  
  // Permission dialog getters
  bool get showBluetoothEnableDialog => _showBluetoothEnableDialog;
  bool get showBluetoothScanPermissionDialog => _showBluetoothScanPermissionDialog;
  bool get showLocationPermissionErrorDialog => _showLocationPermissionErrorDialog;
  bool get showBluetoothPermissionErrorDialog => _showBluetoothPermissionErrorDialog;

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

    // Load user data from SharedPreferences
    await _loadUserData();

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

    // Check permissions before starting Bluetooth operations
    print('🎵 Dashboard: Checking permissions before Bluetooth operations...');
    await _checkPermissionsAndStartBluetooth();

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

  // Load user data from SharedPreferences
  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get user data
      final firstName = prefs.getString('user_first_name')?.trim() ?? '';
      final lastName = prefs.getString('user_last_name')?.trim() ?? '';
      final userName = prefs.getString('user_name')?.trim() ?? '';
      
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
      
      print('🎵 Dashboard: Loaded user data - Name: "$_userName"');
      
    } catch (e) {
      print('🎵 Dashboard: Error loading user data: $e');
      // Keep default values if loading fails
    }
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

  // Permission checking methods
  Future<void> _checkPermissionsAndStartBluetooth() async {
    print('🎵 Dashboard: Starting permission check flow...');
    print('🎵 Dashboard: isBluetoothEnabled=$_isBluetoothEnabled, dialogShown=$_bluetoothDialogShown, scanPermissionGranted=$_isBluetoothScanPermissionGranted, statusChecked=$_bluetoothStatusChecked, permissionFlowInitiated=$_permissionFlowInitiated');
    
    // Prevent multiple permission flow calls
    if (_permissionFlowInitiated) {
      print('🎵 Dashboard: Permission flow already initiated, skipping');
      return;
    }

    // Check Bluetooth status first
    await _checkBluetoothStatus();
    
    // Only show Bluetooth enable dialog if we've checked the status and confirmed it's disabled
    if (!_isBluetoothEnabled &&
        !_bluetoothDialogShown &&
        _bluetoothStatusChecked) {
      print('🎵 Dashboard: Showing Bluetooth enable dialog');
      _showBluetoothEnableDialog = true;
      _bluetoothDialogShown = true; // Prevent multiple dialogs
      _permissionFlowInitiated = true; // Mark permission flow as initiated
    } else if (_isBluetoothEnabled && _bluetoothStatusChecked) {
      _permissionFlowInitiated = true; // Mark permission flow as initiated

      // Check if location permission is already granted first
      bool hasLocationPermission = await _checkLocationPermission();
      print('🎵 Dashboard: Location permission check result: $hasLocationPermission, dialogShown: $_locationPermissionDialogShown');
      if (!hasLocationPermission && !_locationPermissionDialogShown) {
        print('🎵 Dashboard: Showing location permission dialog first');
        _locationPermissionDialogShown = true; // Prevent multiple requests
      } else if (hasLocationPermission) {
        // Location permission granted, check BLE scan permission
        bool hasBluetoothPermission = await _checkBluetoothScanPermission();
        print('🎵 Dashboard: Bluetooth permission check result: $hasBluetoothPermission, dialogShown: $_bluetoothScanPermissionDialogShown');

        if (hasBluetoothPermission) {
          print('🎵 Dashboard: All permissions already granted, starting Bluetooth operations directly');
          _isBluetoothScanPermissionGranted = true;
          await _startBluetoothOperations();
        } else if (!_bluetoothScanPermissionDialogShown) {
          print('🎵 Dashboard: Location permission granted, showing Bluetooth permission dialog');
          _bluetoothScanPermissionDialogShown = true; // Prevent multiple requests
          _showBluetoothScanPermissionDialog = true; // Show custom dialog first
        }
      }
    } else if (!_bluetoothStatusChecked) {
      print('🎵 Dashboard: Bluetooth status not yet checked, waiting for status check to complete...');
      // Don't recursively call - let the status check complete
    } else {
      print('🎵 Dashboard: No action taken - conditions not met');
    }
    notifyListeners();
  }

  Future<void> _checkBluetoothStatus() async {
    try {
      final adapterState = await ble.FlutterBluePlus.adapterState.first;
      _isBluetoothEnabled = adapterState == ble.BluetoothAdapterState.on;
      _bluetoothStatusChecked = true;
      print('🎵 Dashboard: Bluetooth enabled: $_isBluetoothEnabled, status checked: $_bluetoothStatusChecked');
      
      // Log Bluetooth status check
      await _loggingService.logBluetoothOperation(
        operation: 'status_check',
        success: true,
        deviceName: 'Bluetooth ${_isBluetoothEnabled ? 'enabled' : 'disabled'}',
      );
    } catch (e) {
      print('🎵 Dashboard: Error checking Bluetooth status: $e');
      _isBluetoothEnabled = false;
      _bluetoothStatusChecked = true;
      
      // Log Bluetooth status check error
      await _loggingService.logBluetoothOperation(
        operation: 'status_check',
        success: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<bool> _checkLocationPermission() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      bool isGranted = permission == LocationPermission.whileInUse || 
                      permission == LocationPermission.always;
      _isLocationPermissionGranted = isGranted;
      print('🎵 Dashboard: Location permission granted: $isGranted');
      
      // Log location permission status in background
      await _loggingService.sendLogs(
        event: 'Location Permission',
        status: isGranted ? 'success' : 'failed',
        notes: isGranted ? 'success' : permission.name,
      );
      
      return isGranted;
    } catch (e) {
      print('🎵 Dashboard: Error checking location permission: $e');
      
      // Log location permission error
      await _loggingService.sendLogs(
        event: 'Location Permission',
        status: 'failed',
        notes: e.toString(),
      );
      
      return false;
    }
  }

  Future<bool> _checkBluetoothScanPermission() async {
    try {
      if (Platform.isAndroid) {
        // For Android 12+, check BLUETOOTH_SCAN permission
        var status = await Permission.bluetoothScan.status;
        bool isGranted = status == PermissionStatus.granted;
        _isBluetoothScanPermissionGranted = isGranted;
        print('🎵 Dashboard: Bluetooth scan permission granted: $isGranted');
        
        // Log BLE permission status in background
        await _loggingService.sendLogs(
          event: 'BLE Permission',
          status: isGranted ? 'success' : 'failed',
          notes: isGranted ? 'success' : status.name,
        );
        
        return isGranted;
      } else {
        // For iOS, assume granted if we reach here
        _isBluetoothScanPermissionGranted = true;
        
        // Log BLE permission status for iOS
        await _loggingService.sendLogs(
          event: 'BLE Permission',
          status: 'success',
          notes: 'iOS - assumed granted',
        );
        
        return true;
      }
    } catch (e) {
      print('🎵 Dashboard: Error checking Bluetooth scan permission: $e');
      
      // Log BLE permission error
      await _loggingService.sendLogs(
        event: 'BLE Permission',
        status: 'failed',
        notes: e.toString(),
      );
      
      return false;
    }
  }

  Future<void> _startBluetoothOperations() async {
    print('🎵 Dashboard: Starting Bluetooth operations after permissions granted...');
    
    // Initialize Bluetooth service with permissions
    await _bluetoothService.initializeAfterPermissions();
    
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
  }

  // Permission dialog handlers
  Future<void> handleBluetoothEnableOk() async {
    _showBluetoothEnableDialog = false;
    notifyListeners();
    
    // Recheck Bluetooth status
    await _checkBluetoothStatus();
    if (_isBluetoothEnabled) {
      // Reset permission flow flags to allow restart
      _permissionFlowInitiated = false;
      await _checkPermissionsAndStartBluetooth();
    }
  }

  Future<void> allowLocationPermission() async {
    print('🎵 Dashboard: User allowed location permission, requesting system permission');
    
    try {
      LocationPermission permission = await Geolocator.requestPermission();
      print('🎵 Dashboard: Location permission request result: $permission');
      
      if (permission == LocationPermission.whileInUse || 
          permission == LocationPermission.always) {
        print('🎵 Dashboard: Location permission granted');
        _isLocationPermissionGranted = true;
        
        // Log successful location permission
        await _loggingService.sendLogs(
          event: 'Location Permission',
          status: 'success',
          notes: 'success',
        );
        
        // Continue with Bluetooth scan permission check
        bool hasBluetoothPermission = await _checkBluetoothScanPermission();
        print('🎵 Dashboard: Bluetooth permission check result: $hasBluetoothPermission, dialogShown: $_bluetoothScanPermissionDialogShown');

        if (hasBluetoothPermission) {
          print('🎵 Dashboard: All permissions granted, starting Bluetooth operations');
          _isBluetoothScanPermissionGranted = true;
          await _startBluetoothOperations();
        } else if (!_bluetoothScanPermissionDialogShown) {
          print('🎵 Dashboard: Location permission granted, showing Bluetooth permission dialog');
          _bluetoothScanPermissionDialogShown = true;
          _showBluetoothScanPermissionDialog = true;
        }
      } else {
        // Location permission denied
        print('🎵 Dashboard: Location permission denied: ${permission.name}');
        
        // Log denied location permission
        await _loggingService.sendLogs(
          event: 'Location Permission',
          status: 'failed',
          notes: permission.name,
        );
        
        if (permission == LocationPermission.deniedForever) {
          print('🎵 Dashboard: Location permission permanently denied');
          _showLocationPermissionErrorDialog = true;
        }
      }
    } catch (e) {
      print('🎵 Dashboard: Error requesting location permission: $e');
      
      // Log location permission error
      await _loggingService.sendLogs(
        event: 'Location Permission',
        status: 'failed',
        notes: e.toString(),
      );
    }
    notifyListeners();
  }

  Future<void> allowBluetoothScanPermission() async {
    _showBluetoothScanPermissionDialog = false;
    print('🎵 Dashboard: User allowed Bluetooth scan permission, requesting system permission');
    
    try {
      if (Platform.isAndroid) {
        var status = await Permission.bluetoothScan.request();
        print('🎵 Dashboard: Bluetooth scan permission request result: $status');
        
        // Log BLE permission result in background
        await _loggingService.sendLogs(
          event: 'BLE Permission',
          status: status == PermissionStatus.granted ? 'success' : 'failed',
          notes: status == PermissionStatus.granted ? 'success' : status.name,
        );
        
        if (status == PermissionStatus.granted) {
          print('🎵 Dashboard: Bluetooth scan permission granted');
          _isBluetoothScanPermissionGranted = true;
          await _startBluetoothOperations();
        } else if (status == PermissionStatus.permanentlyDenied) {
          print('🎵 Dashboard: Bluetooth scan permission permanently denied');
          _showBluetoothPermissionErrorDialog = true;
        }
      }
    } catch (e) {
      print('🎵 Dashboard: Error requesting Bluetooth scan permission: $e');
      
      // Log BLE permission error
      await _loggingService.sendLogs(
        event: 'BLE Permission',
        status: 'failed',
        notes: e.toString(),
      );
    }
    notifyListeners();
  }

  void handleLocationPermissionErrorOk() {
    _showLocationPermissionErrorDialog = false;
    notifyListeners();
  }

  void handleBluetoothPermissionErrorOk() {
    _showBluetoothPermissionErrorDialog = false;
    notifyListeners();
  }

  Future<void> openDeviceSettings() async {
    try {
      await openAppSettings();
      print('🎵 Dashboard: Opened app settings');
    } catch (e) {
      print('🎵 Dashboard: Error opening app settings: $e');
    }
  }

  @override
  void dispose() {
    _bluetoothService.removeListener(_bluetoothListener);
    super.dispose();
  }
}
