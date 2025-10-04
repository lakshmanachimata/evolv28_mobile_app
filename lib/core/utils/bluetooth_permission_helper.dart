import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/native_bluetooth_service.dart';

class BluetoothPermissionHelper {
  /// Check if Bluetooth is enabled and permission is granted
  static Future<bool> isBluetoothEnabled() async {
    try {
      if (Platform.isMacOS) {
        // For macOS, assume Bluetooth is available and enabled by default
        // macOS handles Bluetooth permissions differently than mobile platforms
        print('🔵 BluetoothPermissionHelper: macOS detected, assuming Bluetooth enabled');
        return true;
      }
      
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
      // For macOS, return true as fallback since permission_handler has limited support
      if (Platform.isMacOS) {
        print('🔵 BluetoothPermissionHelper: macOS fallback - returning true for Bluetooth status');
        return true;
      }
      return false;
    }
  }

  /// Request Bluetooth permission
  static Future<bool> requestBluetoothPermission() async {
    try {
      if (Platform.isMacOS) {
        // For macOS, assume permission is granted by default
        print('🔵 BluetoothPermissionHelper: macOS detected, assuming Bluetooth permission granted');
        return true;
      }
      
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
      // For macOS, return true as fallback
      if (Platform.isMacOS) {
        print('🔵 BluetoothPermissionHelper: macOS fallback - returning true for Bluetooth permission');
        return true;
      }
      return false;
    }
  }

  /// Open system Bluetooth settings
  static Future<void> openBluetoothSettings() async {
    try {
      if (Platform.isMacOS) {
        // For macOS, we can't open app settings programmatically
        // The user would need to manually go to System Preferences > Bluetooth
        print('🔵 BluetoothPermissionHelper: macOS detected - cannot open app settings programmatically');
        print('🔵 BluetoothPermissionHelper: Please go to System Preferences > Bluetooth');
        return;
      }
      
      await openAppSettings();
    } catch (e) {
      print('❌ BluetoothPermissionHelper: Error opening app settings: $e');
      if (Platform.isMacOS) {
        print('🔵 BluetoothPermissionHelper: macOS fallback - cannot open settings programmatically');
      }
    }
  }

  /// Show Bluetooth permission dialog
  static Future<bool> showBluetoothPermissionDialog(BuildContext context) async {
    return await showDialog<bool>(
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
                Icons.bluetooth,
                color: const Color(0xFFF17961),
                size: 28,
              ),
              const SizedBox(width: 12),
              const Text(
                'Bluetooth Permission',
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
                'Evolv28 needs Bluetooth access to connect to your Evolv28 device.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 12),
              Text(
                'This permission is required for device pairing and communication.',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text(
                'Not Now',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop(true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF17961),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Allow',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        );
      },
    ) ?? false;
  }

  /// Check Bluetooth permission and show dialog if needed
  static Future<bool> checkAndRequestBluetoothPermission(BuildContext context) async {
    try {
      // Check if Bluetooth is enabled
      final isEnabled = await isBluetoothEnabled();
      if (!isEnabled) {
        // Show custom dialog first
        final userAccepted = await showBluetoothPermissionDialog(context);
        if (userAccepted) {
          // User accepted, now request the actual system permission
          final granted = await requestBluetoothPermission();
          if (!granted) {
            // If permission was denied, open settings
            await openBluetoothSettings();
          }
          return granted;
        }
        return false;
      }

      return true;
    } catch (e) {
      print('❌ BluetoothPermissionHelper: Error in checkAndRequestBluetoothPermission: $e');
      // Show custom dialog on error
      final userAccepted = await showBluetoothPermissionDialog(context);
      if (userAccepted) {
        await openBluetoothSettings();
      }
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
          'status': status.toString().split('.').last,
          'permission': permissionStatus.toString().split('.').last,
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
