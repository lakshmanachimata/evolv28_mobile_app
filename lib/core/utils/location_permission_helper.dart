import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';

class LocationPermissionHelper {
  /// Check if location permission is granted
  static Future<bool> isLocationPermissionGranted() async {
    try {
      final status = await Permission.location.status;
      return status.isGranted;
    } catch (e) {
      print('❌ LocationPermissionHelper: Error checking location permission: $e');
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
      final status = await Permission.location.request();
      return status.isGranted;
    } catch (e) {
      print('❌ LocationPermissionHelper: Error requesting location permission: $e');
      return false;
    }
  }

  /// Open system location settings
  static Future<void> openLocationSettings() async {
    try {
      await openAppSettings();
    } catch (e) {
      print('❌ LocationPermissionHelper: Error opening app settings: $e');
    }
  }

  /// Show location permission dialog
  static Future<bool> showLocationPermissionDialog(BuildContext context) async {
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
                Icons.location_on,
                color: const Color(0xFFF17961),
                size: 28,
              ),
              const SizedBox(width: 12),
              const Text(
                'Location Permission',
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
                'Evolv28 needs access to your device\'s location to find and connect to your Evolv28 device.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 12),
              Text(
                'This permission is required for device discovery and connection.',
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
          }
          return granted;
        }
        return false;
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
}
