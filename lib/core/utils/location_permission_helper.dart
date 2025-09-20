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
      return false;
    }
  }

  /// Check if location services are enabled
  static Future<bool> isLocationServiceEnabled() async {
    try {
      return await Geolocator.isLocationServiceEnabled();
    } catch (e) {
      return false;
    }
  }

  /// Request location permission
  static Future<bool> requestLocationPermission() async {
    try {
      final status = await Permission.location.request();
      return status.isGranted;
    } catch (e) {
      return false;
    }
  }

  /// Open system location settings
  static Future<void> openLocationSettings() async {
    try {
      await openAppSettings();
    } catch (e) {
    }
  }

  /// Show location permission dialog
  static Future<void> showLocationPermissionDialog(BuildContext context) async {
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
                Icons.location_off,
                color: Colors.orange,
                size: 28,
              ),
              const SizedBox(width: 12),
              const Text(
                'Location Required',
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
                'Location access is required for this app to function properly.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 12),
              Text(
                'Please enable location services in your device settings.',
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
                openLocationSettings();
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

  /// Check location permission and show dialog if needed
  static Future<bool> checkAndRequestLocationPermission(BuildContext context) async {
    try {
      // First check if location services are enabled
      final isServiceEnabled = await isLocationServiceEnabled();
      if (!isServiceEnabled) {
        await showLocationPermissionDialog(context);
        return false;
      }

      // Then check if permission is granted
      final isPermissionGranted = await isLocationPermissionGranted();
      if (!isPermissionGranted) {
        // Try to request permission first
        final granted = await requestLocationPermission();
        if (!granted) {
          // If permission was denied, show dialog to open settings
          await showLocationPermissionDialog(context);
          return false;
        }
      }

      return true;
    } catch (e) {
      await showLocationPermissionDialog(context);
      return false;
    }
  }
}
