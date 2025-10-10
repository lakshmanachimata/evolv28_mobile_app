import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as ble;
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/routing/app_router_config.dart';
import '../../../../core/services/bluetooth_service.dart';
import '../../../../core/services/logging_service.dart';
import '../../../../core/utils/bluetooth_permission_helper.dart';
import '../../../../core/utils/location_permission_helper.dart';
import '../../domain/entities/device_mapping_request.dart';
import '../../domain/usecases/get_all_music_usecase.dart';
import '../../domain/usecases/map_device_without_otp_usecase.dart';
import '../../domain/usecases/verify_otp_usecase.dart';

class DashboardViewModel extends ChangeNotifier {
  // Static reference to the current instance
  static DashboardViewModel? _instance;
  
  // Static getter for the current instance
  static DashboardViewModel? get instance => _instance;
  
  // Static variables to track minimized state
  static bool _isMinimizedFromPlayer = false;
  static String? _minimizedProgramId;

  // Static variables to track navigation state
  static bool _isReturningFromOtherScreen = false;
  static bool _wasConnectedBeforeNavigation = false;

  // Services
  final BluetoothService _bluetoothService = BluetoothService();
  final LoggingService _loggingService = sl<LoggingService>();
  final VerifyOtpUseCase _verifyOtpUseCase = sl<VerifyOtpUseCase>();
  final GetAllMusicUseCase _getAllMusicUseCase = sl<GetAllMusicUseCase>();
  final MapDeviceWithoutOtpUseCase _mapDeviceWithoutOtpUseCase =
      sl<MapDeviceWithoutOtpUseCase>();

  // Constructor
  DashboardViewModel() {
    _instance = this;
  }

  // State variables
  bool _isLoading = false;
  String _userName =
      'Jane Doe'; // Default name, can be passed from previous screen
  bool _shouldAutoConnect =
      false; // Flag to determine if auto-connection should be attempted
  List<dynamic> _userDevices = []; // User's devices from server data
  int _selectedTabIndex = 0;
  bool _isPlaying = false; // Track if a program is currently playing
  bool _showPlayerCard = false; // Track if player card should be shown
  String? _currentPlayingProgramId; // Track which program is playing
  VoidCallback? _bluetoothListener;

  // Music data
  List<dynamic> _musicData = []; // User's music data from server
  bool _isLoadingMusic = false; // Track if music data is being loaded
  String _deviceName = ''; // Device name from getAllMusic API

  // Bluetooth state monitoring
  bool _isBluetoothStateMonitoring = false;
  StreamSubscription<ble.BluetoothAdapterState>? _bluetoothStateSubscription;

  // Permission flow trigger
  bool _shouldTriggerPermissionFlow = false;
  bool _permissionFlowInProgress = false;

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
  bool _showDeviceSelectionDialog = false;

  // Permission dialog flags to prevent multiple dialogs
  bool _bluetoothDialogShown = false;
  bool _bluetoothScanPermissionDialogShown = false;
  bool _locationPermissionDialogShown = false;
  bool _permissionFlowInitiated = false;
  
  // Additional state management for permission flow
  bool _permissionFlowCompleted = false;
  DateTime? _lastPermissionFlowTime;
  static const Duration _permissionFlowCooldown = Duration(seconds: 5);

  // Device selection state
  String _selectedDeviceId = '';
  List<Map<String, dynamic>> _scannedDevices = [];
  bool _bluetoothPermissionPermanentlyDenied = false;
  bool _bluetoothStatusChecked = false;

  // Unknown device details state
  bool _showUnknownDeviceDialog = false;
  List<Map<String, dynamic>> _unknownDevices = [];
  Map<String, dynamic>? _selectedUnknownDevice;
  bool _showOtpConfirmationDialog = false;
  String _otpCode = '';

  // Device selection state for new UI
  Set<String> _selectedDeviceIds = {}; // Track multiple selected devices
  bool _isConnecting = false; // Track connection state
  bool _connectionSuccessful = false; // Track successful connection
  bool _showTroubleshootingScreen = false; // Track troubleshooting screen state

  // Device mapping error state
  bool _showDeviceMappingErrorDialog = false;
  String _deviceMappingError = '';
  String? _pendingDeviceMappingError; // Store error to be handled by UI

  // Debounce mechanism to prevent bottom sheet from reopening immediately
  DateTime? _lastBottomSheetCloseTime;
  static const Duration _bottomSheetDebounceDuration = Duration(seconds: 2);

  // Getters
  bool get isLoading => _isLoading;
  String get userName => _userName;
  int get selectedTabIndex => _selectedTabIndex;
  bool get isPlaying => _isPlaying;
  bool get showPlayerCard => _showPlayerCard;
  String? get currentPlayingProgramId => _currentPlayingProgramId;
  String get deviceName => _deviceName;

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
  List<String> get playCommandResponses =>
      _bluetoothService.playCommandResponses;

  // Bluetooth program getters
  List<String> get bluetoothProgramNames => _bluetoothService.programNames;
  List<String> get bluetoothProgramIds => _bluetoothService.programIds;
  List<String> get bluetoothAvailablePrograms =>
      _bluetoothService.availablePrograms;

  // Music data getters
  List<dynamic> get musicData => _musicData;
  bool get isLoadingMusic => _isLoadingMusic;

  // Filtered programs (union of music data and Bluetooth programs)
  List<dynamic> get filteredPrograms => _getFilteredPrograms();
  set filteredPrograms(List<dynamic> value) {
    // This setter is for compatibility, but the getter will always return the computed value
    // The actual filtered programs are computed dynamically
  }

  // Permission flow trigger getter
  bool get shouldTriggerPermissionFlow => _shouldTriggerPermissionFlow;
  bool get permissionFlowInProgress => _permissionFlowInProgress;
  bool get permissionFlowCompleted => _permissionFlowCompleted;

  // Permission getters
  bool get isBluetoothEnabled => _isBluetoothEnabled;
  bool get isBluetoothScanPermissionGranted =>
      _isBluetoothScanPermissionGranted;
  bool get isLocationPermissionGranted => _isLocationPermissionGranted;

  // Permission dialog getters
  bool get showBluetoothEnableDialog => _showBluetoothEnableDialog;
  bool get showBluetoothScanPermissionDialog =>
      _showBluetoothScanPermissionDialog;
  bool get showLocationPermissionDialog => _showLocationPermissionDialog;
  bool get showLocationPermissionErrorDialog =>
      _showLocationPermissionErrorDialog;
  bool get showBluetoothPermissionErrorDialog =>
      _showBluetoothPermissionErrorDialog;
  bool get showDeviceSelectionDialog => _showDeviceSelectionDialog;

  // Device selection getters
  String get selectedDeviceId => _selectedDeviceId;
  List<Map<String, dynamic>> get scannedDevices => _scannedDevices;

  // Unknown device getters
  bool get showUnknownDeviceDialog => _showUnknownDeviceDialog;
  List<Map<String, dynamic>> get unknownDevices => _unknownDevices;
  Map<String, dynamic>? get selectedUnknownDevice => _selectedUnknownDevice;
  bool get showOtpConfirmationDialog => _showOtpConfirmationDialog;

  // Device selection getters
  Set<String> get selectedDeviceIds => _selectedDeviceIds;
  bool get isConnecting => _isConnecting;
  bool get connectionSuccessful => _connectionSuccessful;
  bool get hasSelectedDevices => _selectedDeviceIds.isNotEmpty;
  bool get showTroubleshootingScreen => _showTroubleshootingScreen;

  // Device mapping error getters
  bool get showDeviceMappingErrorDialog => _showDeviceMappingErrorDialog;
  String get deviceMappingError => _deviceMappingError;
  String? get pendingDeviceMappingError => _pendingDeviceMappingError;

  bool get unknownDeviceBottomSheetShown => _unknownDeviceBottomSheetShown;

  void setUnknownDeviceBottomSheetShown(bool value) {
    _unknownDeviceBottomSheetShown = value;
  }

  // OTP bottom sheet flag getter and setter
  bool get otpBottomSheetShown => _otpBottomSheetShown;

  void setOtpBottomSheetShown(bool value) {
    _otpBottomSheetShown = value;
  }

  // OTP verification getters
  bool get isVerifyingOtp => _isVerifyingOtp;
  String? get otpVerificationMessage => _otpVerificationMessage;
  String get otpCode => _otpCode;

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

  // Static methods to manage navigation state
  static void setNavigationState(bool wasConnected) {
    _isReturningFromOtherScreen = true;
    _wasConnectedBeforeNavigation = wasConnected;
    print('🎵 Dashboard: Set navigation state - wasConnected: $wasConnected');
  }

  static void clearNavigationState() {
    _isReturningFromOtherScreen = false;
    _wasConnectedBeforeNavigation = false;
    print('🎵 Dashboard: Cleared navigation state');
  }

