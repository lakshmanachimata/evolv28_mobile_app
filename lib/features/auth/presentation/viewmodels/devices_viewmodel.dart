import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class DevicesViewModel extends ChangeNotifier {
  // State variables
  bool _isBluetoothEnabled = false;
  bool _isBluetoothScanPermissionGranted = false;
  bool _isScanning = false;
  bool _isConnecting = false;
  bool _isDeviceConnected = false;
  List<Map<String, dynamic>> _nearbyDevices = [];
  String _selectedDeviceId = '';
  String _userName = 'Jane Doe'; // Default name, can be passed from previous screen

  // Getters
  bool get isBluetoothEnabled => _isBluetoothEnabled;
  bool get isBluetoothScanPermissionGranted => _isBluetoothScanPermissionGranted;
  bool get isScanning => _isScanning;
  bool get isConnecting => _isConnecting;
  bool get isDeviceConnected => _isDeviceConnected;
  List<Map<String, dynamic>> get nearbyDevices => _nearbyDevices;
  String get selectedDeviceId => _selectedDeviceId;
  String get userName => _userName;

  // Bluetooth enable dialog
  bool _showBluetoothEnableDialog = false;
  bool _bluetoothDialogShown = false; // Flag to prevent multiple dialogs
  bool _bluetoothStatusChecked = false; // Flag to track if we've checked Bluetooth status
  bool get showBluetoothEnableDialog => _showBluetoothEnableDialog;

  // Bluetooth scan permission dialog
  bool _showBluetoothScanPermissionDialog = false;
  bool get showBluetoothScanPermissionDialog => _showBluetoothScanPermissionDialog;

  // Device activated dialog
  bool _showDeviceActivatedDialog = false;
  bool get showDeviceActivatedDialog => _showDeviceActivatedDialog;

  // Initialize the screen
  Future<void> initialize() async {
    await _checkBluetoothStatus();
    
    // Listen to Bluetooth state changes
    _listenToBluetoothStateChanges();
    
    // Auto-start the device connection flow with a longer delay to ensure Bluetooth is properly initialized
    Future.delayed(const Duration(milliseconds: 1000), () {
      startDeviceConnection();
    });
  }

  // Check if we should show permission dialog on screen load
  void checkPermissionOnLoad() {
    if (_isBluetoothEnabled && !_isBluetoothScanPermissionGranted && !_showBluetoothScanPermissionDialog) {
      print('Bluetooth enabled but no scan permission, showing permission dialog');
      _showBluetoothScanPermissionDialog = true;
      notifyListeners();
    }
  }

  // Listen to Bluetooth state changes
  void _listenToBluetoothStateChanges() {
    if (Platform.isAndroid || Platform.isIOS) {
      FlutterBluePlus.adapterState.listen((BluetoothAdapterState state) {
        print('Bluetooth adapter state changed: $state');
        if (state == BluetoothAdapterState.on) {
          _isBluetoothEnabled = true;
          _bluetoothDialogShown = false; // Reset dialog flag when Bluetooth is enabled
          
          // If Bluetooth was just enabled, proceed to permission check
          if (!_isBluetoothScanPermissionGranted) {
            print('Bluetooth enabled, proceeding to permission check');
            Future.delayed(const Duration(milliseconds: 500), () {
              _showBluetoothScanPermissionDialog = true;
              notifyListeners();
            });
          } else {
            // If permission is already granted, start scanning
            Future.delayed(const Duration(milliseconds: 500), () {
              _startScanning();
            });
          }
          
          notifyListeners();
        } else if (state == BluetoothAdapterState.off) {
          _isBluetoothEnabled = false;
          notifyListeners();
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
          // Add a small delay to ensure the adapter is fully initialized
          await Future.delayed(const Duration(milliseconds: 100));
          
          // Check if Bluetooth is turned on
          _isBluetoothEnabled = await FlutterBluePlus.isOn;
          print('Bluetooth status check: isSupported=true, isOn=$_isBluetoothEnabled');
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
  }

  // Start the device connection flow
  void startDeviceConnection() {
    print('startDeviceConnection called: isBluetoothEnabled=$_isBluetoothEnabled, dialogShown=$_bluetoothDialogShown, scanPermissionGranted=$_isBluetoothScanPermissionGranted, statusChecked=$_bluetoothStatusChecked');
    
    // Only show Bluetooth enable dialog if we've checked the status and confirmed it's disabled
    if (!_isBluetoothEnabled && !_bluetoothDialogShown && _bluetoothStatusChecked) {
      print('Showing Bluetooth enable dialog');
      _showBluetoothEnableDialog = true;
      _bluetoothDialogShown = true; // Prevent multiple dialogs
    } else if (_isBluetoothEnabled && !_isBluetoothScanPermissionGranted) {
      print('Showing Bluetooth scan permission dialog');
      _showBluetoothScanPermissionDialog = true;
    } else if (_isBluetoothEnabled && _isBluetoothScanPermissionGranted) {
      print('Starting scanning');
      _startScanning();
    } else if (!_bluetoothStatusChecked) {
      print('Bluetooth status not yet checked, waiting...');
      // If we haven't checked Bluetooth status yet, wait a bit more and try again
      Future.delayed(const Duration(milliseconds: 500), () {
        startDeviceConnection();
      });
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
      
      // If Bluetooth was just enabled, proceed to permission check
      if (!_isBluetoothScanPermissionGranted) {
        print('Bluetooth enabled after settings, proceeding to permission check');
        Future.delayed(const Duration(milliseconds: 500), () {
          _showBluetoothScanPermissionDialog = true;
          notifyListeners();
        });
      } else {
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

  // Handle Bluetooth scan permission allow
  Future<void> allowBluetoothScanPermission() async {
    _showBluetoothScanPermissionDialog = false;
    
    // Request Bluetooth scan permission
    if (Platform.isAndroid) {
      final status = await Permission.bluetoothScan.request();
      _isBluetoothScanPermissionGranted = status.isGranted;
    } else if (Platform.isIOS) {
      final status = await Permission.bluetooth.request();
      _isBluetoothScanPermissionGranted = status.isGranted;
    } else {
      _isBluetoothScanPermissionGranted = true; // Other platforms
    }
    
    if (_isBluetoothScanPermissionGranted) {
      _startScanning();
    }
    notifyListeners();
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

      // Start scanning for BLE devices with proper parameters
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 10),
        androidUsesFineLocation: true, // This is important for Android
      );

      print('BLE scan started successfully');

      // Set up scan results listener AFTER starting scan
      FlutterBluePlus.scanResults.listen((results) {
        print('BLE scan results: ${results.length} devices found');
        
        // Process all scan results and filter for Evolv28 devices
        _processScanResults(results);
      });

      // Also listen to scan state changes
      FlutterBluePlus.isScanning.listen((isScanning) {
        print('Scan state changed: $isScanning');
        if (!isScanning) {
          _isScanning = false;
          notifyListeners();
          print('BLE scan completed');
        }
      });

      // Stop scanning after timeout
      Future.delayed(const Duration(seconds: 10), () {
        FlutterBluePlus.stopScan();
        _isScanning = false;
        notifyListeners();
        print('BLE scan completed');
      });

    } catch (e) {
      print('Error during BLE scan: $e');
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
        final existingIndex = _nearbyDevices.indexWhere((d) => d['id'] == device.remoteId.toString());
        
        if (existingIndex >= 0) {
          // Update existing device with new scan result
          _nearbyDevices[existingIndex] = {
            'id': device.remoteId.toString(),
            'name': deviceName,
            'isConnected': false,
            'signalStrength': result.rssi != null ? (100 + result.rssi!).clamp(0, 100) : 0,
            'device': device,
          };
        } else {
          // Add new device
          _nearbyDevices.add({
            'id': device.remoteId.toString(),
            'name': deviceName,
            'isConnected': false,
            'signalStrength': result.rssi != null ? (100 + result.rssi!).clamp(0, 100) : 0,
            'device': device,
          });
        }
      }
    }

    // Sort devices by signal strength (strongest first)
    _nearbyDevices.sort((a, b) => (b['signalStrength'] as int).compareTo(a['signalStrength'] as int));

    print('Evolv28 devices found: ${_nearbyDevices.length}');
    notifyListeners();

    // If only one device found, connect automatically
    if (_nearbyDevices.length == 1) {
      Future.delayed(const Duration(seconds: 1), () {
        connectToDevice(_nearbyDevices.first['id']);
      });
    }
  }

  // Connect to a specific device
  void connectToDevice(String deviceId) async {
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
      _showDeviceActivatedDialog = true;
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
  }

  // Try again button
  void tryAgain() {
    print('Try again - restarting BLE scan');
    _startScanning();
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
    // Recheck Bluetooth status when app resumes (user might have enabled Bluetooth)
    print('App resumed, checking Bluetooth status');
    recheckBluetoothStatus();
  }

  // Manual method to check Bluetooth status (for debugging)
  Future<void> checkBluetoothStatusManually() async {
    print('Manual Bluetooth status check requested');
    await _checkBluetoothStatus();
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
  void dispose() {
    try {
      FlutterBluePlus.stopScan();
      print('BLE scanning stopped');
    } catch (e) {
      print('Error stopping BLE scan: $e');
    }
  }
}
