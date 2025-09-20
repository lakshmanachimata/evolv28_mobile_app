import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as ble;

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
  bool _showLocationPermissionDialog = false;
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
  bool get showLocationPermissionDialog => _showLocationPermissionDialog;
  bool get showLocationPermissionErrorDialog => _showLocationPermissionErrorDialog;
  bool get showBluetoothPermissionErrorDialog => _showBluetoothPermissionErrorDialog;

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

    // Initialize Bluetooth service
    await _bluetoothService.initialize();
    
    // Listen to Bluetooth service changes
    _bluetoothListener = () {
      // Check if command sequence just completed and we haven't checked player status yet
      if (!_bluetoothService.isExecutingCommands && 
          _bluetoothService.isConnected && 
          !_showPlayerCard && 
          !_isMinimizedFromPlayer) {
        checkPlayerStatus();
      }
      notifyListeners();
    };
    _bluetoothService.addListener(_bluetoothListener);

    // Check permissions before starting Bluetooth operations
    await _checkPermissionsAndStartBluetooth();

    // Check if we're coming from a minimized player
    
    if (_isMinimizedFromPlayer && _minimizedProgramId != null) {
      _showPlayerCard = true;
      _isPlaying = true;
      _currentPlayingProgramId = _minimizedProgramId;
      // Set the selected BCU file so the player card shows the correct program name
      _bluetoothService.setSelectedBcuFile(_minimizedProgramId!);
      clearMinimizedState(); // Clear the static state
    } else {
    }
    
    // Player status check will be handled automatically by the Bluetooth listener
    // when the command sequence completes

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
  }

  // Handle profile settings
  void openProfileSettings() {
    // Implement profile settings logic here
  }

  // Handle notifications
  void openNotifications() {
    // Implement notifications logic here
  }

  // Handle device management
  void openDeviceManagement() {
    // Implement device management logic here
  }

  // Check if a program is currently playing when navigating to dashboard
  Future<void> checkPlayerStatus() async {
    
    if (!_bluetoothService.isConnected) {
      return;
    }
    
    try {
      final playingFile = await _bluetoothService.checkPlayerCommand();
      
      if (playingFile != null) {
        _showPlayerCard = true;
        _isPlaying = true;
        // Set the selected BCU file so the player card shows the correct program name
        _bluetoothService.setSelectedBcuFile(playingFile);
        notifyListeners();
      } else {
        _showPlayerCard = false;
        _isPlaying = false;
        notifyListeners();
      }
    } catch (e) {
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
    
    if (!_bluetoothService.isConnected) {
      _showStopErrorSnackbar(context, 'Bluetooth not connected');
      return;
    }
    
    try {
      final success = await _bluetoothService.stopProgram();
      
      if (success) {
        // Reset player state
        _showPlayerCard = false;
        _isPlaying = false;
        _currentPlayingProgramId = null;
        // Also reset Bluetooth service play success state
        _bluetoothService.setPlaySuccessState(false);
        notifyListeners();
        
        // Force UI refresh on iOS with a small delay
        await Future.delayed(const Duration(milliseconds: 100));
        notifyListeners();
        
        // Show success snackbar
        _showStopSuccessSnackbar(context, 'Player stopped');
      } else {
        _showStopErrorSnackbar(context, 'Failed to stop program');
      }
    } catch (e) {
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
      
      // Don't show player card immediately - wait for success response
      _currentPlayingProgramId = _getProgramIdFromTitle(programName);
      notifyListeners();
      
      await _bluetoothService.playProgram(programId);
    } else {
    }
  }

  // Permission checking methods
  Future<void> _checkPermissionsAndStartBluetooth() async {
    
    // Prevent multiple permission flow calls
    if (_permissionFlowInitiated) {
      return;
    }

    // Check Bluetooth status first
    await _checkBluetoothStatus();
    
    // Only show Bluetooth enable dialog if we've checked the status and confirmed it's disabled
    if (!_isBluetoothEnabled &&
        !_bluetoothDialogShown &&
        _bluetoothStatusChecked) {
      _showBluetoothEnableDialog = true;
      _bluetoothDialogShown = true; // Prevent multiple dialogs
      _permissionFlowInitiated = true; // Mark permission flow as initiated
    } else if (_isBluetoothEnabled && _bluetoothStatusChecked) {
      _permissionFlowInitiated = true; // Mark permission flow as initiated

      // Check if location permission is already granted first
      bool hasLocationPermission = await _checkLocationPermission();
      if (!hasLocationPermission && !_locationPermissionDialogShown) {
        _locationPermissionDialogShown = true; // Prevent multiple requests
        _showLocationPermissionDialog = true; // Show custom dialog first
      } else if (hasLocationPermission) {
        // Location permission granted, check BLE scan permission
        bool hasBluetoothPermission = await _checkBluetoothScanPermission();

        if (hasBluetoothPermission) {
          _isBluetoothScanPermissionGranted = true;
          await _startBluetoothOperations();
        } else if (!_bluetoothScanPermissionDialogShown) {
          _bluetoothScanPermissionDialogShown = true; // Prevent multiple requests
          _showBluetoothScanPermissionDialog = true; // Show custom dialog first
        }
      }
    } else if (!_bluetoothStatusChecked) {
      // Don't recursively call - let the status check complete
    } else {
    }
    notifyListeners();
  }

  Future<void> _checkBluetoothStatus() async {
    try {
      final adapterState = await ble.FlutterBluePlus.adapterState.first;
      _isBluetoothEnabled = adapterState == ble.BluetoothAdapterState.on;
      _bluetoothStatusChecked = true;
      
      // Log Bluetooth status check
      await _loggingService.logBluetoothOperation(
        operation: 'status_check',
        success: true,
        deviceName: 'Bluetooth ${_isBluetoothEnabled ? 'enabled' : 'disabled'}',
      );
    } catch (e) {
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
      
      // Log location permission status in background
      await _loggingService.sendLogs(
        event: 'Location Permission',
        status: isGranted ? 'success' : 'failed',
        notes: isGranted ? 'success' : permission.name,
      );
      
      return isGranted;
    } catch (e) {
      
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
    
    // Initialize Bluetooth service with permissions
    await _bluetoothService.initializeAfterPermissions();
    
    
    if (!_bluetoothService.isConnected) {
      // Small delay to ensure UI is fully loaded
      await Future.delayed(const Duration(milliseconds: 500));
      await _bluetoothService.startScanning();
    } else {
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
    _showLocationPermissionDialog = false;
    
    try {
      LocationPermission permission = await Geolocator.requestPermission();
      
      if (permission == LocationPermission.whileInUse || 
          permission == LocationPermission.always) {
        _isLocationPermissionGranted = true;
        
        // Log successful location permission
        await _loggingService.sendLogs(
          event: 'Location Permission',
          status: 'success',
          notes: 'success',
        );
        
        // Continue with Bluetooth scan permission check
        bool hasBluetoothPermission = await _checkBluetoothScanPermission();

        if (hasBluetoothPermission) {
          _isBluetoothScanPermissionGranted = true;
          await _startBluetoothOperations();
        } else if (!_bluetoothScanPermissionDialogShown) {
          _bluetoothScanPermissionDialogShown = true;
          _showBluetoothScanPermissionDialog = true;
        }
      } else {
        // Location permission denied
        
        // Log denied location permission
        await _loggingService.sendLogs(
          event: 'Location Permission',
          status: 'failed',
          notes: permission.name,
        );
        
        if (permission == LocationPermission.deniedForever) {
          _showLocationPermissionErrorDialog = true;
        }
      }
    } catch (e) {
      
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
    
    try {
      if (Platform.isAndroid) {
        var status = await Permission.bluetoothScan.request();
        
        // Log BLE permission result in background
        await _loggingService.sendLogs(
          event: 'BLE Permission',
          status: status == PermissionStatus.granted ? 'success' : 'failed',
          notes: status == PermissionStatus.granted ? 'success' : status.name,
        );
        
        if (status == PermissionStatus.granted) {
          _isBluetoothScanPermissionGranted = true;
          await _startBluetoothOperations();
        } else if (status == PermissionStatus.permanentlyDenied) {
          _showBluetoothPermissionErrorDialog = true;
        }
      }
    } catch (e) {
      
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
    } catch (e) {
    }
  }

  @override
  void dispose() {
    _bluetoothService.removeListener(_bluetoothListener);
    super.dispose();
  }
}