  // Set up minimal initialization (listeners only) for when returning from other screens
  Future<void> _setupMinimalInitialization() async {
    print('🎵 Dashboard: Setting up minimal initialization...');

    // Initialize Bluetooth service
    await _bluetoothService.initialize();

    // Set up Bluetooth listener
    _bluetoothListener = () {
      // Check if command sequence just completed and we haven't checked player status yet
      if (!_bluetoothService.isExecutingCommands &&
          _bluetoothService.isConnected &&
          !_showPlayerCard &&
          !_isMinimizedFromPlayer) {
        print(
          '🎵 Dashboard: Command sequence completed, checking player status...',
        );
        checkPlayerStatus();
      }
      notifyListeners();
    };
    _bluetoothService.addListener(_bluetoothListener!);

    // Start Bluetooth state monitoring
    _startBluetoothStateMonitoring();

    print('🎵 Dashboard: Minimal initialization completed');
  }

  // Initialize the dashboard
  Future<void> initialize() async {
    print('🎵 Dashboard: initialize() called');
    _isLoading = false;
    
    // Reset permission flow flags on fresh initialization
    _permissionFlowInitiated = false;
    _permissionFlowInProgress = false;
    _shouldTriggerPermissionFlow = false;
    _permissionFlowCompleted = false;
    _lastPermissionFlowTime = null;
    
    notifyListeners();

    // Check if we're returning from another screen
    if (_isReturningFromOtherScreen) {
      print(
        '🎵 Dashboard: Returning from another screen, checking connection state...',
      );

      if (_wasConnectedBeforeNavigation && _bluetoothService.isConnected) {
        print(
          '🎵 Dashboard: Device was connected before navigation and is still connected, setting up minimal initialization',
        );
        clearNavigationState();
        await loadMusicDataLocal();
        filteredPrograms = await _getFilteredProgramsLocal();
        // Set up minimal initialization (listeners only)
        await _setupMinimalInitialization();
        return;
      } else if (_wasConnectedBeforeNavigation &&
          !_bluetoothService.isConnected) {
        print(
          '🎵 Dashboard: Device was connected before navigation but is no longer connected, reinitializing...',
        );
        clearNavigationState();
        // Continue with full initialization
      } else {
        print(
          '🎵 Dashboard: Device was not connected before navigation, continuing with initialization...',
        );
        clearNavigationState();
        // Continue with full initialization
      }
    }

    // Load user data from SharedPreferences
    await _loadUserData();

    // Load music data from SharedPreferences and fetch if needed
    await _loadMusicData();

    // Initialize Bluetooth service
    print('🎵 Dashboard: Initializing Bluetooth service...');
    await _bluetoothService.initialize();

    // Set user devices for validation
    _bluetoothService.setUserDevices(_userDevices);

    // Set callback for unknown devices found during scanning
    _bluetoothService.setOnUnknownDevicesFoundCallback((unknownDevices) {
      print('🎵 Dashboard: Unknown devices found: ${unknownDevices.length}');
      // Prevent multiple rapid calls and respect debounce period
      if (!_showUnknownDeviceDialog && _shouldShowBottomSheet()) {
        _unknownDevices = unknownDevices;
        _showUnknownDeviceDialog = true;
        _unknownDeviceBottomSheetShown = false; // Reset flag for new dialog
        notifyListeners();
      }
    });

    // Set callback for when no devices are found during scanning
    _bluetoothService.setOnNoDevicesFoundCallback(() {
      print('🎵 Dashboard: No devices found during scanning');
      _unknownDevices = []; // Empty list to trigger no device found UI
      _showUnknownDeviceDialog = true;
      _unknownDeviceBottomSheetShown = false; // Reset flag for new dialog
      notifyListeners();
    });

    print(
      '🎵 Dashboard: Bluetooth service initialized with ${_userDevices.length} user devices',
    );

    // Listen to Bluetooth service changes
    _bluetoothListener = () {
      // Check if command sequence just completed and we haven't checked player status yet
      if (!_bluetoothService.isExecutingCommands &&
          _bluetoothService.isConnected &&
          !_showPlayerCard &&
          !_isMinimizedFromPlayer) {
        print(
          '🎵 Dashboard: Command sequence completed, checking player status...',
        );
        checkPlayerStatus();
      }
      notifyListeners();
    };
    _bluetoothService.addListener(_bluetoothListener!);

    // Start Bluetooth state monitoring
    _startBluetoothStateMonitoring();

    // Check permissions before starting Bluetooth operations
    print('🎵 Dashboard: Checking permissions before Bluetooth operations...');
    await _checkPermissionsAndStartBluetooth();

    // Attempt auto-connection if user has devices
    if (_shouldAutoConnect) {
      print('🎵 Dashboard: User has devices - attempting auto-connection...');
      await _attemptAutoConnection();
    }

    // Check if we're coming from a minimized player
    print('🎵 Dashboard: Checking minimized player state...');
    print(
      '🎵 Dashboard: _isMinimizedFromPlayer: $_isMinimizedFromPlayer, _minimizedProgramId: $_minimizedProgramId',
    );

    if (_isMinimizedFromPlayer && _minimizedProgramId != null) {
      print('🎵 Dashboard: Restoring minimized player state');
      _showPlayerCard = true;
      _isPlaying = true;
      _currentPlayingProgramId = _minimizedProgramId;
      // Set the selected BCU file so the player card shows the correct program name
      _bluetoothService.setSelectedBcuFile(_minimizedProgramId!);
      print(
        '🎵 Dashboard: Minimized player restored with programId: $_minimizedProgramId',
      );
      clearMinimizedState(); // Clear the static state
    } else {
      print(
        '🎵 Dashboard: Not coming from minimized player, will check player status',
      );
    }

    // Player status check will be handled automatically by the Bluetooth listener
    // when the command sequence completes

    // Simulate loading time
    // await Future.delayed(const Duration(milliseconds: 500));

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
      final devicesCount = prefs.getInt('user_devices_count') ?? 0;

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

      print(
        '🎵 Dashboard: Loaded user data - Name: "$_userName", Devices Count: $devicesCount',
      );

      // Load user's devices array from stored JSON data
      await _loadUserDevices(prefs);

      // Always show device selection dialog after permissions are granted
      print(
        '🎵 Dashboard: Will show device selection dialog after Bluetooth initialization',
      );

      _shouldAutoConnect = false;
    } catch (e) {
      print('🎵 Dashboard: Error loading user data: $e');
      // Keep default values if loading fails
      _shouldAutoConnect = false;
    }
  }

  // Load user's devices array from stored data
  Future<void> _loadUserDevices(SharedPreferences prefs) async {
    try {
      // Try to get devices from user_data_json first
      final userDataJson = prefs.getString('user_data_json');
      if (userDataJson != null) {
        final userData = jsonDecode(userDataJson);
        final devices = userData['devices'] as List<dynamic>? ?? [];
        print(
          '🎵 Dashboard: Loaded ${devices.length} devices from user_data_json: $devices',
        );
        _userDevices = devices;
        return;
      }

      // Fallback to user_data
      final userDataString = prefs.getString('user_data');
      if (userDataString != null) {
        final userData = jsonDecode(userDataString);
        final devices = userData['data']?['devices'] as List<dynamic>? ?? [];
        print(
          '🎵 Dashboard: Loaded ${devices.length} devices from user_data: $devices',
        );
        _userDevices = devices;
        return;
      }

      print('🎵 Dashboard: No user devices data found in SharedPreferences');
      _userDevices = [];
    } catch (e) {
      print('🎵 Dashboard: Error loading user devices: $e');
      _userDevices = [];
    }
  }

  Future<void> loadMusicDataLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load device name from SharedPreferences first
      await _loadDeviceNameFromPrefs();

      // Try to load music data from SharedPreferences first
      final musicDataString = prefs.getString('user_music_data');
      if (musicDataString != null && musicDataString.isNotEmpty) {
        final musicData = jsonDecode(musicDataString);
        if (musicData is List && musicData.isNotEmpty) {
          _musicData = musicData;
          print(
            '🎵 Dashboard: Loaded ${musicData.length} music items from SharedPreferences',
          );
          return;
        }
      }

      // If no music data in SharedPreferences, fetch from API
      print(
        '🎵 Dashboard: No music data in SharedPreferences, fetching from API...',
      );
    } catch (e) {
      print('🎵 Dashboard: Error loading music data: $e');
      _musicData = [];
    }
  }

  // Load music data from SharedPreferences and fetch if needed
  Future<void> _loadMusicData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load device name from SharedPreferences first
      await _loadDeviceNameFromPrefs();

      // Try to load music data from SharedPreferences first
      final musicDataString = prefs.getString('user_music_data');
      if (musicDataString != null && musicDataString.isNotEmpty) {
        final musicData = jsonDecode(musicDataString);
        if (musicData is List && musicData.isNotEmpty) {
          _musicData = musicData;
          print(
            '🎵 Dashboard: Loaded ${musicData.length} music items from SharedPreferences',
          );
          return;
        }
      }

      // If no music data in SharedPreferences, fetch from API
      print(
        '🎵 Dashboard: No music data in SharedPreferences, fetching from API...',
      );
      await _fetchMusicData();
    } catch (e) {
      print('🎵 Dashboard: Error loading music data: $e');
      _musicData = [];
    }
  }

  // Fetch music data from API
  Future<void> _fetchMusicData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userIdString = prefs.getString('user_id');

      if (userIdString == null || userIdString.isEmpty) {
        print('🎵 Dashboard: No user ID found for fetching music data');
        return;
      }

      final userId = int.tryParse(userIdString);
      if (userId == null) {
        print(
          '🎵 Dashboard: Invalid user ID format for fetching music data: $userIdString',
        );
        return;
      }

      _isLoadingMusic = true;
      notifyListeners();

      print('🎵 Dashboard: Fetching music data for userId: $userId');

      final result = await _getAllMusicUseCase(userId);

      result.fold(
        (error) {
          print('🎵 Dashboard: Failed to fetch music data: $error');
          _musicData = [];
        },
        (musicData) {
          print('🎵 Dashboard: Successfully fetched music data');

          // Check if the data array is non-empty
          if (musicData is Map<String, dynamic> &&
              musicData.containsKey('data')) {
            final data = musicData['data'];
            if (data is List && data.isNotEmpty) {
              _musicData = data;
              print('🎵 Dashboard: User has ${data.length} music items');

              // Extract device name from music data
              _extractDeviceNameFromMusicData(data);

              // Save to SharedPreferences
              _saveMusicDataToPrefs(data);
            } else {
              print('🎵 Dashboard: User has no music items (empty data array)');
              _musicData = [];
              _deviceName = '';
            }
          } else {
            print('🎵 Dashboard: Invalid music data format');
            _musicData = [];
            _deviceName = '';
          }
        },
      );
    } catch (e) {
      print('🎵 Dashboard: Error fetching music data: $e');
      _musicData = [];
    } finally {
      _isLoadingMusic = false;
      notifyListeners();
    }
  }

  // Extract device name from music data
  void _extractDeviceNameFromMusicData(List<dynamic> musicData) {
    try {
      // Look for devicename in the music data
      for (final musicItem in musicData) {
        if (musicItem is Map<String, dynamic>) {
          // Check for devicename field in various possible formats
          final deviceName =
              musicItem['devicename'] ??
              musicItem['deviceName'] ??
              musicItem['device_name'] ??
              musicItem['device'] ??
              musicItem['deviceName'];

          if (deviceName != null && deviceName.toString().isNotEmpty) {
            _deviceName = deviceName.toString();
            print(
              '🎵 Dashboard: Extracted device name from music data: $_deviceName',
            );

            // Save device name to SharedPreferences
            _saveDeviceNameToPrefs(_deviceName);
            return;
          }
        }
      }

      // If no device name found, clear it
      _deviceName = '';
      print('🎵 Dashboard: No device name found in music data');
    } catch (e) {
      print('🎵 Dashboard: Error extracting device name from music data: $e');
      _deviceName = '';
    }
  }

  // Save device name to SharedPreferences
  Future<void> _saveDeviceNameToPrefs(String deviceName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_device_name', deviceName);
      print(
        '🎵 Dashboard: Saved device name to SharedPreferences: $deviceName',
      );
    } catch (e) {
      print('🎵 Dashboard: Error saving device name to SharedPreferences: $e');
    }
  }

  // Load device name from SharedPreferences
  Future<void> _loadDeviceNameFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final deviceName = prefs.getString('user_device_name') ?? '';
      _deviceName = deviceName;
      print(
        '🎵 Dashboard: Loaded device name from SharedPreferences: $_deviceName',
      );
    } catch (e) {
      print(
        '🎵 Dashboard: Error loading device name from SharedPreferences: $e',
      );
      _deviceName = '';
    }
  }

  // Save music data to SharedPreferences
  Future<void> _saveMusicDataToPrefs(List<dynamic> musicData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final musicDataString = jsonEncode(musicData);
      await prefs.setString('user_music_data', musicDataString);
      print(
        '🎵 Dashboard: Saved ${musicData.length} music items to SharedPreferences',
      );
    } catch (e) {
      print('🎵 Dashboard: Error saving music data to SharedPreferences: $e');
    }
  }

  // Get filtered programs (union of music data and Bluetooth programs)
  Future<List> _getFilteredProgramsLocal() async {
    try {
      print(
        '🎵 Dashboard: Creating union between music data and Bluetooth programs...',
      );

      // Get Bluetooth programs from the service
      final bluetoothPrograms = _bluetoothService.availablePrograms;
      print(
        '🎵 Dashboard: Bluetooth programs: ${bluetoothPrograms.length} items',
      );
      await loadMusicDataLocal();
      // Get music data
      print('🎵 Dashboard: Music data: ${_musicData.length} items');

      // If no music data or no Bluetooth programs, return empty list
      if (_musicData.isEmpty || bluetoothPrograms.isEmpty) {
        print('🎵 Dashboard: No music data or Bluetooth programs available');
        return [];
      }

      // Create union by matching music data with Bluetooth programs
      final filteredPrograms = <dynamic>[];

      for (final musicItem in _musicData) {
        if (musicItem is Map<String, dynamic>) {
          // Check if this music item has a musicfiles array
          final musicFiles = musicItem['musicfiles'];
          if (musicFiles is List && musicFiles.isNotEmpty) {
            // Process each entry in the musicfiles array
            for (final musicFile in musicFiles) {
              if (musicFile is Map<String, dynamic>) {
                // Extract relevant fields from music file
                final musicName = _extractMusicName(musicFile);
                final musicId = _extractMusicId(musicFile);

                if (musicName != null && musicId != null) {
                  // Check if this music file matches any Bluetooth program
                  final matchingBluetoothProgram =
                      _findMatchingBluetoothProgram(
                        musicName,
                        musicId,
                        bluetoothPrograms,
                      );

                  if (matchingBluetoothProgram != null) {
                    // Create enhanced music item with Bluetooth program info
                    final enhancedMusicItem = Map<String, dynamic>.from(
                      musicItem,
                    );
                    enhancedMusicItem['bluetoothProgram'] =
                        matchingBluetoothProgram;
                    enhancedMusicItem['bluetoothProgramName'] =
                        matchingBluetoothProgram.split('|')[0];
                    enhancedMusicItem['bluetoothProgramId'] =
                        matchingBluetoothProgram.split('|')[1];
                    // Add the specific music file info
                    enhancedMusicItem['matchedMusicFile'] = musicFile;

                    filteredPrograms.add(enhancedMusicItem);
                    print(
                      '🎵 Dashboard: Matched music file "$musicName" with Bluetooth program "$matchingBluetoothProgram"',
                    );
                  }
                }
              }
            }
          } else {
            // Fallback to original logic for music items without musicfiles array
            final musicName = _extractMusicName(musicItem);
            final musicId = _extractMusicId(musicItem);

            if (musicName != null && musicId != null) {
              // Check if this music item matches any Bluetooth program
              final matchingBluetoothProgram = _findMatchingBluetoothProgram(
                musicName,
                musicId,
                bluetoothPrograms,
              );

              if (matchingBluetoothProgram != null) {
                // Create enhanced music item with Bluetooth program info
                final enhancedMusicItem = Map<String, dynamic>.from(musicItem);
                enhancedMusicItem['bluetoothProgram'] =
                    matchingBluetoothProgram;
                enhancedMusicItem['bluetoothProgramName'] =
                    matchingBluetoothProgram.split('|')[0];
                enhancedMusicItem['bluetoothProgramId'] =
                    matchingBluetoothProgram.split('|')[1];

                filteredPrograms.add(enhancedMusicItem);
                print(
                  '🎵 Dashboard: Matched music "$musicName" with Bluetooth program "$matchingBluetoothProgram"',
                );
              }
            }
          }
        }
      }

      print(
        '🎵 Dashboard: Created union with ${filteredPrograms.length} filtered programs',
      );
      return filteredPrograms;
    } catch (e) {
      print('🎵 Dashboard: Error creating filtered programs: $e');
      return [];
    }
  }

  // Get filtered programs (union of music data and Bluetooth programs)
  List<dynamic> _getFilteredPrograms() {
    try {
      print(
        '🎵 Dashboard: Creating union between music data and Bluetooth programs...',
      );

      // Get Bluetooth programs from the service
      final bluetoothPrograms = _bluetoothService.availablePrograms;
      print(
        '🎵 Dashboard: Bluetooth programs: ${bluetoothPrograms.length} items',
      );
      // Get music data
      print('🎵 Dashboard: Music data: ${_musicData.length} items');

      // If no music data or no Bluetooth programs, return empty list
      if (_musicData.isEmpty || bluetoothPrograms.isEmpty) {
        print('🎵 Dashboard: No music data or Bluetooth programs available');
        return [];
      }

      // Create union by matching music data with Bluetooth programs
      final filteredPrograms = <dynamic>[];

      for (final musicItem in _musicData) {
        if (musicItem is Map<String, dynamic>) {
          // Check if this music item has a musicfiles array
          final musicFiles = musicItem['musicfiles'];
          if (musicFiles is List && musicFiles.isNotEmpty) {
            // Process each entry in the musicfiles array
            for (final musicFile in musicFiles) {
              if (musicFile is Map<String, dynamic>) {
                // Extract relevant fields from music file
                final musicName = _extractMusicName(musicFile);
                final musicId = _extractMusicId(musicFile);

                if (musicName != null && musicId != null) {
                  // Check if this music file matches any Bluetooth program
                  final matchingBluetoothProgram =
                      _findMatchingBluetoothProgram(
                        musicName,
                        musicId,
                        bluetoothPrograms,
                      );

                  if (matchingBluetoothProgram != null) {
                    // Create enhanced music item with Bluetooth program info
                    final enhancedMusicItem = Map<String, dynamic>.from(
                      musicItem,
                    );
                    enhancedMusicItem['bluetoothProgram'] =
                        matchingBluetoothProgram;
                    enhancedMusicItem['bluetoothProgramName'] =
                        matchingBluetoothProgram.split('|')[0];
                    enhancedMusicItem['bluetoothProgramId'] =
                        matchingBluetoothProgram.split('|')[1];
                    // Add the specific music file info
                    enhancedMusicItem['matchedMusicFile'] = musicFile;

                    filteredPrograms.add(enhancedMusicItem);
                    print(
                      '🎵 Dashboard: Matched music file "$musicName" with Bluetooth program "$matchingBluetoothProgram"',
                    );
                  }
                }
              }
            }
          } else {
            // Fallback to original logic for music items without musicfiles array
            final musicName = _extractMusicName(musicItem);
            final musicId = _extractMusicId(musicItem);

            if (musicName != null && musicId != null) {
              // Check if this music item matches any Bluetooth program
              final matchingBluetoothProgram = _findMatchingBluetoothProgram(
                musicName,
                musicId,
                bluetoothPrograms,
              );

              if (matchingBluetoothProgram != null) {
                // Create enhanced music item with Bluetooth program info
                final enhancedMusicItem = Map<String, dynamic>.from(musicItem);
                enhancedMusicItem['bluetoothProgram'] =
                    matchingBluetoothProgram;
                enhancedMusicItem['bluetoothProgramName'] =
                    matchingBluetoothProgram.split('|')[0];
                enhancedMusicItem['bluetoothProgramId'] =
                    matchingBluetoothProgram.split('|')[1];

                filteredPrograms.add(enhancedMusicItem);
                print(
                  '🎵 Dashboard: Matched music "$musicName" with Bluetooth program "$matchingBluetoothProgram"',
                );
              }
            }
          }
        }
      }

      print(
        '🎵 Dashboard: Created union with ${filteredPrograms.length} filtered programs',
      );
      return filteredPrograms;
    } catch (e) {
      print('🎵 Dashboard: Error creating filtered programs: $e');
      return [];
    }
  }

  // Extract music name from music data item
  String? _extractMusicName(Map<String, dynamic> musicItem) {
    // Try different possible field names for music name
    return musicItem['name'] ??
        musicItem['title'] ??
        musicItem['musicName'] ??
        musicItem['programName'] ??
        musicItem['filename'] ??
        musicItem['file_name'];
  }

  // Extract music ID from music data item
  String? _extractMusicId(Map<String, dynamic> musicItem) {
    // Try different possible field names for music ID
    return musicItem['id']?.toString() ??
        musicItem['musicId']?.toString() ??
        musicItem['programId']?.toString() ??
        musicItem['fileId']?.toString() ??
        musicItem['file_id']?.toString();
  }

  // Find matching Bluetooth program for a music item
  String? _findMatchingBluetoothProgram(
    String musicName,
    String musicId,
    List<String> bluetoothPrograms,
  ) {
    try {
      // Normalize music name for comparison
      final normalizedMusicName = _normalizeName(musicName);

      for (final bluetoothProgram in bluetoothPrograms) {
        final parts = bluetoothProgram.split('|');
        if (parts.length >= 2) {
          final bluetoothProgramName = parts[1];
          final bluetoothProgramId = parts[0];

          // Normalize Bluetooth program name for comparison
          final normalizedBluetoothName = _normalizeName(bluetoothProgramName);

          // Check for exact match or partial match
          if (_isNameMatch(normalizedMusicName, normalizedBluetoothName) ||
              _isIdMatch(musicId, bluetoothProgramId)) {
            return bluetoothProgram;
          }
        }
      }

      return null;
    } catch (e) {
      print('🎵 Dashboard: Error finding matching Bluetooth program: $e');
      return null;
    }
  }

  // Normalize name for comparison (remove special chars, convert to lowercase)
  String _normalizeName(String name) {
    return name
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '') // Remove special characters
        .replaceAll(RegExp(r'\s+'), ' ') // Normalize spaces
        .trim();
  }

  // Check if names match (exact or partial)
  bool _isNameMatch(String musicName, String bluetoothName) {
    // Exact match
    if (musicName == bluetoothName) return true;

    // Check if one contains the other (for partial matches)
    if (musicName.contains(bluetoothName) || bluetoothName.contains(musicName))
      return true;

    // Check for word-level matches
    final musicWords = musicName.split(' ');
    final bluetoothWords = bluetoothName.split(' ');

    // If any significant word matches, consider it a match
    for (final musicWord in musicWords) {
      if (musicWord.length > 2) {
        // Only consider words longer than 2 chars
        for (final bluetoothWord in bluetoothWords) {
          if (bluetoothWord.length > 2 && musicWord == bluetoothWord) {
            return true;
          }
        }
      }
    }

    return false;
  }

  // Check if IDs match
  bool _isIdMatch(String musicId, String bluetoothId) {
    // Remove file extensions for comparison
    final normalizedMusicId = musicId.replaceAll(RegExp(r'\.\w+$'), '');
    final normalizedBluetoothId = bluetoothId.replaceAll(RegExp(r'\.\w+$'), '');

    return normalizedMusicId.toLowerCase() ==
        normalizedBluetoothId.toLowerCase();
  }

  // Start Bluetooth state monitoring
  Future<void> _startBluetoothStateMonitoring() async {
    if (_isBluetoothStateMonitoring) return;

    _isBluetoothStateMonitoring = true;
    print('🎵 Dashboard: Starting Bluetooth state monitoring...');

    try {
      _bluetoothStateSubscription = ble.FlutterBluePlus.adapterState.listen((
        state,
      ) {
        print('🎵 Dashboard: Bluetooth state changed to: $state');
        _handleBluetoothStateChange(state);
      });
    } catch (e) {
      print('🎵 Dashboard: Error starting Bluetooth state monitoring: $e');
      _isBluetoothStateMonitoring = false;
    }
  }

  // Handle Bluetooth state changes
  void _handleBluetoothStateChange(ble.BluetoothAdapterState state) {
    switch (state) {
      case ble.BluetoothAdapterState.off:
        print('🎵 Dashboard: Bluetooth turned OFF - showing error');
        _handleBluetoothTurnedOff();
        break;
      case ble.BluetoothAdapterState.on:
        print('🎵 Dashboard: Bluetooth turned ON - checking permissions');
        _handleBluetoothTurnedOn();
        break;
      case ble.BluetoothAdapterState.turningOn:
        print('🎵 Dashboard: Bluetooth turning ON...');
        break;
      case ble.BluetoothAdapterState.turningOff:
        print('🎵 Dashboard: Bluetooth turning OFF...');
        break;
      case ble.BluetoothAdapterState.unknown:
        print('🎵 Dashboard: Bluetooth state unknown');
        break;
      case ble.BluetoothAdapterState.unavailable:
        print('🎵 Dashboard: Bluetooth unavailable');
        break;
      case ble.BluetoothAdapterState.unauthorized:
        print('🎵 Dashboard: Bluetooth unauthorized');
        _handleBluetoothTurnedOff(); // Treat as turned off
        break;
    }
  }

  // Handle Bluetooth turned off
  void _handleBluetoothTurnedOff() {
    // Use existing popup system
    _showBluetoothEnableDialog = true;
    notifyListeners();
  }

  // Handle Bluetooth turned on
  Future<void> _handleBluetoothTurnedOn() async {
    try {
      // Clear any existing error messages
      _bluetoothService.clearErrorMessage();

      // Always start the full permission flow when Bluetooth is turned on
      print(
        '🎵 Dashboard: Bluetooth turned on - starting full permission flow',
      );
      await _startFullPermissionFlow();
    } catch (e) {
      print('🎵 Dashboard: Error handling Bluetooth turned on: $e');
    }
  }

  // Start full permission flow (all 4 dialogs in sequence)
  Future<void> _startFullPermissionFlow() async {
    try {
      // Check if permission flow is in progress
      if (_permissionFlowInProgress) {
        print('🎵 Dashboard: Permission flow already in progress, skipping...');
        return;
      }

      // Check cooldown period
      if (_lastPermissionFlowTime != null) {
        final timeSinceLastFlow = DateTime.now().difference(_lastPermissionFlowTime!);
        if (timeSinceLastFlow < _permissionFlowCooldown) {
          print('🎵 Dashboard: Permission flow cooldown active, skipping (${timeSinceLastFlow.inSeconds}s since last flow)');
          return;
        }
      }

      // Check if both permissions are already granted
      final hasLocationPermission =
          await LocationPermissionHelper.isLocationPermissionGranted();
      final hasBluetoothPermission =
          await BluetoothPermissionHelper.isBluetoothEnabled();

      if (hasLocationPermission && hasBluetoothPermission) {
        print(
          '🎵 Dashboard: Both permissions already granted, checking connection status...',
        );

        // Mark permission flow as completed
        _permissionFlowCompleted = true;
        _lastPermissionFlowTime = DateTime.now();

        // Check if already connected before starting scan
        if (_bluetoothService.isConnected) {
          print('🎵 Dashboard: Already connected to device, skipping scan');
          _bluetoothService.setStatusMessage(
            '${_bluetoothService.connectedDevice?.platformName} is connected',
          );
        } else {
          print('🎵 Dashboard: Not connected, starting device scanning...');
          await _bluetoothService.startScanning();
          _bluetoothService.setStatusMessage('Scanning for devices...');
        }
        notifyListeners();
        return;
      }

      print('🎵 Dashboard: Starting full permission flow sequence...');

      // Mark permission flow as initiated
      _permissionFlowInitiated = true;
      _lastPermissionFlowTime = DateTime.now();

      // Set flag to trigger permission flow in UI layer
      _shouldTriggerPermissionFlow = true;
      notifyListeners();
    } catch (e) {
      print('🎵 Dashboard: Error starting full permission flow: $e');
      // Reset flags on error
      _permissionFlowInProgress = false;
      notifyListeners();
    }
  }

  // Clear permission flow trigger flag
  void clearPermissionFlowTrigger() {
    _shouldTriggerPermissionFlow = false;
    notifyListeners();
  }

  // Set permission flow in progress flag
  void setPermissionFlowInProgress(bool inProgress) {
    _permissionFlowInProgress = inProgress;
    
    // If setting to false (completed), mark as completed
    if (!inProgress) {
      _permissionFlowCompleted = true;
      _lastPermissionFlowTime = DateTime.now();
      print('🎵 Dashboard: Permission flow completed');
    }
    
    notifyListeners();
  }

  // Check if permission flow should be allowed (considering cooldown)
  bool _shouldAllowPermissionFlow() {
    // If permission flow is in progress, don't allow another one
    if (_permissionFlowInProgress) {
      print('🎵 Dashboard: Permission flow already in progress, not allowing another');
      return false;
    }
    
    // Check cooldown period
    if (_lastPermissionFlowTime != null) {
      final timeSinceLastFlow = DateTime.now().difference(_lastPermissionFlowTime!);
      if (timeSinceLastFlow < _permissionFlowCooldown) {
        print('🎵 Dashboard: Permission flow cooldown active, not allowing another (${timeSinceLastFlow.inSeconds}s since last flow)');
        return false;
      }
    }
    
    return true;
  }

  // Start permission flow after Bluetooth is enabled
  Future<void> _startPermissionFlowAfterBluetoothEnabled() async {
    try {
      // Check if Bluetooth permission exists
      final hasPermission = await _checkBluetoothPermission();

      if (hasPermission) {
        print('🎵 Dashboard: Bluetooth permission exists - starting scan');
        await _bluetoothService.startScanning();
        _bluetoothService.setStatusMessage('Scanning for devices...');
      } else {
        print(
          '🎵 Dashboard: Bluetooth permission missing - will be handled by UI layer',
        );
        _bluetoothService.setStatusMessage('Click here to scan for devices');
      }

      notifyListeners();
    } catch (e) {
      print(
        '🎵 Dashboard: Error starting permission flow after Bluetooth enabled: $e',
      );
    }
  }

  // Check if Bluetooth permission exists
  Future<bool> _checkBluetoothPermission() async {
    try {
      // Check if Bluetooth is enabled (this includes permission check)
      final state = await ble.FlutterBluePlus.adapterState.first;
      return state == ble.BluetoothAdapterState.on;
    } catch (e) {
      print('🎵 Dashboard: Error checking Bluetooth permission: $e');
      return false;
    }
  }

  // Request Bluetooth permission and start scanning
  Future<void> _requestBluetoothPermissionAndScan() async {
    try {
      // For now, just start scanning since we can't access context here
      // The permission should be handled by the UI layer
      print('🎵 Dashboard: Starting scan after Bluetooth turned on');
      await _bluetoothService.startScanning();
      _bluetoothService.setStatusMessage('Scanning for devices...');
      notifyListeners();
    } catch (e) {
      print('🎵 Dashboard: Error starting scan after Bluetooth turned on: $e');
      _bluetoothService.setErrorMessage(
        'Error starting scan. Please try again.',
      );
      notifyListeners();
    }
  }

  // Attempt automatic device connection
  Future<void> _attemptAutoConnection() async {
    // Prevent multiple simultaneous calls
    if (_isAutoConnectionRunning) {
      print(
        '🎵 Dashboard: Auto-connection already running, skipping duplicate call',
      );
      return;
    }

    _isAutoConnectionRunning = true;

    try {
      print('🎵 Dashboard: Starting device scanning process...');
      print(
        '🎵 Dashboard: User has ${_userDevices.length} devices in their account',
      );

      // Check if Bluetooth service is already connected
      if (_bluetoothService.isConnected) {
        print(
          '🎵 Dashboard: Device already connected, skipping auto-connection',
        );
        _isAutoConnectionRunning = false;
        return;
      }

      // Check if Bluetooth service is ready
      if (!_bluetoothService.isConnected) {
        print(
          '🎵 Dashboard: Bluetooth service not connected, starting scanning...',
        );

        // Start scanning for devices
        await _bluetoothService.startScanning();

        // Wait a bit for scanning to complete
        await Future.delayed(const Duration(seconds: 10));

        // Check if we found any devices
        if (_bluetoothService.scannedDevices.isNotEmpty) {
          print(
            '🎵 Dashboard: Found ${_bluetoothService.scannedDevices.length} devices during auto-scan',
          );

          // First, try to auto-connect to device matching getAllMusic devicename
          final autoConnectDevice = _findAutoConnectDevice(
            _bluetoothService.scannedDevices,
          );

          if (autoConnectDevice != null) {
            print(
              '🎵 Dashboard: Found device matching getAllMusic devicename, attempting auto-connection: ${autoConnectDevice.platformName}',
            );
            try {
              await _bluetoothService.connectToDevice(autoConnectDevice);
              print(
                '🎵 Dashboard: Auto-connected to device: ${autoConnectDevice.platformName}',
              );
              _isAutoConnectionRunning = false;
              return; // Exit early since we successfully connected
            } catch (e) {
              print('🎵 Dashboard: Auto-connection failed: $e');
              // Continue with normal flow if auto-connection fails
            }
          }

          // Check for unknown devices (not in user's registered devices)
          final unknownDevicesList = _findUnknownDevices(
            _bluetoothService.scannedDevices,
          );

          if (unknownDevicesList.isNotEmpty) {
            print(
              '🎵 Dashboard: Found ${unknownDevicesList.length} unknown devices, checking OTP dialog status...',
            );
            print(
              '🎵 Dashboard: Current state - otpDialogClosed: $_otpDialogClosed, showOtpConfirmationDialog: $_showOtpConfirmationDialog, showUnknownDeviceDialog: $_showUnknownDeviceDialog',
            );
            // Only show unknown devices list dialog if OTP dialog hasn't been closed and not already showing and debounce period has passed
            if (!_showUnknownDeviceDialog && _shouldShowBottomSheet()) {
              _unknownDevices = unknownDevicesList
                  .map(
                    (device) => {
                      'id': device.remoteId.toString(),
                      'name': device.platformName.isNotEmpty
                          ? device.platformName
                          : device.remoteId.toString(),
                      'signalStrength': _bluetoothService.getDeviceRssi(
                        device,
                      ), // Use actual RSSI from device
                      'isConnected': false,
                      'isUnknown': true,
                      'device':
                          device, // Store the actual BluetoothDevice for connection
                    },
                  )
                  .toList();
              _showUnknownDeviceDialog = true;
              _unknownDeviceBottomSheetShown =
                  false; // Reset flag when showing new dialog
            }
          } else {
            // Show device selection dialog for all found devices (all are known)
            _scannedDevices = _bluetoothService.scannedDevices
                .map(
                  (device) => {
                    'id': device.remoteId.toString(),
                    'name': device.platformName.isNotEmpty
                        ? device.platformName
                        : device.remoteId.toString(),
                    'signalStrength': _bluetoothService.getDeviceRssi(
                      device,
                    ), // Use actual RSSI from device
                    'isConnected': false,
                  },
                )
                .toList();

            _showDeviceSelectionDialog = true;
            print(
              '🎵 Dashboard: Showing device selection dialog with ${_scannedDevices.length} devices',
            );
          }
        } else {
          print('🎵 Dashboard: No devices found during auto-scan');
        }
      } else {
        print('🎵 Dashboard: Bluetooth service already connected');
      }
    } catch (e) {
      print('🎵 Dashboard: Error during auto-connection: $e');
    } finally {
      _isAutoConnectionRunning = false;
    }
  }

  // Added: Find unknown devices (not in user's registered devices)
  List<ble.BluetoothDevice> _findUnknownDevices(
    List<ble.BluetoothDevice> scannedDevices,
  ) {
    final unknownDevices = <ble.BluetoothDevice>[];

    for (final scannedDevice in scannedDevices) {
      final deviceName = scannedDevice.platformName.toLowerCase();
      bool isKnownDevice = false;

      // First, check if this device matches the device name from getAllMusic API
      if (_deviceName.isNotEmpty) {
        final expectedDeviceName = _deviceName.toLowerCase();
        if (deviceName.contains(expectedDeviceName) ||
            expectedDeviceName.contains(deviceName)) {
          isKnownDevice = true;
          print(
            '🎵 Dashboard: Device matches getAllMusic devicename, marking as known: ${scannedDevice.platformName} (expected: $_deviceName)',
          );
        }
      }

      // If not matched by getAllMusic devicename, check user's registered devices
      if (!isKnownDevice) {
        for (final userDevice in _userDevices) {
          if (userDevice is Map<String, dynamic>) {
            // Check various possible device identifiers
            final deviceId = userDevice['id']?.toString().toLowerCase() ?? '';
            final deviceNameFromUser =
                userDevice['name']?.toString().toLowerCase() ?? '';
            final deviceMac = userDevice['mac']?.toString().toLowerCase() ?? '';
            final deviceSerial =
                userDevice['serial']?.toString().toLowerCase() ?? '';

            // Match by device name (most common case)
            if (deviceName.contains('evolv28') &&
                (deviceNameFromUser.contains('evolv28') ||
                    deviceId.contains('evolv28') ||
                    deviceMac.isNotEmpty ||
                    deviceSerial.isNotEmpty)) {
              isKnownDevice = true;
              break;
            }
          } else if (userDevice is String) {
            // If user device is just a string, check if it contains evolv28
            if (userDevice.toLowerCase().contains('evolv28') &&
                deviceName.contains('evolv28')) {
              isKnownDevice = true;
              break;
            }
          }
        }
      }

      // If device is not known and is an Evolv28 device, add to unknown list
      if (!isKnownDevice && deviceName.contains('evolv28')) {
        unknownDevices.add(scannedDevice);
        print(
          '🎵 Dashboard: Found unknown Evolv28 device: ${scannedDevice.platformName}',
        );
      }
    }

    return unknownDevices;
  }

  // Find device that matches getAllMusic devicename for auto-connection
  ble.BluetoothDevice? _findAutoConnectDevice(
    List<ble.BluetoothDevice> scannedDevices,
  ) {
    if (_deviceName.isEmpty) {
      print(
        '🎵 Dashboard: No device name from getAllMusic API, skipping auto-connection',
      );
      return null;
    }

    for (final scannedDevice in scannedDevices) {
      final deviceName = scannedDevice.platformName.toLowerCase();
      final expectedDeviceName = _deviceName.toLowerCase();

      // Check if device name matches (partial or exact match)
      if (deviceName.contains(expectedDeviceName) ||
          expectedDeviceName.contains(deviceName)) {
        print(
          '🎵 Dashboard: Found device for auto-connection: ${scannedDevice.platformName} (matches: $_deviceName)',
        );
        return scannedDevice;
      }
    }

    print(
      '🎵 Dashboard: No device found matching getAllMusic devicename: $_deviceName',
    );
    return null;
  }

  // Find devices that match user's devices
  List<ble.BluetoothDevice> _findMatchingUserDevices(
    List<ble.BluetoothDevice> scannedDevices,
  ) {
    final matchingDevices = <ble.BluetoothDevice>[];

    for (final scannedDevice in scannedDevices) {
      final deviceName = scannedDevice.platformName.toLowerCase();

      // First, check if this device matches the device name from getAllMusic API
      if (_deviceName.isNotEmpty) {
        final expectedDeviceName = _deviceName.toLowerCase();
        if (deviceName.contains(expectedDeviceName) ||
            expectedDeviceName.contains(deviceName)) {
          matchingDevices.add(scannedDevice);
          print(
            '🎵 Dashboard: Found matching device by getAllMusic devicename: ${scannedDevice.platformName} (expected: $_deviceName)',
          );
          continue; // Skip other checks since we found a match
        }
      }

      // Check if this scanned device matches any of user's devices
      for (final userDevice in _userDevices) {
        if (userDevice is Map<String, dynamic>) {
          // Check various possible device identifiers
          final deviceId = userDevice['id']?.toString().toLowerCase() ?? '';
          final deviceNameFromUser =
              userDevice['name']?.toString().toLowerCase() ?? '';
          final deviceMac = userDevice['mac']?.toString().toLowerCase() ?? '';
          final deviceSerial =
              userDevice['serial']?.toString().toLowerCase() ?? '';

          // Match by device name (most common case)
          if (deviceName.contains('evolv28') &&
              (deviceNameFromUser.contains('evolv28') ||
                  deviceId.contains('evolv28') ||
                  deviceMac.isNotEmpty ||
                  deviceSerial.isNotEmpty)) {
            matchingDevices.add(scannedDevice);
            print(
              '🎵 Dashboard: Found matching device: ${scannedDevice.platformName}',
            );
            break; // Don't add the same device multiple times
          }
        } else if (userDevice is String) {
          // If user device is just a string, check if it contains evolv28
          if (userDevice.toLowerCase().contains('evolv28') &&
              deviceName.contains('evolv28')) {
            matchingDevices.add(scannedDevice);
            print(
              '🎵 Dashboard: Found matching device by string: ${scannedDevice.platformName}',
            );
            break;
          }
        }
      }
    }

    return matchingDevices;
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
        // Set navigation state to preserve connection when returning
        setNavigationState(_bluetoothService.isConnected);
        context.go(AppRoutes.programs);
        break;
      case 2: // Device
        // Set navigation state to preserve connection when returning
        setNavigationState(_bluetoothService.isConnected);
        context.go(AppRoutes.deviceConnected);
        break;
      case 3: // Profile
        // Set navigation state to preserve connection when returning
        setNavigationState(_bluetoothService.isConnected);
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
        print(
          '🎵 Dashboard: Player card state set to: showPlayerCard=$_showPlayerCard, isPlaying=$_isPlaying, selectedBcuFile=$playingFile',
        );
        notifyListeners();
      } else {
        print('🎵 Dashboard: No program currently playing');
        _showPlayerCard = false;
        _isPlaying = false;
        print(
          '🎵 Dashboard: Player card state set to: showPlayerCard=$_showPlayerCard, isPlaying=$_isPlaying',
        );
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
        print(
          '🎵 Dashboard: Player state reset - showPlayerCard: $_showPlayerCard, isPlaySuccessful: ${_bluetoothService.isPlaySuccessful}',
        );
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
      // Only start scanning if we're not already showing dialogs or scanning
      if (!_showUnknownDeviceDialog && !_showDeviceSelectionDialog) {
        print('🎵 Dashboard: connectBluetoothDevice() - Starting new scan');
        await _attemptAutoConnection();
      } else {
        print(
          '🎵 Dashboard: connectBluetoothDevice() - Skipping scan, dialog already showing',
        );
      }
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
    print(
      '🎵 Dashboard: isBluetoothEnabled=$_isBluetoothEnabled, dialogShown=$_bluetoothDialogShown, scanPermissionGranted=$_isBluetoothScanPermissionGranted, statusChecked=$_bluetoothStatusChecked, permissionFlowInitiated=$_permissionFlowInitiated, permissionFlowCompleted=$_permissionFlowCompleted',
    );

    // Check if permission flow is in progress
    if (_permissionFlowInProgress) {
      print('🎵 Dashboard: Permission flow already in progress, skipping');
      return;
    }

    // Check cooldown period
    if (_lastPermissionFlowTime != null) {
      final timeSinceLastFlow = DateTime.now().difference(_lastPermissionFlowTime!);
      if (timeSinceLastFlow < _permissionFlowCooldown) {
        print('🎵 Dashboard: Permission flow cooldown active, skipping (${timeSinceLastFlow.inSeconds}s since last flow)');
        return;
      }
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
      print(
        '🎵 Dashboard: Location permission check result: $hasLocationPermission, dialogShown: $_locationPermissionDialogShown',
      );
      if (!hasLocationPermission && !_locationPermissionDialogShown) {
        print(
          '🎵 Dashboard: Location permission missing - triggering UI layer permission flow',
        );
        _locationPermissionDialogShown = true; // Prevent multiple requests
        _permissionFlowInitiated = true; // Mark permission flow as initiated
        // Trigger the UI layer permission flow
        _shouldTriggerPermissionFlow = true;
        notifyListeners();
      } else if (hasLocationPermission) {
        // Location permission granted, check BLE scan permission
        bool hasBluetoothPermission = await _checkBluetoothScanPermission();
        print(
          '🎵 Dashboard: Bluetooth permission check result: $hasBluetoothPermission, dialogShown: $_bluetoothScanPermissionDialogShown',
        );

        if (hasBluetoothPermission) {
          print(
            '🎵 Dashboard: All permissions already granted, starting Bluetooth operations directly',
          );
          _isBluetoothScanPermissionGranted = true;
          await _startBluetoothOperations();
        } else if (!_bluetoothScanPermissionDialogShown) {
          print(
            '🎵 Dashboard: Bluetooth permission missing - triggering UI layer permission flow',
          );
          _bluetoothScanPermissionDialogShown =
              true; // Prevent multiple requests
          // Trigger the UI layer permission flow
          _shouldTriggerPermissionFlow = true;
          notifyListeners();
        }
      }
    } else if (!_bluetoothStatusChecked) {
      print(
        '🎵 Dashboard: Bluetooth status not yet checked, waiting for status check to complete...',
      );
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
      print(
        '🎵 Dashboard: Bluetooth enabled: $_isBluetoothEnabled, status checked: $_bluetoothStatusChecked',
      );

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
      bool isGranted =
          permission == LocationPermission.whileInUse ||
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
    print(
      '🎵 Dashboard: Starting Bluetooth operations after permissions granted...',
    );

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
      print(
        '🎵 Dashboard: Already connected to Bluetooth device - skipping scan',
      );
    }
  }

  /// Start automatic device scanning when both permissions are granted
  Future<void> startAutomaticDeviceScanning() async {
    print(
      '🎵 Dashboard: Starting automatic device scanning after permissions granted...',
    );

    // Mark permissions as granted
    _isLocationPermissionGranted = true;
    _isBluetoothScanPermissionGranted = true;
    
    // Mark permission flow as completed
    _permissionFlowCompleted = true;
    _permissionFlowInProgress = false;
    _lastPermissionFlowTime = DateTime.now();

    // Start Bluetooth operations which includes scanning
    await _startBluetoothOperations();

    notifyListeners();
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
    print(
      '🎵 Dashboard: User allowed location permission, requesting system permission',
    );

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
        print(
          '🎵 Dashboard: Bluetooth permission check result: $hasBluetoothPermission, dialogShown: $_bluetoothScanPermissionDialogShown',
        );

        if (hasBluetoothPermission) {
          print(
            '🎵 Dashboard: All permissions granted, starting Bluetooth operations',
          );
          _isBluetoothScanPermissionGranted = true;
          
          // Mark permission flow as completed
          _permissionFlowCompleted = true;
          _permissionFlowInProgress = false;
          _lastPermissionFlowTime = DateTime.now();
          
          await _startBluetoothOperations();
        } else if (!_bluetoothScanPermissionDialogShown) {
          print(
            '🎵 Dashboard: Location permission granted, showing Bluetooth permission dialog',
          );
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

  void denyLocationPermission() {
    _showLocationPermissionDialog = false;
    print('🎵 Dashboard: User denied location permission');

    // Log denied location permission
    _loggingService.sendLogs(
      event: 'Location Permission',
      status: 'failed',
      notes: 'user_denied',
    );

    notifyListeners();
  }

  Future<void> allowBluetoothScanPermission() async {
    _showBluetoothScanPermissionDialog = false;
    print(
      '🎵 Dashboard: User allowed Bluetooth scan permission, requesting system permission',
    );

    try {
      if (Platform.isAndroid) {
        var status = await Permission.bluetoothScan.request();
        print(
          '🎵 Dashboard: Bluetooth scan permission request result: $status',
        );

        // Log BLE permission result in background
        await _loggingService.sendLogs(
          event: 'BLE Permission',
          status: status == PermissionStatus.granted ? 'success' : 'failed',
          notes: status == PermissionStatus.granted ? 'success' : status.name,
        );

        if (status == PermissionStatus.granted) {
          print('🎵 Dashboard: Bluetooth scan permission granted');
          _isBluetoothScanPermissionGranted = true;

          // Mark permission flow as completed
          _permissionFlowCompleted = true;
          _permissionFlowInProgress = false;
          _lastPermissionFlowTime = DateTime.now();

          // Start scanning for devices and show device selection dialog
          await _startDeviceScanning();
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

  void denyBluetoothScanPermission() {
    _showBluetoothScanPermissionDialog = false;
    print('🎵 Dashboard: User denied Bluetooth scan permission');

    // Log denied Bluetooth permission
    _loggingService.sendLogs(
      event: 'BLE Permission',
      status: 'failed',
      notes: 'user_denied',
    );

    notifyListeners();
  }

  // Device selection methods
  Future<void> _startDeviceScanning() async {
    try {
      print('🎵 Dashboard: Starting device scanning...');
      _scannedDevices.clear();
      _selectedDeviceId = '';

      // Start scanning
      await _bluetoothService.startScanning();

      // Show device selection dialog immediately
      _showDeviceSelectionDialog = true;

      // Listen to scanned devices and update the list
      _bluetoothService.addListener(() {
        _scannedDevices = _bluetoothService.scannedDevices
            .map(
              (device) => {
                'id': device.remoteId.toString(),
                'name': device.platformName.isNotEmpty
                    ? device.platformName
                    : device.remoteId.toString(),
                'signalStrength': _bluetoothService.getDeviceRssi(
                  device,
                ), // Use actual RSSI from device
                'isConnected': false,
              },
            )
            .toList();
        notifyListeners();
      });
    } catch (e) {
      print('🎵 Dashboard: Error starting device scanning: $e');
    }
    notifyListeners();
  }

  void selectDevice(String deviceId, String deviceName) {
    _selectedDeviceId = deviceId;
    print('🎵 Dashboard: Selected device: $deviceName ($deviceId)');
    notifyListeners();
  }

  Future<void> connectToSelectedDevice() async {
    if (_selectedDeviceId.isEmpty) return;

    try {
      print('🎵 Dashboard: Connecting to selected device: $_selectedDeviceId');
      _showDeviceSelectionDialog = false;

      // Find the selected device and connect
      final selectedDevice = _bluetoothService.scannedDevices.firstWhere(
        (device) => device.remoteId.toString() == _selectedDeviceId,
      );

      // Connect to the device
      await _bluetoothService.connectToDevice(selectedDevice);
    } catch (e) {
      print('🎵 Dashboard: Error connecting to selected device: $e');
    }
    notifyListeners();
  }

  void closeDeviceSelectionDialog() {
    _showDeviceSelectionDialog = false;
    _selectedDeviceId = '';
    print('🎵 Dashboard: Device selection dialog closed');
    notifyListeners();
  }

  // Unknown device dialog methods
  void closeUnknownDeviceDialog() {
    _showUnknownDeviceDialog = false;
    _unknownDevices.clear();
    _selectedUnknownDevice = null;
    _unknownDeviceBottomSheetShown = false; // Reset bottom sheet flag
    // Reset connection states
    _selectedDeviceIds.clear();
    _isConnecting = false;
    _connectionSuccessful = false;
    _showTroubleshootingScreen = false; // Reset troubleshooting screen state
    // Record close time for debouncing
    _lastBottomSheetCloseTime = DateTime.now();
    print('🎵 Dashboard: Unknown device dialog closed');
    notifyListeners();
  }

  // Flag to prevent showing unknown device dialog after OTP dialog is closed
  bool _otpDialogClosed = false;

  // Flag to prevent multiple simultaneous calls to _attemptAutoConnection
  bool _isAutoConnectionRunning = false;

  // Flag to prevent multiple unknown device bottom sheets
  bool _unknownDeviceBottomSheetShown = false;

  // Flag to prevent multiple OTP confirmation bottom sheets
  bool _otpBottomSheetShown = false;

  // OTP verification state
  bool _isVerifyingOtp = false;
  String? _otpVerificationMessage;

  void selectUnknownDevice(Map<String, dynamic> device) {
    _selectedUnknownDevice = device;
    _showOtpConfirmationDialog = true;
    _otpCode = '';
    _otpDialogClosed = false; // Reset flag when selecting device
    _otpBottomSheetShown = false; // Reset flag when showing new OTP dialog
    // Keep the unknown device dialog visible - don't change its state
    print(
      '🎵 Dashboard: Selected unknown device for OTP verification: ${device['name']}',
    );
    notifyListeners();
  }

  // New methods for device selection with checkboxes
  void toggleDeviceSelection(String deviceId) {
    if (_selectedDeviceIds.contains(deviceId)) {
      _selectedDeviceIds.remove(deviceId);
    } else {
      _selectedDeviceIds.add(deviceId);
    }
    print(
      '🎵 Dashboard: Toggled device selection: $deviceId, Selected: $_selectedDeviceIds',
    );
    notifyListeners();
  }

  bool isDeviceSelected(String deviceId) {
    return _selectedDeviceIds.contains(deviceId);
  }

  Future<void> connectToSelectedDevices() async {
    if (_selectedDeviceIds.isEmpty) return;

    try {
      _isConnecting = true;
      _connectionSuccessful = false;
      notifyListeners();

      print(
        '🎵 Dashboard: Connecting to selected devices: $_selectedDeviceIds',
      );

      // Connect to the first selected device (for now, connect to one device)
      final selectedDeviceId = _selectedDeviceIds.first;

      // Find the selected device from unknown devices
      final selectedDeviceData = _unknownDevices.firstWhere(
        (device) => device['id'] == selectedDeviceId,
      );

      // Get the actual BluetoothDevice from the device data
      final bluetoothDevice = selectedDeviceData['device'];

      if (bluetoothDevice != null) {
        // First, map the device to user account using API
        print('🎵 Dashboard: Mapping device to user account...');

        // Get user ID from SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        final userId = prefs.getString('user_id') ?? '';

        if (userId.isEmpty) {
          throw Exception('User ID not found');
        }

        // Get the actual MAC address from the Bluetooth device
        final bluetoothDevice =
            selectedDeviceData['device'] as ble.BluetoothDevice;
        final macAddress = bluetoothDevice.remoteId.toString();

        // Create device mapping request
        final mappingRequest = DeviceMappingRequest(
          userid: userId,
          maddress: macAddress, // Use actual MAC address from Bluetooth device
        );

        print(
          '🎵 Dashboard: Device mapping request - UserID: $userId, MAC: ${mappingRequest.maddress}',
        );

        // Call device mapping API
        final mappingResult = await _mapDeviceWithoutOtpUseCase(mappingRequest);

        await mappingResult.fold(
          (error) {
            print('🎵 Dashboard: Device mapping failed: $error');
            // Set pending error to be handled by UI
            _pendingDeviceMappingError = error;
            notifyListeners();
            throw Exception('Device mapping failed: $error');
          },
          (response) {
            print(
              '🎵 Dashboard: Device mapped successfully: ${response.message}',
            );
            return Future.value();
          },
        );

        // After successful mapping, connect to the device
        print('🎵 Dashboard: Connecting to mapped device...');
        await _bluetoothService.connectToDeviceWithoutCommandSequence(
          bluetoothDevice,
        );

        // Wait for connection to complete
        int attempts = 0;
        const maxAttempts = 10;

        while (attempts < maxAttempts && !_bluetoothService.isConnected) {
          await Future.delayed(const Duration(milliseconds: 500));
          attempts++;
        }

        if (_bluetoothService.isConnected) {
          _isConnecting = false;
          _connectionSuccessful = true;
          print(
            '🎵 Dashboard: Successfully connected to mapped device: $selectedDeviceId',
          );
        } else {
          throw Exception('Connection timeout');
        }
      } else {
        throw Exception('Device not found');
      }

      notifyListeners();

      // Don't close the bottom sheet - show success UI instead
      // The success UI will be shown in the bottom sheet
    } catch (e) {
      _isConnecting = false;
      _connectionSuccessful = false;
      print('🎵 Dashboard: Error connecting to devices: $e');
      notifyListeners();
    }
  }

  // Troubleshooting screen methods
  void openTroubleshootingScreen() {
    _showTroubleshootingScreen = true;
    notifyListeners();
  }

  void closeTroubleshootingScreen() {
    _showTroubleshootingScreen = false;
    notifyListeners();
  }

  // Device mapping error handling
  void _showDeviceMappingError(String errorMessage, {BuildContext? context}) {
    // Close the bottom sheet if context is provided and we can pop
    if (context != null && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }

    // Store error message for display
    _deviceMappingError = errorMessage;
    _showDeviceMappingErrorDialog = true;
    notifyListeners();
  }

  void closeDeviceMappingErrorDialog() {
    _showDeviceMappingErrorDialog = false;
    _deviceMappingError = '';
    notifyListeners();
  }

  // Public method to show device mapping error with context
  void showDeviceMappingErrorWithContext(
    String errorMessage,
    BuildContext context,
  ) {
    _showDeviceMappingError(errorMessage, context: context);
  }

  // Clear pending device mapping error
  void clearPendingDeviceMappingError() {
    _pendingDeviceMappingError = null;
    notifyListeners();
  }

  // Check if we should show the bottom sheet (considering debounce)
  bool _shouldShowBottomSheet() {
    if (_lastBottomSheetCloseTime == null) {
      return true;
    }

    final timeSinceClose = DateTime.now().difference(
      _lastBottomSheetCloseTime!,
    );
    return timeSinceClose > _bottomSheetDebounceDuration;
  }

  void closeOtpConfirmationDialog() {
    print('🎵 Dashboard: Closing OTP confirmation dialog');
    print(
      '🎵 Dashboard: Current state - showOtpConfirmationDialog: $_showOtpConfirmationDialog, showUnknownDeviceDialog: $_showUnknownDeviceDialog, otpDialogClosed: $_otpDialogClosed',
    );
    _showOtpConfirmationDialog = false;
    _selectedUnknownDevice = null;
    _otpCode = '';
    _otpBottomSheetShown = false; // Reset flag when closing OTP dialog
    // Don't automatically restore unknown device dialog - let it remain as is
    _otpDialogClosed = true;
    print('🎵 Dashboard: OTP confirmation dialog closed');
    print(
      '🎵 Dashboard: New state - showOtpConfirmationDialog: $_showOtpConfirmationDialog, showUnknownDeviceDialog: $_showUnknownDeviceDialog, otpDialogClosed: $_otpDialogClosed',
    );
    notifyListeners();
  }

  // Method to properly close unknown device dialog and dismiss modal
  void closeUnknownDeviceDialogAndDismiss() {
    print('🎵 Dashboard: Closing unknown device dialog and dismissing modal');
    _showUnknownDeviceDialog = false;
    _unknownDevices.clear();
    _selectedUnknownDevice = null;
    _unknownDeviceBottomSheetShown = false; // Reset flag when closing dialog
    notifyListeners();
  }

  void updateOtpCode(String code) {
    _otpCode = code;
    // Don't call notifyListeners() here to avoid rebuilds during typing
    notifyListeners(); // Call notifyListeners to update UI
  }

  Future<bool> verifyOtpAndAddDevice() async {
    if (_selectedUnknownDevice == null || _otpCode.isEmpty) {
      print('🎵 Dashboard: Cannot verify OTP - missing device or OTP code');
      _otpVerificationMessage = 'Please enter OTP code';
      notifyListeners();
      return false;
    }

    _isVerifyingOtp = true;
    _otpVerificationMessage = null;
    notifyListeners();

    try {
      print(
        '🎵 Dashboard: Verifying OTP for device: ${_selectedUnknownDevice!['name']}',
      );

      // Get user email from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final userEmail = prefs.getString('user_email_id') ?? '';

      if (userEmail.isEmpty) {
        print('🎵 Dashboard: No user email found for OTP verification');
        _otpVerificationMessage = 'User email not found';
        _isVerifyingOtp = false;
        notifyListeners();
        return false;
      }

      // Verify OTP
      final result = await _verifyOtpUseCase(userEmail, _otpCode);

      result.fold(
        (error) {
          print('🎵 Dashboard: OTP verification failed: $error');
          _otpVerificationMessage = 'OTP verification failed: $error';
          _isVerifyingOtp = false;

          // Log failed OTP verification
          _loggingService.sendLogs(
            event: 'Device OTP Verification',
            status: 'failed',
            notes: 'Device: ${_selectedUnknownDevice!['name']}, Error: $error',
          );

          notifyListeners();
        },
        (success) async {
          if (success) {
            print('🎵 Dashboard: OTP verification successful');

            // Log successful OTP verification
            _loggingService.sendLogs(
              event: 'Device OTP Verification',
              status: 'success',
              notes: 'Device: ${_selectedUnknownDevice!['name']}',
            );

            // Close OTP dialog
            closeOtpConfirmationDialog();

            // Close unknown device dialog
            closeUnknownDeviceDialog();

            // Reload user data to get updated device list
            await _loadUserData();

            // Update Bluetooth service with refreshed device list
            _bluetoothService.setUserDevices(_userDevices);

            // Re-set callback for unknown devices (in case it was lost)
            _bluetoothService.setOnUnknownDevicesFoundCallback((
              unknownDevices,
            ) {
              print(
                '🎵 Dashboard: Unknown devices found: ${unknownDevices.length}',
              );
              // Prevent multiple rapid calls and respect debounce period
              if (!_showUnknownDeviceDialog && _shouldShowBottomSheet()) {
                _unknownDevices = unknownDevices;
                _showUnknownDeviceDialog = true;
                _unknownDeviceBottomSheetShown =
                    false; // Reset flag for new dialog
                notifyListeners();
              }
            });

            print(
              '🎵 Dashboard: Updated Bluetooth service with ${_userDevices.length} user devices',
            );

            // Connect to the device
            final bluetoothDevice =
                _selectedUnknownDevice!['device'] as ble.BluetoothDevice;
            await _bluetoothService.connectToDevice(bluetoothDevice);

            print(
              '🎵 Dashboard: Device added to account and connected successfully',
            );

            _otpVerificationMessage =
                'Device added and connected successfully!';
          } else {
            print('🎵 Dashboard: OTP verification failed - invalid OTP');
            _otpVerificationMessage = 'Invalid OTP code';
            _isVerifyingOtp = false;

            // Log failed OTP verification
            _loggingService.sendLogs(
              event: 'Device OTP Verification',
              status: 'failed',
              notes:
                  'Device: ${_selectedUnknownDevice!['name']}, Error: Invalid OTP',
            );
          }
          notifyListeners();
        },
      );
      return result.isRight();
    } catch (e) {
      print('🎵 Dashboard: Error during OTP verification: $e');
      _otpVerificationMessage = 'Error during verification: $e';
      _isVerifyingOtp = false;

      // Log OTP verification error
      await _loggingService.sendLogs(
        event: 'Device OTP Verification',
        status: 'failed',
        notes: 'Device: ${_selectedUnknownDevice!['name']}, Error: $e',
      );

      notifyListeners();
      return false;
    }
  }

  void skipUnknownDevice() {
    print('🎵 Dashboard: Skipping unknown device');
    closeUnknownDeviceDialog();
  }

  Future<void> rescanDevices() async {
    try {
      print('🎵 Dashboard: Rescanning devices...');
      _scannedDevices.clear();
      _selectedDeviceId = '';

      // Restart scanning
      await _bluetoothService.startScanning();
    } catch (e) {
      print('🎵 Dashboard: Error rescanning devices: $e');
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
    if (_bluetoothListener != null) {
      _bluetoothService.removeListener(_bluetoothListener!);
    }
    _bluetoothStateSubscription?.cancel();
    super.dispose();
  }
}
