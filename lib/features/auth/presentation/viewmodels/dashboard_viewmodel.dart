import 'dart:convert';
import 'dart:io';
import 'dart:async';

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
import '../../domain/usecases/verify_otp_usecase.dart';
import '../../domain/usecases/get_all_music_usecase.dart';

class DashboardViewModel extends ChangeNotifier {
  // Static variables to track minimized state
  static bool _isMinimizedFromPlayer = false;
  static String? _minimizedProgramId;

  // Services
  final BluetoothService _bluetoothService = BluetoothService();
  final LoggingService _loggingService = sl<LoggingService>();
  final VerifyOtpUseCase _verifyOtpUseCase = sl<VerifyOtpUseCase>();
  final GetAllMusicUseCase _getAllMusicUseCase = sl<GetAllMusicUseCase>();

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
  late VoidCallback _bluetoothListener;

  // Music data
  List<dynamic> _musicData = []; // User's music data from server
  bool _isLoadingMusic = false; // Track if music data is being loaded

  // Bluetooth state monitoring
  bool _isBluetoothStateMonitoring = false;
  StreamSubscription<ble.BluetoothAdapterState>? _bluetoothStateSubscription;

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

  // Initialize the dashboard
  Future<void> initialize() async {
    print('🎵 Dashboard: initialize() called');
    _isLoading = true;
    notifyListeners();

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
      _unknownDevices = unknownDevices;
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
    _bluetoothService.addListener(_bluetoothListener);

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

  // Load music data from SharedPreferences and fetch if needed
  Future<void> _loadMusicData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Try to load music data from SharedPreferences first
      final musicDataString = prefs.getString('user_music_data');
      if (musicDataString != null && musicDataString.isNotEmpty) {
        final musicData = jsonDecode(musicDataString);
        if (musicData is List && musicData.isNotEmpty) {
          _musicData = musicData;
          print('🎵 Dashboard: Loaded ${musicData.length} music items from SharedPreferences');
          return;
        }
      }

      // If no music data in SharedPreferences, fetch from API
      print('🎵 Dashboard: No music data in SharedPreferences, fetching from API...');
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
        print('🎵 Dashboard: Invalid user ID format for fetching music data: $userIdString');
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
          if (musicData is Map<String, dynamic> && musicData.containsKey('data')) {
            final data = musicData['data'];
            if (data is List && data.isNotEmpty) {
              _musicData = data;
              print('🎵 Dashboard: User has ${data.length} music items');
              
              // Save to SharedPreferences
              _saveMusicDataToPrefs(data);
            } else {
              print('🎵 Dashboard: User has no music items (empty data array)');
              _musicData = [];
            }
          } else {
            print('🎵 Dashboard: Invalid music data format');
            _musicData = [];
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

  // Save music data to SharedPreferences
  Future<void> _saveMusicDataToPrefs(List<dynamic> musicData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final musicDataString = jsonEncode(musicData);
      await prefs.setString('user_music_data', musicDataString);
      print('🎵 Dashboard: Saved ${musicData.length} music items to SharedPreferences');
    } catch (e) {
      print('🎵 Dashboard: Error saving music data to SharedPreferences: $e');
    }
  }

  // Start Bluetooth state monitoring
  Future<void> _startBluetoothStateMonitoring() async {
    if (_isBluetoothStateMonitoring) return;
    
    _isBluetoothStateMonitoring = true;
    print('🎵 Dashboard: Starting Bluetooth state monitoring...');
    
    try {
      _bluetoothStateSubscription = ble.FlutterBluePlus.adapterState.listen((state) {
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
    // Set error message to show on the first card
    _bluetoothService.setErrorMessage('Bluetooth is turned off. Please enable Bluetooth to connect to your device.');
    notifyListeners();
  }

  // Handle Bluetooth turned on
  Future<void> _handleBluetoothTurnedOn() async {
    try {
      // Clear any existing error messages
      _bluetoothService.clearErrorMessage();
      
      // Check if Bluetooth permission exists
      final hasPermission = await _checkBluetoothPermission();
      
      if (hasPermission) {
        print('🎵 Dashboard: Bluetooth permission exists - clearing error and showing scan option');
        // Permission exists, just clear error and show "click here to scan"
        _bluetoothService.setStatusMessage('Click here to scan for devices');
        notifyListeners();
      } else {
        print('🎵 Dashboard: Bluetooth permission missing - requesting permission');
        // Permission doesn't exist, ask for permission
        await _requestBluetoothPermissionAndScan();
      }
    } catch (e) {
      print('🎵 Dashboard: Error handling Bluetooth turned on: $e');
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
      _bluetoothService.setErrorMessage('Error starting scan. Please try again.');
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

      // Check if Bluetooth service is ready
      if (!_bluetoothService.isConnected) {
        print(
          '🎵 Dashboard: Bluetooth service not connected, starting scanning...',
        );

        // Start scanning for devices
        await _bluetoothService.startScanning();

        // Wait a bit for scanning to complete
        await Future.delayed(const Duration(seconds: 12));

        // Check if we found any devices
        if (_bluetoothService.scannedDevices.isNotEmpty) {
          print(
            '🎵 Dashboard: Found ${_bluetoothService.scannedDevices.length} devices during auto-scan',
          );

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
            // Only show unknown devices list dialog if OTP dialog hasn't been closed
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

      // Check if this scanned device matches any of user's registered devices
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

  // Find devices that match user's devices
  List<ble.BluetoothDevice> _findMatchingUserDevices(
    List<ble.BluetoothDevice> scannedDevices,
  ) {
    final matchingDevices = <ble.BluetoothDevice>[];

    for (final scannedDevice in scannedDevices) {
      final deviceName = scannedDevice.platformName.toLowerCase();

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
      if (!_showUnknownDeviceDialog &&
          !_showDeviceSelectionDialog &&
          !_showOtpConfirmationDialog) {
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
      '🎵 Dashboard: isBluetoothEnabled=$_isBluetoothEnabled, dialogShown=$_bluetoothDialogShown, scanPermissionGranted=$_isBluetoothScanPermissionGranted, statusChecked=$_bluetoothStatusChecked, permissionFlowInitiated=$_permissionFlowInitiated',
    );

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
      print(
        '🎵 Dashboard: Location permission check result: $hasLocationPermission, dialogShown: $_locationPermissionDialogShown',
      );
      if (!hasLocationPermission && !_locationPermissionDialogShown) {
        print('🎵 Dashboard: Showing location permission dialog first');
        _locationPermissionDialogShown = true; // Prevent multiple requests
        _permissionFlowInitiated = true; // Mark permission flow as initiated
        _showLocationPermissionDialog = true; // Show location permission dialog
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
            '🎵 Dashboard: Location permission granted, showing Bluetooth permission dialog',
          );
          _bluetoothScanPermissionDialogShown =
              true; // Prevent multiple requests
          _showBluetoothScanPermissionDialog = true; // Show custom dialog first
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
      print('🎵 Dashboard: Already connected to Bluetooth device');
    }
  }

  /// Start automatic device scanning when both permissions are granted
  Future<void> startAutomaticDeviceScanning() async {
    print('🎵 Dashboard: Starting automatic device scanning after permissions granted...');
    
    // Mark permissions as granted
    _isLocationPermissionGranted = true;
    _isBluetoothScanPermissionGranted = true;
    
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
              _unknownDevices = unknownDevices;
              _showUnknownDeviceDialog = true;
              _unknownDeviceBottomSheetShown =
                  false; // Reset flag for new dialog
              notifyListeners();
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
    _bluetoothService.removeListener(_bluetoothListener);
    _bluetoothStateSubscription?.cancel();
    super.dispose();
  }
}
