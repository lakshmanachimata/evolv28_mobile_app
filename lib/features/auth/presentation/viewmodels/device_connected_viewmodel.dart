import 'package:flutter/material.dart';

import '../../../../core/services/bluetooth_service.dart';

class DeviceConnectedViewModel extends ChangeNotifier {
  // Bluetooth service
  final BluetoothService _bluetoothService = BluetoothService();
  
  // Bluetooth listener
  late VoidCallback _bluetoothListener;

  // Device information
  final String _deviceName = 'evolv28-F07C1K';
  final int _batteryLevel = 90;
  final bool _isConnected = true;
  
  // Firmware update state
  String _currentVersion = '1.0.17.47.4';
  final String _latestVersion = '1.0.17.48.78';
  bool _updateAvailable = false;
  bool _isUpdating = false;
  bool _updateCompleted = false;
  
  // Dialog states
  bool _showUpdateSuccessDialog = false;
  
  // Device disconnection state
  bool _showDeviceDisconnectedPopup = false;
  String _disconnectedDeviceName = '';
  
  // Getters
  String get deviceName => _deviceName;
  int get batteryLevel => _batteryLevel;
  bool get isConnected => _isConnected;
  String get currentVersion => _currentVersion;
  String get latestVersion => _latestVersion;
  bool get updateAvailable => _updateAvailable;
  bool get isUpdating => _isUpdating;
  bool get updateCompleted => _updateCompleted;
  bool get showUpdateSuccessDialog => _showUpdateSuccessDialog;
  
  // Device disconnection getters
  bool get showDeviceDisconnectedPopup => _showDeviceDisconnectedPopup;
  String get disconnectedDeviceName => _disconnectedDeviceName;
  
  // Initialize the view model
  void initialize() async {
    // Initialize Bluetooth service
    await _bluetoothService.initialize();

    // Set up Bluetooth listener
    _bluetoothListener = () {
      notifyListeners();
    };
    _bluetoothService.addListener(_bluetoothListener);

    // Set up device disconnection callback
    _bluetoothService.setOnDeviceDisconnectedCallback((deviceName) {
      print('🎵 DeviceConnected: Device disconnected: $deviceName');
      _handleDeviceDisconnection(deviceName);
    });

    // Simulate checking for updates after a short delay
    Future.delayed(const Duration(seconds: 1), () {
      checkForUpdates();
    });
  }
  
  // Check for firmware updates
  void checkForUpdates() {
    // Simulate checking for updates
    Future.delayed(const Duration(milliseconds: 500), () {
      _updateAvailable = true;
      notifyListeners();
    });
  }
  
  // Start firmware update
  void startFirmwareUpdate() {
    if (!_updateAvailable || _isUpdating) return;
    
    _isUpdating = true;
    notifyListeners();
    
    // Simulate update process
    Future.delayed(const Duration(seconds: 3), () {
      _isUpdating = false;
      _updateCompleted = true;
      _currentVersion = _latestVersion;
      _updateAvailable = false;
      _showUpdateSuccessDialog = true;
      notifyListeners();
    });
  }
  
  // Handle update success dialog OK
  void handleUpdateSuccessOk() {
    _showUpdateSuccessDialog = false;
    notifyListeners();
  }
  
  // Handle help/troubleshooting
  void handleHelp() {
    // Navigate to help or show help dialog
    // TODO: Implement help functionality
  }

  // Handle device disconnection
  void _handleDeviceDisconnection(String deviceName) {
    print('🎵 DeviceConnected: Handling device disconnection for: $deviceName');
    
    // Show disconnection popup
    _showDeviceDisconnectedPopup = true;
    _disconnectedDeviceName = deviceName;
    notifyListeners();
  }

  void closeDeviceDisconnectedPopup() {
    _showDeviceDisconnectedPopup = false;
    _disconnectedDeviceName = '';
    notifyListeners();
  }

  @override
  void dispose() {
    _bluetoothService.removeListener(_bluetoothListener);
    super.dispose();
  }
}
