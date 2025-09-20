import 'dart:async';
import 'package:flutter/services.dart';

class NativeBluetoothService {
  static const MethodChannel _channel = MethodChannel('bluetooth_manager');
  
  // Stream controllers for callbacks
  static final StreamController<Map<String, dynamic>> _bluetoothStateController = 
      StreamController<Map<String, dynamic>>.broadcast();
  static final StreamController<Map<String, dynamic>> _deviceDiscoveredController = 
      StreamController<Map<String, dynamic>>.broadcast();
  
  static Stream<Map<String, dynamic>> get bluetoothStateStream => _bluetoothStateController.stream;
  static Stream<Map<String, dynamic>> get deviceDiscoveredStream => _deviceDiscoveredController.stream;
  
  static bool _isInitialized = false;
  
  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    _channel.setMethodCallHandler(_handleMethodCall);
    _isInitialized = true;
  }
  
  static Future<void> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onBluetoothStateChanged':
        final Map<String, dynamic> data = Map<String, dynamic>.from(call.arguments);
        _bluetoothStateController.add(data);
        break;
      case 'onDeviceDiscovered':
        final Map<String, dynamic> data = Map<String, dynamic>.from(call.arguments);
        _deviceDiscoveredController.add(data);
        break;
    }
  }
  
  /// Get current Bluetooth status
  static Future<String> getBluetoothStatus() async {
    try {
      final String status = await _channel.invokeMethod('getBluetoothStatus');
      return status;
    } catch (e) {
      return 'unknown';
    }
  }
  
  /// Get Bluetooth permission status
  static Future<String> getBluetoothPermissionStatus() async {
    try {
      final String status = await _channel.invokeMethod('getBluetoothPermissionStatus');
      return status;
    } catch (e) {
      return 'unknown';
    }
  }
  
  /// Request Bluetooth permission
  static Future<String> requestBluetoothPermission() async {
    try {
      final String result = await _channel.invokeMethod('requestBluetoothPermission');
      return result;
    } catch (e) {
      return 'error';
    }
  }
  
  /// Start Bluetooth scanning
  static Future<String> startScanning() async {
    try {
      final String result = await _channel.invokeMethod('startScanning');
      return result;
    } catch (e) {
      return 'error';
    }
  }
  
  /// Stop Bluetooth scanning
  static Future<String> stopScanning() async {
    try {
      final String result = await _channel.invokeMethod('stopScanning');
      return result;
    } catch (e) {
      return 'error';
    }
  }
  
  /// Dispose resources
  static void dispose() {
    _bluetoothStateController.close();
    _deviceDiscoveredController.close();
    _isInitialized = false;
  }
}

// Enum for Bluetooth states
enum NativeBluetoothState {
  unknown,
  resetting,
  unsupported,
  unauthorized,
  poweredOff,
  poweredOn
}

// Enum for permission status
enum BluetoothPermissionStatus {
  unknown,
  resetting,
  unsupported,
  denied,
  grantedButOff,
  granted
}

// Extension to convert strings to enums
extension BluetoothStateExtension on String {
  NativeBluetoothState toNativeBluetoothState() {
    switch (this) {
      case 'unknown':
        return NativeBluetoothState.unknown;
      case 'resetting':
        return NativeBluetoothState.resetting;
      case 'unsupported':
        return NativeBluetoothState.unsupported;
      case 'unauthorized':
        return NativeBluetoothState.unauthorized;
      case 'powered_off':
        return NativeBluetoothState.poweredOff;
      case 'powered_on':
        return NativeBluetoothState.poweredOn;
      default:
        return NativeBluetoothState.unknown;
    }
  }
  
  BluetoothPermissionStatus toBluetoothPermissionStatus() {
    switch (this) {
      case 'unknown':
        return BluetoothPermissionStatus.unknown;
      case 'resetting':
        return BluetoothPermissionStatus.resetting;
      case 'unsupported':
        return BluetoothPermissionStatus.unsupported;
      case 'denied':
        return BluetoothPermissionStatus.denied;
      case 'granted_but_off':
        return BluetoothPermissionStatus.grantedButOff;
      case 'granted':
        return BluetoothPermissionStatus.granted;
      default:
        return BluetoothPermissionStatus.unknown;
    }
  }
}
