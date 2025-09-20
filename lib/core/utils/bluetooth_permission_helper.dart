import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/native_bluetooth_service.dart';

class BluetoothPermissionHelper {
  /// Check if Bluetooth is enabled and permission is granted
  static Future<bool> isBluetoothEnabled() async {
    try {
      // Initialize the native service if not already done
      await NativeBluetoothService.initialize();
      
      if (Platform.isIOS) {
        // Use native iOS implementation for accurate Bluetooth status
        final status = await NativeBluetoothService.getBluetoothStatus();
        final permissionStatus = await NativeBluetoothService.getBluetoothPermissionStatus();
        
        print('🔵 BluetoothPermissionHelper: iOS Bluetooth status: $status');
        print('🔵 BluetoothPermissionHelper: iOS Permission status: $permissionStatus');
        
        // Bluetooth is enabled if status is powered_on and permission is granted
        return status == 'powered_on' && permissionStatus == 'granted';
      } else {
        // For Android, use permission_handler
        final status = await Permission.bluetooth.status;
        final bluetoothConnectStatus = await Permission.bluetoothConnect.status;
        final bluetoothScanStatus = await Permission.bluetoothScan.status;
        
        print('🔵 BluetoothPermissionHelper: Android Bluetooth permission status: $status');
        print('🔵 BluetoothPermissionHelper: Android BluetoothConnect status: $bluetoothConnectStatus');
        print('🔵 BluetoothPermissionHelper: Android BluetoothScan status: $bluetoothScanStatus');
        
        return status.isGranted && bluetoothConnectStatus.isGranted && bluetoothScanStatus.isGranted;
      }
    } catch (e) {
      print('❌ BluetoothPermissionHelper: Error checking Bluetooth status: $e');
      return false;
    }
  }

  /// Request Bluetooth permission
  static Future<bool> requestBluetoothPermission() async {
    try {
      if (Platform.isIOS) {
        // Use native iOS implementation
        final result = await NativeBluetoothService.requestBluetoothPermission();
        return result == 'permission_requested';
      } else {
        // For Android, request all necessary Bluetooth permissions
        final bluetoothStatus = await Permission.bluetooth.request();
        final bluetoothConnectStatus = await Permission.bluetoothConnect.request();
        final bluetoothScanStatus = await Permission.bluetoothScan.request();
        
        return bluetoothStatus.isGranted && 
               bluetoothConnectStatus.isGranted && 
               bluetoothScanStatus.isGranted;
      }
    } catch (e) {
      print('❌ BluetoothPermissionHelper: Error requesting Bluetooth permission: $e');
      return false;
    }
  }

  /// Open system Bluetooth settings
  static Future<void> openBluetoothSettings() async {
    try {
      await openAppSettings();
    } catch (e) {
      print('❌ BluetoothPermissionHelper: Error opening app settings: $e');
    }
  }

  /// Show Bluetooth permission dialog
  static Future<void> showBluetoothPermissionDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.bluetooth_disabled,
                color: Colors.blue,
                size: 28,
              ),
              const SizedBox(width: 12),
              const Text(
                'Bluetooth Required',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bluetooth access is required for this app to connect to your Evolv28 device.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 12),
              Text(
                'Please enable Bluetooth in your device settings.',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'Cancel',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                openBluetoothSettings();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF17961),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Open Settings',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Check Bluetooth permission and show dialog if needed
  static Future<bool> checkAndRequestBluetoothPermission(BuildContext context) async {
    try {
      // Check if Bluetooth is enabled
      final isEnabled = await isBluetoothEnabled();
      if (!isEnabled) {
        // Try to request permission first
        final granted = await requestBluetoothPermission();
        if (!granted) {
          // If permission was denied or Bluetooth is off, show dialog
          await showBluetoothPermissionDialog(context);
          return false;
        }
      }

      return true;
    } catch (e) {
      print('❌ BluetoothPermissionHelper: Error in checkAndRequestBluetoothPermission: $e');
      await showBluetoothPermissionDialog(context);
      return false;
    }
  }

  /// Get detailed Bluetooth status for debugging
  static Future<Map<String, String>> getDetailedBluetoothStatus() async {
    try {
      if (Platform.isIOS) {
        final status = await NativeBluetoothService.getBluetoothStatus();
        final permissionStatus = await NativeBluetoothService.getBluetoothPermissionStatus();
        
        return {
          'status': status,
          'permission': permissionStatus,
          'platform': 'iOS',
        };
      } else {
        final bluetoothStatus = await Permission.bluetooth.status;
        final bluetoothConnectStatus = await Permission.bluetoothConnect.status;
        final bluetoothScanStatus = await Permission.bluetoothScan.status;
        
        return {
          'bluetooth': bluetoothStatus.toString(),
          'bluetoothConnect': bluetoothConnectStatus.toString(),
          'bluetoothScan': bluetoothScanStatus.toString(),
          'platform': 'Android',
        };
      }
    } catch (e) {
      print('❌ BluetoothPermissionHelper: Error getting detailed status: $e');
      return {
        'error': e.toString(),
        'platform': Platform.isIOS ? 'iOS' : 'Android',
      };
    }
  }
}
