import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/services/native_bluetooth_service.dart';

class DevicesViewModel extends ChangeNotifier {
  // State variables
  bool _isBluetoothEnabled = false;
  bool _isBluetoothScanPermissionGranted = false;
  bool _isScanning = false;
  bool _isConnecting = false;
  bool _isDeviceConnected = false;
  List<Map<String, dynamic>> _nearbyDevices = [];
  String _selectedDeviceId = '';
  String _userName =
      'Jane Doe'; // Default name, can be passed from previous screen

  // Getters
  bool get isBluetoothEnabled => _isBluetoothEnabled;
  bool get isBluetoothScanPermissionGranted =>
      _isBluetoothScanPermissionGranted;
  bool get isScanning => _isScanning;
  bool get isConnecting => _isConnecting;
  bool get isDeviceConnected => _isDeviceConnected;
  List<Map<String, dynamic>> get nearbyDevices => _nearbyDevices;
  String get selectedDeviceId => _selectedDeviceId;
  String get userName => _userName;

  // Bluetooth enable dialog
  bool _showBluetoothEnableDialog = false;
  bool _bluetoothDialogShown = false; // Flag to prevent multiple dialogs
  bool _bluetoothStatusChecked =
      false; // Flag to track if we've checked Bluetooth status
  bool _permissionFlowInitiated =
      false; // Flag to prevent multiple permission flow calls
  bool _bluetoothPermissionPermanentlyDenied =
      false; // Flag to track permanently denied Bluetooth permission
  bool get showBluetoothEnableDialog => _showBluetoothEnableDialog;

  // Bluetooth scan permission dialog
  bool _showBluetoothScanPermissionDialog = false;
  bool _bluetoothScanPermissionDialogShown =
      false; // Flag to prevent multiple dialogs
  bool get showBluetoothScanPermissionDialog =>
      _showBluetoothScanPermissionDialog;

  // Bluetooth permission error dialog
  bool _showBluetoothPermissionErrorDialog = false;
  bool get showBluetoothPermissionErrorDialog =>
      _showBluetoothPermissionErrorDialog;

  // BLE scanning subscriptions
  StreamSubscription<List<ScanResult>>? _scanResultsSubscription;
  StreamSubscription<bool>? _isScanningSubscription;

  // Location permission dialog
  bool _locationPermissionDialogShown =
      false; // Flag to prevent multiple dialogs

  // Location permission error dialog
  bool _showLocationPermissionErrorDialog = false;
  bool get showLocationPermissionErrorDialog =>
      _showLocationPermissionErrorDialog;

  // Device activated dialog
  bool _showDeviceActivatedDialog = false;
  bool _deviceActivatedDialogShown = false; // Flag to prevent multiple dialogs
  bool get showDeviceActivatedDialog => _showDeviceActivatedDialog;

  // Device connection flow states
  int _connectionStep = 0; // 0: device selection, 1: connecting, 2: loading
  bool _isDeviceSelected = false;
  String _selectedDeviceName = '';
  int _batteryLevel = 0;
  double _connectionProgress = 0.0;

  int get connectionStep => _connectionStep;
  bool get isDeviceSelected => _isDeviceSelected;
  String get selectedDeviceName => _selectedDeviceName;
  int get batteryLevel => _batteryLevel;
  double get connectionProgress => _connectionProgress;

  // Device connection flow methods
  void selectDevice(String deviceId, [String? deviceName]) {
    _selectedDeviceId = deviceId;
    if (deviceName != null) {
      _selectedDeviceName = deviceName;
    } else if (deviceId.isNotEmpty) {
      // Find device name from nearby devices
      final device = _nearbyDevices.firstWhere(
        (d) => d['id'] == deviceId,
        orElse: () => {'name': 'Unknown Device'},
      );
      _selectedDeviceName = device['name'];
    } else {
      _selectedDeviceName = '';
    }
    _isDeviceSelected = deviceId.isNotEmpty;
    notifyListeners();
  }

  void startConnection() {
    _connectionStep = 1; // Move to connecting step
    notifyListeners();

    // Simulate connection process
    _simulateConnection();
  }

  void _simulateConnection() async {
    // Simulate connection delay
    await Future.delayed(const Duration(seconds: 2));

    _connectionStep = 2; // Move to loading step
    _batteryLevel = 80; // Simulate battery level
    _connectionProgress = 0.0;
    notifyListeners();

    // Simulate loading progress
    _simulateLoading();
  }

  void _simulateLoading() async {
    for (int i = 0; i <= 100; i += 2) {
      await Future.delayed(const Duration(milliseconds: 50));
      _connectionProgress = i / 100.0;
      notifyListeners();
    }

    // Connection complete
    _isDeviceConnected = true;
    _connectionStep = 0; // Reset to initial state
    notifyListeners();
  }

  void resetConnectionFlow() {
    _connectionStep = 0;
    _isDeviceSelected = false;
    _selectedDeviceName = '';
    _batteryLevel = 0;
    _connectionProgress = 0.0;
    notifyListeners();
  }

  void startDeviceConnectionFlow() {
    _connectionStep = 0; // Start with device selection
    _isDeviceSelected = false;
    _selectedDeviceName = '';
    notifyListeners();
  }

  // Initialize the screen
  bool _isInitialized = false;

