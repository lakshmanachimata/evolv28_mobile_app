import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DevicesViewModel extends ChangeNotifier {
  // State variables
  bool _isBluetoothEnabled = false;
  bool _isLocationPermissionGranted = false;
  bool _isScanning = false;
  bool _isConnecting = false;
  bool _isDeviceConnected = false;
  List<Map<String, dynamic>> _nearbyDevices = [];
  String _selectedDeviceId = '';
  String _userName = 'Jane Doe'; // Default name, can be passed from previous screen

  // Getters
  bool get isBluetoothEnabled => _isBluetoothEnabled;
  bool get isLocationPermissionGranted => _isLocationPermissionGranted;
  bool get isScanning => _isScanning;
  bool get isConnecting => _isConnecting;
  bool get isDeviceConnected => _isDeviceConnected;
  List<Map<String, dynamic>> get nearbyDevices => _nearbyDevices;
  String get selectedDeviceId => _selectedDeviceId;
  String get userName => _userName;

  // Bluetooth permission dialog
  bool _showBluetoothPermissionDialog = false;
  bool get showBluetoothPermissionDialog => _showBluetoothPermissionDialog;

  // Location permission dialog
  bool _showLocationPermissionDialog = false;
  bool get showLocationPermissionDialog => _showLocationPermissionDialog;

  // Device activated dialog
  bool _showDeviceActivatedDialog = false;
  bool get showDeviceActivatedDialog => _showDeviceActivatedDialog;

  // Initialize the screen
  void initialize() {
    _checkBluetoothStatus();
  }

  // Check if Bluetooth is enabled
  void _checkBluetoothStatus() {
    // Simulate checking Bluetooth status
    // In real implementation, this would check actual Bluetooth state
    _isBluetoothEnabled = false; // Start with disabled state
    notifyListeners();
  }

  // Show Bluetooth permission dialog
  void showBluetoothPermission() {
    _showBluetoothPermissionDialog = true;
    notifyListeners();
  }

  // Handle Bluetooth permission allow
  void allowBluetoothPermission() {
    _showBluetoothPermissionDialog = false;
    _enableBluetooth();
    notifyListeners();
  }

  // Enable Bluetooth
  void _enableBluetooth() {
    _isBluetoothEnabled = true;
    // Start scanning for devices
    _startScanning();
    notifyListeners();
  }

  // Start scanning for devices
  void _startScanning() {
    _isScanning = true;
    notifyListeners();

    // Simulate scanning delay
    Future.delayed(const Duration(seconds: 2), () {
      _isScanning = false;
      _simulateDeviceScan();
      notifyListeners();
    });
  }

  // Simulate device scanning
  void _simulateDeviceScan() {
    // Simulate finding no devices initially
    _nearbyDevices = [];
    notifyListeners();

    // After a delay, show location permission dialog
    Future.delayed(const Duration(seconds: 1), () {
      showLocationPermission();
    });
  }

  // Show location permission dialog
  void showLocationPermission() {
    _showLocationPermissionDialog = true;
    notifyListeners();
  }

  // Handle location permission allow
  void allowLocationPermission() {
    _showLocationPermissionDialog = false;
    _isLocationPermissionGranted = true;
    _startDeviceScanWithLocation();
    notifyListeners();
  }

  // Cancel location permission
  void cancelLocationPermission() {
    _showLocationPermissionDialog = false;
    notifyListeners();
  }

  // Start device scan with location permission
  void _startDeviceScanWithLocation() {
    _isScanning = true;
    notifyListeners();

    // Simulate finding devices after location permission
    Future.delayed(const Duration(seconds: 2), () {
      _isScanning = false;
      _simulateFoundDevices();
      notifyListeners();
    });
  }

  // Simulate finding devices
  void _simulateFoundDevices() {
    _nearbyDevices = [
      {
        'id': 'evolv28_001',
        'name': 'Evolv28 Device 1',
        'isConnected': false,
        'signalStrength': 85,
      },
      {
        'id': 'evolv28_002', 
        'name': 'Evolv28 Device 2',
        'isConnected': true, // This device was previously activated
        'signalStrength': 92,
      },
    ];
    notifyListeners();

    // Auto-connect to previously activated device
    _autoConnectToActivatedDevice();
  }

  // Auto-connect to previously activated device
  void _autoConnectToActivatedDevice() {
    final activatedDevice = _nearbyDevices.firstWhere(
      (device) => device['isConnected'] == true,
      orElse: () => {},
    );

    if (activatedDevice.isNotEmpty) {
      Future.delayed(const Duration(seconds: 1), () {
        connectToDevice(activatedDevice['id']);
      });
    }
  }

  // Connect to a specific device
  void connectToDevice(String deviceId) {
    _isConnecting = true;
    _selectedDeviceId = deviceId;
    notifyListeners();

    // Simulate connection delay
    Future.delayed(const Duration(seconds: 3), () {
      _isConnecting = false;
      _isDeviceConnected = true;
      _showDeviceActivatedDialog = true;
      notifyListeners();
    });
  }

  // Handle device activated dialog OK
  void handleDeviceActivatedOk() {
    _showDeviceActivatedDialog = false;
    notifyListeners();
  }

  // Try again button
  void tryAgain() {
    _startScanning();
  }

  // Can't find device button
  void cantFindDevice() {
    // Handle can't find device action
    // This could show help or support options
  }

  // Update firmware button
  void updateFirmware() {
    // Handle firmware update
  }

  // Having troubles button
  void havingTroubles() {
    // Handle support/troubleshooting
  }
}
