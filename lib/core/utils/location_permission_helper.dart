import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';

class LocationPermissionHelper {
  /// Check if location permission is granted
  static Future<bool> isLocationPermissionGranted() async {
    try {
      if (Platform.isMacOS) {
        // For macOS, assume location permission is granted by default
        // macOS handles location permissions differently than mobile platforms
        print('📍 LocationPermissionHelper: macOS detected, assuming location permission granted');
        return true;
      }
      
      final status = await Permission.location.status;
      return status.isGranted;
    } catch (e) {
      print('❌ LocationPermissionHelper: Error checking location permission: $e');
      // For macOS, return true as fallback since permission_handler has limited support
      if (Platform.isMacOS) {
        print('📍 LocationPermissionHelper: macOS fallback - returning true for location permission');
        return true;
      }
      return false;
    }
  }

  /// Check if location services are enabled
  static Future<bool> isLocationServiceEnabled() async {
    try {
      return await Geolocator.isLocationServiceEnabled();
    } catch (e) {
      print('❌ LocationPermissionHelper: Error checking location service: $e');
      return false;
    }
  }

  /// Request location permission
  static Future<bool> requestLocationPermission() async {
    try {
      if (Platform.isMacOS) {
        // For macOS, assume permission is granted by default
        print('📍 LocationPermissionHelper: macOS detected, assuming location permission granted');
        return true;
      }
      
      final status = await Permission.location.request();
      return status.isGranted;
    } catch (e) {
      print('❌ LocationPermissionHelper: Error requesting location permission: $e');
      // For macOS, return true as fallback
      if (Platform.isMacOS) {
        print('📍 LocationPermissionHelper: macOS fallback - returning true for location permission');
        return true;
      }
      return false;
    }
  }

  /// Open system location settings
  static Future<void> openLocationSettings() async {
    try {
      if (Platform.isMacOS) {
        // For macOS, we can't open app settings programmatically
        // The user would need to manually go to System Preferences > Security & Privacy > Privacy > Location Services
        print('📍 LocationPermissionHelper: macOS detected - cannot open app settings programmatically');
        print('📍 LocationPermissionHelper: Please go to System Preferences > Security & Privacy > Privacy > Location Services');
        return;
      }
      
      await openAppSettings();
    } catch (e) {
      print('❌ LocationPermissionHelper: Error opening app settings: $e');
      if (Platform.isMacOS) {
        print('📍 LocationPermissionHelper: macOS fallback - cannot open settings programmatically');
      }
    }
  }

  /// Show location permission bottom sheet
  static Future<bool> showLocationPermissionDialog(BuildContext context) async {
    return await showModalBottomSheet<bool>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Close button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).pop(false);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            Icons.close,
                            color: Colors.red[600],
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Title
                  const Text(
                    'Location Permission',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Content
                  const Text(
                    'Evolv28 collects location data to find and connect to nearby Evolv28 devices via Bluetooth, even when the app is closed or not in use. This data is used to enable seamless device connectivity and ensure proper functionality.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.left,
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Allow button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.of(context).pop(true);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF17961),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Allow',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    ) ?? false;
  }

  /// Check location permission and show dialog if needed
  static Future<bool> checkAndRequestLocationPermission(BuildContext context) async {
    try {
      // First check if location services are enabled
      final isServiceEnabled = await isLocationServiceEnabled();
      if (!isServiceEnabled) {
        // Show custom dialog first
        final userAccepted = await showLocationPermissionDialog(context);
        if (userAccepted) {
          // User accepted, open settings to enable location services
          await openLocationSettings();
        }
        return false;
      }

      // Always show app dialog first, regardless of permission status
      final userAccepted = await showLocationPermissionDialog(context);
      if (!userAccepted) {
        return false;
      }

      // Then check if permission is granted
      final isPermissionGranted = await isLocationPermissionGranted();
      if (!isPermissionGranted) {
        // User accepted app dialog, now request the actual system permission
        final granted = await requestLocationPermission();
        if (!granted) {
          // If permission was denied, open settings
          await openLocationSettings();
        }
        return granted;
      }

      return true;
    } catch (e) {
      print('❌ LocationPermissionHelper: Error in checkAndRequestLocationPermission: $e');
      // Show custom dialog on error
      final userAccepted = await showLocationPermissionDialog(context);
      if (userAccepted) {
        await openLocationSettings();
      }
      return false;
    }
  }

  /// Check location permission and show dialog if needed with callback
  static Future<bool> checkAndRequestLocationPermissionWithCallback(
    BuildContext context, {
    VoidCallback? onPermissionGranted,
  }) async {
    try {
      // First check if location services are enabled
      final isServiceEnabled = await isLocationServiceEnabled();
      if (!isServiceEnabled) {
        // Show custom dialog first
        final userAccepted = await showLocationPermissionDialog(context);
        if (userAccepted) {
          // User accepted, open settings to enable location services
          await openLocationSettings();
        }
        return false;
      }

      // Then check if permission is granted
      final isPermissionGranted = await isLocationPermissionGranted();
      if (!isPermissionGranted) {
        // Show custom dialog first
        final userAccepted = await showLocationPermissionDialog(context);
        if (userAccepted) {
          // User accepted, now request the actual system permission
          final granted = await requestLocationPermission();
          if (!granted) {
            // If permission was denied, open settings
            await openLocationSettings();
          } else {
            // Permission granted, call the callback
            onPermissionGranted?.call();
          }
          return granted;
        }
        return false;
      } else {
        // Permission already granted, call the callback
        onPermissionGranted?.call();
      }

      return true;
    } catch (e) {
      print('❌ LocationPermissionHelper: Error in checkAndRequestLocationPermissionWithCallback: $e');
      // Show custom dialog on error
      final userAccepted = await showLocationPermissionDialog(context);
      if (userAccepted) {
        await openLocationSettings();
      }
      return false;
    }
  }
}