  Future<void> initialize() async {
    // Prevent multiple initializations
    if (_isInitialized) {
      print('DevicesViewModel already initialized, skipping');
      return;
    }

    print('Initializing DevicesViewModel...');
    _isInitialized = true;
    
    // Use native Bluetooth service for iOS or when forced
    if (shouldUseNativeBluetooth || _forceNativeBluetooth) {
      print('Using native Bluetooth service for iOS');
      await startDeviceConnectionWithNative();
      return;
    }

    await _checkBluetoothStatus();

    // Listen to Bluetooth state changes
    _listenToBluetoothStateChanges();

    // Auto-start the device connection flow with a longer delay to ensure Bluetooth is properly initialized
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (!_permissionFlowInitiated) {
        // Check flag before calling
        startDeviceConnection();
      }
    });
  }

  // Check if we should show permission dialog on screen load
  void checkPermissionOnLoad() async {
    // This method is no longer needed as startDeviceConnection() handles all permission checking
    // Keeping it empty to avoid breaking the view
  }

  // Listen to Bluetooth state changes
  void _listenToBluetoothStateChanges() {
    if (Platform.isAndroid || Platform.isIOS) {
      FlutterBluePlus.adapterState.listen((BluetoothAdapterState state) {
        print('Bluetooth adapter state changed: $state');
        if (state == BluetoothAdapterState.on) {
          _isBluetoothEnabled = true;
          _bluetoothDialogShown =
              false; // Reset dialog flag when Bluetooth is enabled

          // If Bluetooth was just enabled and we're not already in a permission flow, start the flow
          if (!_permissionFlowInitiated) {
            Future.delayed(const Duration(milliseconds: 500), () {
              startDeviceConnection(); // Use the main permission checking logic
            });
          }

          notifyListeners();
        } else if (state == BluetoothAdapterState.off) {
          _isBluetoothEnabled = false;
          notifyListeners();
        } else if (state == BluetoothAdapterState.unknown) {
          // When state is unknown, wait a bit and check again
          print('Bluetooth adapter state unknown, checking status...');
          Future.delayed(const Duration(milliseconds: 1000), () async {
            bool isOn = await FlutterBluePlus.isOn;
            print('Bluetooth status after unknown state: isOn=$isOn');
            if (isOn && !_isBluetoothEnabled) {
              _isBluetoothEnabled = true;
              _bluetoothDialogShown = false;
              notifyListeners();

              // Start permission flow if not already initiated
              if (!_permissionFlowInitiated) {
                Future.delayed(const Duration(milliseconds: 500), () {
                  startDeviceConnection();
                });
              }
            }
          });
        }
      });
    }
  }

  // Check if Bluetooth is enabled
  Future<void> _checkBluetoothStatus() async {
    try {
      // Check if Bluetooth is available and enabled
      if (Platform.isAndroid || Platform.isIOS) {
        // Check if Bluetooth adapter is available
        if (await FlutterBluePlus.isSupported) {
          if (Platform.isAndroid) {
            // For Android, use the standard approach
            await Future.delayed(const Duration(milliseconds: 200));
            _isBluetoothEnabled = await FlutterBluePlus.isOn;
            print(
              'Android Bluetooth status check: isSupported=true, isOn=$_isBluetoothEnabled',
            );

            if (!_isBluetoothEnabled) {
              print(
                'Android Bluetooth appears off, waiting for adapter state...',
              );
              await Future.delayed(const Duration(milliseconds: 500));
              _isBluetoothEnabled = await FlutterBluePlus.isOn;
              print(
                'Android Bluetooth status recheck: isOn=$_isBluetoothEnabled',
              );
            }
          } else if (Platform.isIOS) {
            // For iOS, handle unknown adapter state like the reference code
            print(
              'iOS: Starting Bluetooth status check with unknown state handling',
            );

            // Start listening to adapter state changes immediately
            _listenToBluetoothStateChanges();

            // Try to get the current state
            await Future.delayed(const Duration(milliseconds: 200));
            _isBluetoothEnabled = await FlutterBluePlus.isOn;
            print(
              'iOS Bluetooth status check: isSupported=true, isOn=$_isBluetoothEnabled',
            );

            // If we can't determine the state, assume it's enabled and proceed
            // The scanning will reveal the actual state
            if (!_isBluetoothEnabled) {
              print(
                'iOS: Bluetooth state unclear, proceeding with permission flow (scanning will reveal actual state)',
              );
              _isBluetoothEnabled = true; // Assume enabled for now
            }
          }
        } else {
          // If Bluetooth is not supported, assume it's enabled to avoid showing dialog unnecessarily
          _isBluetoothEnabled = true;
          print('Bluetooth status check: isSupported=false, assuming enabled');
        }
      } else {
        _isBluetoothEnabled = false; // Other platforms disabled
        print('Bluetooth status check: Platform not supported');
      }
    } catch (e) {
      // If there's an error checking Bluetooth status, assume it's enabled to avoid showing dialog unnecessarily
      _isBluetoothEnabled = true;
      print('Error checking Bluetooth status: $e, assuming enabled');
    }

    _bluetoothStatusChecked = true; // Mark that we've checked the status
    notifyListeners();

    // After status check is complete, start the device connection flow if Bluetooth is enabled
    if (_isBluetoothEnabled && !_permissionFlowInitiated) {
      print('Bluetooth status check complete, starting device connection flow');
      Future.delayed(const Duration(milliseconds: 200), () {
        startDeviceConnection();
      });
    }
  }

  // Start the device connection flow
  void startDeviceConnection() async {
    print(
      'startDeviceConnection called: isBluetoothEnabled=$_isBluetoothEnabled, dialogShown=$_bluetoothDialogShown, scanPermissionGranted=$_isBluetoothScanPermissionGranted, statusChecked=$_bluetoothStatusChecked, permissionFlowInitiated=$_permissionFlowInitiated',
    );

    // Prevent multiple permission flow calls
    if (_permissionFlowInitiated) {
      print('Permission flow already initiated, skipping');
      return;
    }

    // Only show Bluetooth enable dialog if we've checked the status and confirmed it's disabled
    if (!_isBluetoothEnabled &&
        !_bluetoothDialogShown &&
        _bluetoothStatusChecked) {
      print('Showing Bluetooth enable dialog');
      _showBluetoothEnableDialog = true;
      _bluetoothDialogShown = true; // Prevent multiple dialogs
      _permissionFlowInitiated = true; // Mark permission flow as initiated
    } else if (_isBluetoothEnabled && _bluetoothStatusChecked) {
      _permissionFlowInitiated = true; // Mark permission flow as initiated

      // Check if location permission is already granted first
      bool hasLocationPermission = await _checkLocationPermission();
      print(
        'Location permission check result: $hasLocationPermission, dialogShown: $_locationPermissionDialogShown',
      );
      if (!hasLocationPermission && !_locationPermissionDialogShown) {
        print('Showing location permission dialog first');
        _locationPermissionDialogShown = true; // Prevent multiple requests
      } else if (hasLocationPermission) {
        // Location permission granted, check BLE scan permission
        bool hasBluetoothPermission = await _checkBluetoothScanPermission();
        print(
          'Bluetooth permission check result: $hasBluetoothPermission, dialogShown: $_bluetoothScanPermissionDialogShown',
        );

        if (hasBluetoothPermission) {
          print('All permissions already granted, starting scanning directly');
          _isBluetoothScanPermissionGranted = true;
          _startScanning();
        } else if (!_bluetoothScanPermissionDialogShown) {
          print(
            'Location permission granted, showing Bluetooth permission dialog',
          );
          _bluetoothScanPermissionDialogShown =
              true; // Prevent multiple requests
          _showBluetoothScanPermissionDialog = true; // Show custom dialog first
        }
      }
    } else if (!_bluetoothStatusChecked) {
      print(
        'Bluetooth status not yet checked, waiting for status check to complete...',
      );
      // Don't recursively call startDeviceConnection - let the status check complete
      // The Bluetooth state listener will handle starting the flow when status is ready
    } else {
      print('No action taken - conditions not met');
    }
    notifyListeners();
  }

  // Handle Bluetooth enable OK - navigate to settings
  void handleBluetoothEnableOk() {
    _showBluetoothEnableDialog = false;

    if (Platform.isAndroid) {
      // Open Android Bluetooth settings
      _openAndroidBluetoothSettings();
    } else if (Platform.isIOS) {
      // Open iOS Settings app
      _openIOSSettings();
    } else {
      // For other platforms, simulate enabling Bluetooth
      _simulateBluetoothEnabled();
    }

    notifyListeners();
  }

  // Recheck Bluetooth status when returning from settings
  Future<void> recheckBluetoothStatus() async {
    await _checkBluetoothStatus();
    // If Bluetooth is now enabled, proceed with the flow
    if (_isBluetoothEnabled) {
      _bluetoothDialogShown = false; // Reset flag

      // If Bluetooth was just enabled and we're not already in a permission flow, proceed to permission check
      if (!_isBluetoothScanPermissionGranted && !_permissionFlowInitiated) {
        print(
          'Bluetooth enabled after settings, proceeding to permission check',
        );
        Future.delayed(const Duration(milliseconds: 500), () {
          startDeviceConnection(); // Use the main permission flow
        });
      } else if (_isBluetoothScanPermissionGranted) {
        // If permission is already granted, start scanning
        Future.delayed(const Duration(milliseconds: 500), () {
          _startScanning();
        });
      }
    }
  }

  // Open Android Bluetooth settings
  void _openAndroidBluetoothSettings() {
    // In real implementation, this would use platform channels to open Bluetooth settings
    // For now, simulate opening settings and then rechecking Bluetooth status
    Future.delayed(const Duration(seconds: 2), () {
      recheckBluetoothStatus();
    });
  }

  // Open iOS Settings app
  void _openIOSSettings() {
    // In real implementation, this would use platform channels to open Settings
    // For now, simulate opening settings and then rechecking Bluetooth status
    Future.delayed(const Duration(seconds: 2), () {
      recheckBluetoothStatus();
    });
  }

  // Simulate Bluetooth being enabled
  void _simulateBluetoothEnabled() {
    _isBluetoothEnabled = true;
    // After enabling, check for scan permission
    Future.delayed(const Duration(seconds: 1), () {
      if (!_isBluetoothScanPermissionGranted) {
        _showBluetoothScanPermissionDialog = true;
        notifyListeners();
      } else {
        _startScanning();
      }
    });
  }

  // Handle Bluetooth scan permission allow - show system dialog after custom dialog
  Future<void> allowBluetoothScanPermission() async {
    _showBluetoothScanPermissionDialog = false;
    print(
      'User allowed Bluetooth permission in custom dialog, requesting system permission',
    );
    await _requestBluetoothPermissionDirectly();
  }

  // Handle location permission allow - show system dialog after custom dialog
  Future<void> allowLocationPermission() async {
    print(
      'User allowed location permission in custom dialog, requesting system permission',
    );
    await _requestLocationPermissionDirectly();
  }

  // Handle location permission error dialog OK
  void handleLocationPermissionErrorOk() {
    _showLocationPermissionErrorDialog = false;
    notifyListeners();
  }

  // Open app settings
  Future<void> openDeviceSettings() async {
    try {
      await openAppSettings();
      print('Opened app settings');
    } catch (e) {
      print('Error opening app settings: $e');
    }
  }

  // Check if Bluetooth scan permission is already granted
  Future<bool> _checkBluetoothScanPermission() async {
    try {
      if (Platform.isAndroid) {
        final status = await Permission.bluetoothScan.status;
        print('Android Bluetooth scan permission status: $status');
        _isBluetoothScanPermissionGranted = status.isGranted;
        return status.isGranted;
      } else if (Platform.isIOS) {
        final status = await Permission.bluetooth.status;
        print('iOS Bluetooth permission status: $status');

        // For iOS, permission status can be unreliable, so we test with actual scan attempt
        if (status.isGranted) {
          try {
            // Try a quick scan test to verify permission is actually working
            await FlutterBluePlus.startScan(
              timeout: const Duration(seconds: 1),
            );
            await FlutterBluePlus.stopScan();
            print('iOS: Bluetooth permission verified by successful scan test');
            _isBluetoothScanPermissionGranted = true;
            return true;
          } catch (e) {
            print('iOS: Bluetooth permission test failed: $e');
            _isBluetoothScanPermissionGranted = false;
            return false;
          }
        } else if (status.isPermanentlyDenied) {
          // Even if status shows permanentlyDenied, test with actual scan
          try {
            await FlutterBluePlus.startScan(
              timeout: const Duration(seconds: 1),
            );
            await FlutterBluePlus.stopScan();
            print(
              'iOS: Bluetooth permission actually granted despite status showing permanentlyDenied',
            );
            _isBluetoothScanPermissionGranted = true;
            return true;
          } catch (e) {
            print('iOS: Bluetooth permission actually denied: $e');
            _isBluetoothScanPermissionGranted = false;
            return false;
          }
        } else {
          _isBluetoothScanPermissionGranted = status.isGranted;
          return status.isGranted;
        }
      } else {
        _isBluetoothScanPermissionGranted = true; // Other platforms
        return true;
      }
    } catch (e) {
      print('Error checking Bluetooth scan permission: $e');
      return false;
    }
  }

  // Check if location permission is already granted
  Future<bool> _checkLocationPermission() async {
    try {
      print('Checking location permission...');
      LocationPermission permission = await Geolocator.checkPermission();
      print('Location permission status: $permission');
      return permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always;
    } catch (e) {
      print('Error checking location permission: $e');
      return false;
    }
  }

  // Request location permission directly (shows system dialog)
  Future<void> _requestLocationPermissionDirectly() async {
    try {
      print('Requesting location permission from system...');
      print(
        'Platform: ${Platform.isIOS
            ? "iOS"
            : Platform.isAndroid
            ? "Android"
            : "Other"}',
      );

      LocationPermission permission = await Geolocator.requestPermission();
      print('Location permission request result: $permission');

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        print('Location permission granted by system');
        // Location permission granted, now check BLE scan permission
        bool hasBluetoothPermission = await _checkBluetoothScanPermission();
        print(
          'Bluetooth permission check result: $hasBluetoothPermission, dialogShown: $_bluetoothScanPermissionDialogShown, permanentlyDenied: $_bluetoothPermissionPermanentlyDenied',
        );

        if (hasBluetoothPermission) {
          print('All permissions granted, starting scanning');
          _isBluetoothScanPermissionGranted = true;
          _bluetoothPermissionPermanentlyDenied = false;
          _showBluetoothPermissionErrorDialog = false;
          _startScanning();
        } else if (!_bluetoothScanPermissionDialogShown &&
            !_bluetoothPermissionPermanentlyDenied) {
          print(
            'Location permission granted, showing Bluetooth permission dialog',
          );
          _bluetoothScanPermissionDialogShown = true;
          _showBluetoothScanPermissionDialog = true; // Show custom dialog first
        } else if (_bluetoothPermissionPermanentlyDenied) {
          print(
            'Bluetooth permission permanently denied, showing error dialog',
          );
          _showBluetoothPermissionErrorDialog = true;
        }
      } else if (permission == LocationPermission.deniedForever) {
        print(
          'Location permission permanently denied by system, showing error dialog',
        );
        _showLocationPermissionErrorDialog = true;
        // Don't reset permission flow flag for permanent denial - user needs to go to settings
      } else {
        print('Location permission denied by system, showing error dialog');
        _showLocationPermissionErrorDialog = true;
        // Reset permission flow flag to allow retry for temporary denial
        _permissionFlowInitiated = false;
      }
    } catch (e) {
      print('Error requesting location permission: $e');
      _showLocationPermissionErrorDialog = true;
      _permissionFlowInitiated = false;
    }
    notifyListeners();
  }

  // Request Bluetooth permission directly (shows system dialog)
  Future<void> _requestBluetoothPermissionDirectly() async {
    try {
      print('Requesting Bluetooth permission from system...');

      PermissionStatus status;
      if (Platform.isAndroid) {
        status = await Permission.bluetoothScan.request();
      } else if (Platform.isIOS) {
        status = await Permission.bluetooth.request();
      } else {
        status = PermissionStatus.granted; // Other platforms
      }

      print('Bluetooth permission request result: $status');

      if (status.isGranted) {
        print('Bluetooth permission granted by system');
        _isBluetoothScanPermissionGranted = true;
        _startScanning();
      } else if (status.isPermanentlyDenied) {
        // For iOS, even if status shows permanentlyDenied, try to start scanning
        // iOS permission detection is unreliable, so we test by attempting to scan
        if (Platform.isIOS) {
          print(
            'iOS: Permission status shows permanentlyDenied, but testing with actual scan attempt',
          );
          await _testBluetoothPermissionByScanning();
        } else {
          print('Bluetooth permission permanently denied by system');
          _bluetoothPermissionPermanentlyDenied = true;
          _showBluetoothPermissionErrorDialog = true;
        }
      } else {
        print('Bluetooth permission denied by system');
        // Reset permission flow flag to allow retry for temporary denial
        _permissionFlowInitiated = false;
      }
    } catch (e) {
      print('Error requesting Bluetooth permission: $e');
      _permissionFlowInitiated = false;
    }
    notifyListeners();
  }

  // Test Bluetooth permission by attempting to scan (iOS-specific workaround)
  Future<void> _testBluetoothPermissionByScanning() async {
    try {
      print('iOS: Testing Bluetooth permission by attempting to scan...');

      // Try to start a quick scan to test if permission is actually granted
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 3),
        continuousUpdates: false,
        continuousDivisor: 1,
      );

      // If we get here without error, permission is actually granted
      print('iOS: Scan started successfully - permission is actually granted!');
      await FlutterBluePlus.stopScan();

      _isBluetoothScanPermissionGranted = true;
      _bluetoothPermissionPermanentlyDenied = false;
      _showBluetoothPermissionErrorDialog = false;

      // Start the actual scanning
      _startScanning();
    } catch (e) {
      print('iOS: Scan failed - permission is actually denied: $e');
      _bluetoothPermissionPermanentlyDenied = true;
      _showBluetoothPermissionErrorDialog = true;
    }
  }

  // Start scanning for devices
  void _startScanning() {
    _isScanning = true;
    _nearbyDevices.clear(); // Clear previous results
    notifyListeners();

    // Start real BLE scanning
    _scanForRealEvolv28Devices();
  }

  // Scan for real BLE devices with "evolv28" in name
  void _scanForRealEvolv28Devices() async {
    try {
      print('Starting real BLE scan for Evolv28 devices...');
      print(
        'Platform: ${Platform.isIOS
            ? "iOS"
            : Platform.isAndroid
            ? "Android"
            : "Other"}',
      );

      // Check if Bluetooth is still enabled before scanning
      if (!await FlutterBluePlus.isOn) {
        print('Bluetooth is not enabled, cannot scan');
        _isScanning = false;
        notifyListeners();
        return;
      }

      // Clear previous results
      _nearbyDevices.clear();
      notifyListeners();

      if (Platform.isIOS) {
        // iOS-specific scanning logic
        await _startIOSBLEScan();
      } else {
        // Android scanning logic
        await _startAndroidBLEScan();
      }
    } catch (e) {
      print('Error during BLE scan: $e');
      _isScanning = false;
      notifyListeners();
    }
  }

  // iOS-specific BLE scanning (based on reference code)
  Future<void> _startIOSBLEScan() async {
    try {
      print('Starting iOS BLE scan with unknown adapter state handling...');

      // Start scanning with iOS-specific parameters (like reference code)
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 15),
        continuousUpdates: true,
        continuousDivisor: 1,
      );

      print('iOS BLE scan started successfully');

      // Set up scan results listener immediately (like reference code)
      _scanResultsSubscription = FlutterBluePlus.scanResults.listen((results) {
        print('iOS BLE scan results: ${results.length} devices found');
        _processScanResults(results);
      });

      // Listen to adapter state changes (like reference code)
      FlutterBluePlus.adapterState.listen((state) {
        print('iOS adapter state changed to: $state');
        if (state == BluetoothAdapterState.on) {
          print('iOS: Adapter is now ON, continuing scan');
        } else if (state == BluetoothAdapterState.unknown ||
            state == BluetoothAdapterState.off) {
          print('iOS: Adapter state is $state, continuing scan for 15 seconds');
        }
      });

      // Listen to scan state changes
      _isScanningSubscription = FlutterBluePlus.isScanning.listen((isScanning) {
        print('iOS scan state changed: $isScanning');
        if (!isScanning) {
          print('iOS scanning stopped naturally');
          _isScanning = false;
          _scanResultsSubscription?.cancel();
          _isScanningSubscription?.cancel();
          notifyListeners();
          print('iOS BLE scan completed');
        }
      });

      // Set a 15-second timer to stop scanning and show results (like reference code)
      Timer(const Duration(seconds: 15), () {
        if (_isScanning) {
          print('iOS BLE scan timeout reached (15 seconds), stopping scan');
          FlutterBluePlus.stopScan();
          _isScanning = false;
          _scanResultsSubscription?.cancel();
          _isScanningSubscription?.cancel();
          notifyListeners();

          if (_nearbyDevices.isEmpty) {
            print('iOS: No devices found after 15 seconds');
          }
        }
      });
    } catch (e) {
      print('Error starting iOS BLE scan: $e');
      _isScanning = false;
      notifyListeners();
    }
  }

  // Android-specific BLE scanning
  Future<void> _startAndroidBLEScan() async {
    try {
      print('Starting Android BLE scan...');

      // Start scanning for BLE devices with Android-specific parameters
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 10),
        androidUsesFineLocation: true,
        continuousUpdates: true,
        continuousDivisor: 8,
      );

      print('Android BLE scan started successfully');

      // Set up scan results listener
      _scanResultsSubscription = FlutterBluePlus.scanResults.listen((results) {
        print('Android BLE scan results: ${results.length} devices found');
        _processScanResults(results);
      });

      // Listen to scan state changes
      _isScanningSubscription = FlutterBluePlus.isScanning.listen((isScanning) {
        print('Android scan state changed: $isScanning');
        if (!isScanning) {
          _isScanning = false;
          _scanResultsSubscription?.cancel();
          _isScanningSubscription?.cancel();
          notifyListeners();
          print('Android BLE scan completed');
        }
      });

      // Stop scanning after timeout
      Future.delayed(const Duration(seconds: 10), () {
        FlutterBluePlus.stopScan();
        _isScanning = false;
        notifyListeners();
        print('Android BLE scan completed');
      });
    } catch (e) {
      print('Error starting Android BLE scan: $e');
      _isScanning = false;
      notifyListeners();
    }
  }

  // Process scan results and filter for Evolv28 devices
  void _processScanResults(List<ScanResult> results) {
    for (final result in results) {
      final device = result.device;
      final deviceName = device.platformName.isNotEmpty
          ? device.platformName
          : device.remoteId.toString();

      print('Found device: $deviceName');

      // Check if device contains "evolv28" in name
      if (deviceName.toLowerCase().contains('evolv28')) {
        // Check if device already exists
        final existingIndex = _nearbyDevices.indexWhere(
          (d) => d['id'] == device.remoteId.toString(),
        );

        if (existingIndex >= 0) {
          // Update existing device with new scan result
          _nearbyDevices[existingIndex] = {
            'id': device.remoteId.toString(),
            'name': deviceName,
            'isConnected': false,
            'signalStrength': result.rssi != null
                ? (100 + result.rssi!).clamp(0, 100)
                : 0,
            'device': device,
          };
        } else {
          // Add new device
          _nearbyDevices.add({
            'id': device.remoteId.toString(),
            'name': deviceName,
            'isConnected': false,
            'signalStrength': result.rssi != null
                ? (100 + result.rssi!).clamp(0, 100)
                : 0,
            'device': device,
          });
        }
      }
    }

    // Sort devices by signal strength (strongest first)
    _nearbyDevices.sort(
      (a, b) =>
          (b['signalStrength'] as int).compareTo(a['signalStrength'] as int),
    );

    print('Evolv28 devices found: ${_nearbyDevices.length}');

    // If we found devices, Bluetooth permission is actually working
    if (_nearbyDevices.isNotEmpty && !_isBluetoothScanPermissionGranted) {
      print(
        'Devices found - Bluetooth permission is actually granted, hiding permission dialog',
      );
      _isBluetoothScanPermissionGranted = true;
      _showBluetoothScanPermissionDialog = false;
      _bluetoothScanPermissionDialogShown =
          true; // Prevent dialog from showing again
    }

    notifyListeners();

    // Don't auto-connect - let user select device from list
  }

  // Connect to a specific device
  void connectToDevice(String deviceId) async {
    // Prevent multiple connection attempts
    if (_isConnecting || _deviceActivatedDialogShown) {
      print('Connection already in progress or device already activated');
      return;
    }

    _isConnecting = true;
    _selectedDeviceId = deviceId;
    notifyListeners();

    try {
      // Find the device in our nearby devices list
      final deviceData = _nearbyDevices.firstWhere(
        (device) => device['id'] == deviceId,
        orElse: () => throw Exception('Device not found'),
      );

      final device = deviceData['device'] as BluetoothDevice;
      print('Connecting to device: ${device.platformName}');

      // Connect to the device
      await device.connect();
      print('Connected to device: ${device.platformName}');

      // Update device status
      final deviceIndex = _nearbyDevices.indexWhere((d) => d['id'] == deviceId);
      if (deviceIndex != -1) {
        _nearbyDevices[deviceIndex]['isConnected'] = true;
      }

      _isConnecting = false;
      _isDeviceConnected = true;

      // Only show dialog if it hasn't been shown before
      if (!_deviceActivatedDialogShown) {
        _showDeviceActivatedDialog = true;
        _deviceActivatedDialogShown = true;
      }
      notifyListeners();
    } catch (e) {
      print('Error connecting to device: $e');
      _isConnecting = false;
      notifyListeners();
    }
  }

  // Handle device activated dialog OK
  void handleDeviceActivatedOk() {
    _showDeviceActivatedDialog = false;
    notifyListeners();

    // Navigate to home screen
    // Note: We'll need to pass the context from the view to navigate
    // For now, we'll just close the dialog and let the view handle navigation
  }

  // Try again button
  void tryAgain() {
    print('Try again - restarting permission flow and BLE scan');
    _resetPermissionFlags();
    startDeviceConnection();
  }

  // Reset all permission flags to allow retry
  void _resetPermissionFlags() {
    _permissionFlowInitiated = false;
    _bluetoothDialogShown = false;
    _bluetoothScanPermissionDialogShown = false;
    _locationPermissionDialogShown = false;
    _bluetoothPermissionPermanentlyDenied = false;
    _showBluetoothEnableDialog = false;
    _showBluetoothScanPermissionDialog = false;
    _showBluetoothPermissionErrorDialog = false;
    _showLocationPermissionErrorDialog = false;
    _isInitialized = false; // Allow re-initialization
  }

  // Refresh scan - clear devices and start fresh scan
  Future<void> refreshScan() async {
    print('Refreshing BLE scan...');

    // Stop any ongoing scan first
    if (_isScanning) {
      FlutterBluePlus.stopScan();
      _isScanning = false;
    }

    // Clear all existing devices for a fresh start
    _nearbyDevices.clear();
    notifyListeners();

    // Start a fresh scan
    _startScanning();
  }

  // Can't find device button
  void cantFindDevice() {
    // Handle can't find device action
    // This could show help or support options
  }

  // Handle app lifecycle changes
  void onAppResumed() {
    // Only recheck Bluetooth status if we're not in the middle of a permission flow
    if (!_permissionFlowInitiated) {
      print('App resumed, checking Bluetooth status');
      recheckBluetoothStatus();
    } else {
      print(
        'App resumed, but permission flow is already in progress, skipping recheck',
      );
    }
    // Also check if Bluetooth permission was granted
    _checkBluetoothPermissionAfterSettings();
  }

  // Check if Bluetooth permission was granted after user returns from settings
  Future<void> _checkBluetoothPermissionAfterSettings() async {
    if (_bluetoothPermissionPermanentlyDenied) {
      print('Checking if Bluetooth permission was granted after settings');
      bool hasBluetoothPermission = await _checkBluetoothScanPermission();
      if (hasBluetoothPermission) {
        print('Bluetooth permission granted after settings, starting scan');
        _bluetoothPermissionPermanentlyDenied = false;
        _showBluetoothPermissionErrorDialog = false;
        _isBluetoothScanPermissionGranted = true;
        _startScanning();
      } else {
        print('Bluetooth permission still not granted after settings');
      }
    }
  }

  // Manual method to check Bluetooth status (for debugging)
  Future<void> checkBluetoothStatusManually() async {
    print('Manual Bluetooth status check requested');
    await _checkBluetoothStatus();
  }

  // Manual method to check and reset Bluetooth permission state
  Future<void> checkBluetoothPermissionManually() async {
    print('Manual Bluetooth permission check requested');
    bool hasBluetoothPermission = await _checkBluetoothScanPermission();
    print('Manual Bluetooth permission check result: $hasBluetoothPermission');

    if (hasBluetoothPermission) {
      print(
        'Bluetooth permission is granted, resetting flags and starting scan',
      );
      _bluetoothPermissionPermanentlyDenied = false;
      _showBluetoothPermissionErrorDialog = false;
      _isBluetoothScanPermissionGranted = true;
      _startScanning();
    } else {
      print('Bluetooth permission is not granted');
    }
    notifyListeners();
  }

  // Force refresh permission state and restart scanning
  Future<void> forceRefreshPermissions() async {
    print('Force refreshing permissions...');

    // Reset all permission flags
    _resetPermissionFlags();

    // Check current permission states
    bool hasLocationPermission = await _checkLocationPermission();
    bool hasBluetoothPermission = await _checkBluetoothScanPermission();

    print(
      'Force refresh - Location: $hasLocationPermission, Bluetooth: $hasBluetoothPermission',
    );

    if (hasLocationPermission && hasBluetoothPermission) {
      print('All permissions granted, starting scan');
      _startScanning();
    } else {
      print('Permissions not fully granted, restarting permission flow');
      _permissionFlowInitiated = false;
      startDeviceConnection();
    }

    notifyListeners();
  }

  // iOS-specific method to get BLE devices when adapter state is unknown (based on reference code)
  Future<void> getBLEDevicesWhenAdapterUnknown() async {
    if (Platform.isIOS) {
      print('iOS: Getting BLE devices when adapter state is unknown');
      _isScanning = true;
      _nearbyDevices.clear();
      notifyListeners();

      try {
        // Get devices with 15-second timeout (like reference code)
        List<BluetoothDevice> devices = await getBLEDevicesOnIOS(
          timeout: const Duration(seconds: 15),
        );

        if (devices.isNotEmpty) {
          // Process found devices
          for (var device in devices) {
            if (device.platformName.toLowerCase().contains('evolv28') ||
                device.platformName.toLowerCase().contains('evolv')) {
              _nearbyDevices.add({
                'id': device.remoteId.toString(),
                'name': device.platformName,
                'rssi': -50, // Default RSSI for iOS
                'device': device,
              });
            }
          }
          print(
            'iOS: Successfully found ${_nearbyDevices.length} Evolv28 devices',
          );
        } else {
          print('iOS: No Evolv28 devices found after 15 seconds');
        }
      } catch (e) {
        print('iOS: Error getting BLE devices: $e');
      } finally {
        _isScanning = false;
        notifyListeners();
      }
    }
  }

  // Helper method to get BLE devices on iOS regardless of adapter state (based on reference code)
  Future<List<BluetoothDevice>> getBLEDevicesOnIOS({
    Duration timeout = const Duration(seconds: 15),
  }) async {
    List<BluetoothDevice> devices = [];
    List<ScanResult> scanResults = [];
    StreamSubscription<List<ScanResult>>? scanResultsSubscription;
    StreamSubscription<bool>? isScanningSubscription;

    try {
      print('iOS: Starting BLE device discovery (like reference code)');

      // Start scanning (like reference code)
      await FlutterBluePlus.startScan(
        timeout: timeout,
        continuousUpdates: true,
        continuousDivisor: 1,
      );

      // Listen to scan results immediately (like reference code)
      scanResultsSubscription = FlutterBluePlus.scanResults.listen((results) {
        scanResults = results;
        print('iOS: Found ${results.length} devices during scan');
      });

      // Listen to adapter state changes (like reference code)
      FlutterBluePlus.adapterState.listen((state) {
        print('iOS: Adapter state changed to: $state');
        if (state == BluetoothAdapterState.on) {
          print('iOS: Adapter is now ON, continuing scan');
        } else if (state == BluetoothAdapterState.unknown ||
            state == BluetoothAdapterState.off) {
          print(
            'iOS: Adapter state is $state, continuing scan for ${timeout.inSeconds} seconds',
          );
        }
      });

      // Wait for the timeout (like reference code)
      await Future.delayed(timeout);

      // Stop scanning
      await FlutterBluePlus.stopScan();

      // Extract unique devices
      Set<String> deviceIds = {};
      for (var result in scanResults) {
        if (!deviceIds.contains(result.device.remoteId.toString())) {
          deviceIds.add(result.device.remoteId.toString());
          devices.add(result.device);
        }
      }

      print('iOS: Discovery completed, found ${devices.length} unique devices');
    } catch (e) {
      print('iOS: Error during BLE discovery: $e');
    } finally {
      // Clean up subscriptions
      scanResultsSubscription?.cancel();
      isScanningSubscription?.cancel();
    }

    return devices;
  }

  // Disconnect from a device
  Future<void> disconnectDevice(String deviceId) async {
    try {
      final deviceData = _nearbyDevices.firstWhere(
        (device) => device['id'] == deviceId,
        orElse: () => throw Exception('Device not found'),
      );

      final device = deviceData['device'] as BluetoothDevice;
      await device.disconnect();

      // Update device status
      final deviceIndex = _nearbyDevices.indexWhere((d) => d['id'] == deviceId);
      if (deviceIndex != -1) {
        _nearbyDevices[deviceIndex]['isConnected'] = false;
      }

      _isDeviceConnected = false;
      notifyListeners();
      print('Disconnected from device: ${device.platformName}');
    } catch (e) {
      print('Error disconnecting from device: $e');
    }
  }

  // Stop scanning and cleanup
  // Native Bluetooth Service Methods
  StreamSubscription<Map<String, dynamic>>? _nativeBluetoothStateSubscription;
  StreamSubscription<Map<String, dynamic>>? _nativeDeviceDiscoveredSubscription;
  
  /// Initialize native Bluetooth service
  Future<void> initializeNativeBluetooth() async {
    try {
      await NativeBluetoothService.initialize();
      
      // Listen to Bluetooth state changes
      _nativeBluetoothStateSubscription = NativeBluetoothService.bluetoothStateStream.listen((data) {
        print('Native Bluetooth state changed: ${data['state']}, permission: ${data['permission']}');
        
        final state = data['state'].toString().toNativeBluetoothState();
        final permission = data['permission'].toString().toBluetoothPermissionStatus();
        
        _isBluetoothEnabled = state == NativeBluetoothState.poweredOn;
        _isBluetoothScanPermissionGranted = permission == BluetoothPermissionStatus.granted;
        
        notifyListeners();
      });
      
      // Listen to device discoveries
      _nativeDeviceDiscoveredSubscription = NativeBluetoothService.deviceDiscoveredStream.listen((deviceData) {
        print('Native device discovered: ${deviceData['name']} (${deviceData['id']})');
        
        // Filter only devices with "evolv28" in the name
        final deviceName = deviceData['name'] ?? '';
        if (deviceName.toLowerCase().contains('evolv28')) {
          final device = {
            'id': deviceData['id'],
            'name': deviceName,
            'signalStrength': _calculateSignalStrength(deviceData['rssi']),
            'isConnected': false,
          };
          
          // Add device if not already in list
          if (!_nearbyDevices.any((d) => d['id'] == device['id'])) {
            _nearbyDevices.add(device);
            notifyListeners();
          }
        }
      });
      
      print('Native Bluetooth service initialized');
    } catch (e) {
      print('Error initializing native Bluetooth service: $e');
    }
  }
  
  /// Get Bluetooth status using native service
  Future<String> getNativeBluetoothStatus() async {
    try {
      final status = await NativeBluetoothService.getBluetoothStatus();
      print('Native Bluetooth status: $status');
      return status.toString().split('.').last;
    } catch (e) {
      print('Error getting native Bluetooth status: $e');
      return 'unknown';
    }
  }
  
  /// Get Bluetooth permission status using native service
  Future<String> getNativeBluetoothPermissionStatus() async {
    try {
      final status = await NativeBluetoothService.getBluetoothPermissionStatus();
      print('Native Bluetooth permission status: $status');
      return status.toString().split('.').last;
    } catch (e) {
      print('Error getting native Bluetooth permission status: $e');
      return 'unknown';
    }
  }
  
  /// Request Bluetooth permission using native service
  Future<String> requestNativeBluetoothPermission() async {
    try {
      final result = await NativeBluetoothService.requestBluetoothPermission();
      print('Native Bluetooth permission request result: $result');
      return result.toString();
    } catch (e) {
      print('Error requesting native Bluetooth permission: $e');
      return 'error';
    }
  }
  
  /// Start scanning using native service
  Future<String> startNativeScanning() async {
    try {
      _isScanning = true;
      _nearbyDevices.clear(); // Clear previous results
      notifyListeners();
      
      final result = await NativeBluetoothService.startScanning();
      print('Native Bluetooth scanning result: $result');
      return result.toString();
    } catch (e) {
      print('Error starting native Bluetooth scanning: $e');
      _isScanning = false;
      notifyListeners();
      return 'error';
    }
  }
  
  /// Stop scanning using native service
  Future<String> stopNativeScanning() async {
    try {
      final result = await NativeBluetoothService.stopScanning();
      _isScanning = false;
      notifyListeners();
      print('Native Bluetooth scanning stopped: $result');
      return result.toString();
    } catch (e) {
      print('Error stopping native Bluetooth scanning: $e');
      return 'error';
    }
  }
  
  /// Calculate signal strength from RSSI
  int _calculateSignalStrength(int rssi) {
    if (rssi >= -50) return 100;
    if (rssi >= -60) return 80;
    if (rssi >= -70) return 60;
    if (rssi >= -80) return 40;
    if (rssi >= -90) return 20;
    return 10;
  }
  
  /// Filter and keep only evolv28 devices
  void _filterEvolv28Devices() {
    _nearbyDevices.removeWhere((device) {
      final deviceName = device['name'] ?? '';
      final isEvolv28 = deviceName.toLowerCase().contains('evolv28');
      if (!isEvolv28) {
        print('Removing non-evolv28 device: $deviceName');
      }
      return !isEvolv28;
    });
    notifyListeners();
  }
  
  /// Check if we should use native Bluetooth service
  bool get shouldUseNativeBluetooth => Platform.isIOS;
  
  /// Force use native Bluetooth service (for testing)
  bool _forceNativeBluetooth = false;
  bool get forceNativeBluetooth => _forceNativeBluetooth;
  
  void setForceNativeBluetooth(bool value) {
    _forceNativeBluetooth = value;
    notifyListeners();
  }
  
  /// Enhanced start device connection using native service when available
  Future<void> startDeviceConnectionWithNative() async {
    if (shouldUseNativeBluetooth) {
      print('Using native Bluetooth service for iOS');
      
      // Initialize native service
      await initializeNativeBluetooth();
      
      // Check Bluetooth status
      final status = await getNativeBluetoothStatus();
      print('Native Bluetooth status: $status');
      
      // Check permission status
      final permissionStatus = await getNativeBluetoothPermissionStatus();
      print('Native Bluetooth permission status: $permissionStatus');
      
      if (status == 'powered_on' && permissionStatus == 'granted') {
        // Start scanning
        await startNativeScanning();
      } else if (status == 'powered_off') {
        // Show Bluetooth enable dialog
        _showBluetoothEnableDialog = true;
        notifyListeners();
      } else if (permissionStatus == 'denied') {
        // Show permission error dialog
        _showBluetoothPermissionErrorDialog = true;
        notifyListeners();
      } else {
        // Request permission
        await requestNativeBluetoothPermission();
      }
    } else {
      // Use existing Flutter Blue Plus logic for Android
      startDeviceConnection();
    }
  }

  @override
  void dispose() {
    try {
      FlutterBluePlus.stopScan();
      _scanResultsSubscription?.cancel();
      _isScanningSubscription?.cancel();
      _nativeBluetoothStateSubscription?.cancel();
      _nativeDeviceDiscoveredSubscription?.cancel();
      NativeBluetoothService.dispose();
      print('BLE scanning stopped and subscriptions cancelled');
    } catch (e) {
      print('Error stopping BLE scan: $e');
    }
    super.dispose();
  }
}
