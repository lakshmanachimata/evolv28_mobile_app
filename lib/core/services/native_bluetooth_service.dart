import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';

enum NativeBluetoothState {
  unknown,
  resetting,
  unsupported,
  unauthorized,
  poweredOff,
  poweredOn,
}

enum BluetoothPermissionStatus {
  denied,
  granted,
  restricted,
  limited,
  provisional,
}

class NativeBluetoothService {
  static const MethodChannel _channel = MethodChannel('bluetooth_manager');
  static StreamController<Map<String, dynamic>>? _stateController;
  static StreamController<Map<String, dynamic>>? _deviceController;

  static Future<void> initialize() async {
    if (!Platform.isMacOS) {
      print('🔵 NativeBluetoothService: Not macOS, skipping initialization');
      return;
    }

    print('🔵 NativeBluetoothService: Initializing native Bluetooth service for macOS');
    
    // Set up method call handler for state changes from native code
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onBluetoothStateChanged':
          final arguments = call.arguments as Map<String, dynamic>;
          _stateController?.add(arguments);
          break;
        case 'onDeviceDiscovered':
          final arguments = call.arguments as Map<String, dynamic>;
          _deviceController?.add(arguments);
          break;
      }
    });

    // Initialize state controllers
    _stateController = StreamController<Map<String, dynamic>>.broadcast();
    _deviceController = StreamController<Map<String, dynamic>>.broadcast();
  }

  static Future<String> getBluetoothState() async {
    if (!Platform.isMacOS) {
      print('🔵 NativeBluetoothService: Not macOS, returning unknown state');
      return 'unknown';
    }

    try {
      final String state = await _channel.invokeMethod('getBluetoothState');
      print('🔵 NativeBluetoothService: Bluetooth state: $state');
      return state;
    } catch (e) {
      print('❌ NativeBluetoothService: Error getting Bluetooth state: $e');
      return 'unknown';
    }
  }

  static Future<bool> isBluetoothEnabled() async {
    if (!Platform.isMacOS) {
      print('🔵 NativeBluetoothService: Not macOS, returning false');
      return false;
    }

    try {
      final bool enabled = await _channel.invokeMethod('isBluetoothEnabled');
      print('🔵 NativeBluetoothService: Bluetooth enabled: $enabled');
      return enabled;
    } catch (e) {
      print('❌ NativeBluetoothService: Error checking if Bluetooth is enabled: $e');
      return false;
    }
  }

  static Future<bool> requestBluetoothPermission() async {
    if (!Platform.isMacOS) {
      print('🔵 NativeBluetoothService: Not macOS, returning false');
      return false;
    }

    try {
      final bool granted = await _channel.invokeMethod('requestBluetoothPermission');
      print('🔵 NativeBluetoothService: Bluetooth permission granted: $granted');
      return granted;
    } catch (e) {
      print('❌ NativeBluetoothService: Error requesting Bluetooth permission: $e');
      return false;
    }
  }

  static Future<NativeBluetoothState> getBluetoothStatus() async {
    if (!Platform.isMacOS) {
      return NativeBluetoothState.unknown;
    }

    try {
      final String state = await _channel.invokeMethod('getBluetoothState');
      return _stringToBluetoothState(state);
    } catch (e) {
      print('❌ NativeBluetoothService: Error getting Bluetooth status: $e');
      return NativeBluetoothState.unknown;
    }
  }

  static Future<BluetoothPermissionStatus> getBluetoothPermissionStatus() async {
    if (!Platform.isMacOS) {
      return BluetoothPermissionStatus.denied;
    }

    try {
      final bool granted = await _channel.invokeMethod('requestBluetoothPermission');
      return granted ? BluetoothPermissionStatus.granted : BluetoothPermissionStatus.denied;
    } catch (e) {
      print('❌ NativeBluetoothService: Error getting Bluetooth permission status: $e');
      return BluetoothPermissionStatus.denied;
    }
  }

  static Future<bool> startScanning() async {
    if (!Platform.isMacOS) {
      return false;
    }

    try {
      final bool result = await _channel.invokeMethod('startScanning');
      print('🔵 NativeBluetoothService: Start scanning result: $result');
      return result;
    } catch (e) {
      print('❌ NativeBluetoothService: Error starting scanning: $e');
      return false;
    }
  }

  static Future<bool> stopScanning() async {
    if (!Platform.isMacOS) {
      return false;
    }

    try {
      final bool result = await _channel.invokeMethod('stopScanning');
      print('🔵 NativeBluetoothService: Stop scanning result: $result');
      return result;
    } catch (e) {
      print('❌ NativeBluetoothService: Error stopping scanning: $e');
      return false;
    }
  }

  static Stream<Map<String, dynamic>> get bluetoothStateStream {
    if (_stateController == null) {
      initialize();
    }
    return _stateController!.stream;
  }

  static Stream<Map<String, dynamic>> get deviceDiscoveredStream {
    if (_deviceController == null) {
      initialize();
    }
    return _deviceController!.stream;
  }

  static NativeBluetoothState _stringToBluetoothState(String state) {
    switch (state) {
      case 'powered_on':
        return NativeBluetoothState.poweredOn;
      case 'powered_off':
        return NativeBluetoothState.poweredOff;
      case 'resetting':
        return NativeBluetoothState.resetting;
      case 'unauthorized':
        return NativeBluetoothState.unauthorized;
      case 'unsupported':
        return NativeBluetoothState.unsupported;
      default:
        return NativeBluetoothState.unknown;
    }
  }

  static void dispose() {
    _stateController?.close();
    _deviceController?.close();
    _stateController = null;
    _deviceController = null;
  }
}

// Extension methods for string conversion
extension StringBluetoothExtension on String {
  NativeBluetoothState toNativeBluetoothState() {
    switch (this) {
      case 'powered_on':
        return NativeBluetoothState.poweredOn;
      case 'powered_off':
        return NativeBluetoothState.poweredOff;
      case 'resetting':
        return NativeBluetoothState.resetting;
      case 'unauthorized':
        return NativeBluetoothState.unauthorized;
      case 'unsupported':
        return NativeBluetoothState.unsupported;
      default:
        return NativeBluetoothState.unknown;
    }
  }

  BluetoothPermissionStatus toBluetoothPermissionStatus() {
    switch (this) {
      case 'granted':
        return BluetoothPermissionStatus.granted;
      case 'denied':
        return BluetoothPermissionStatus.denied;
      case 'restricted':
        return BluetoothPermissionStatus.restricted;
      case 'limited':
        return BluetoothPermissionStatus.limited;
      case 'provisional':
        return BluetoothPermissionStatus.provisional;
      default:
        return BluetoothPermissionStatus.denied;
    }
  }
}

