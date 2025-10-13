import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/routing/app_router_config.dart';
import '../../core/services/bluetooth_service.dart';

class DeviceDisconnectedPopup {
  static void show(BuildContext context, String deviceName) {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          title: const Text(
            'Device Disconnected',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
          content: Text(
            '$deviceName is disconnected from the app, please connect again',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          actions: [
            Center(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Close the dialog
                    Navigator.of(context).pop();
                    
                    // Navigate to dashboard and start scanning
                    navigateToDashboardAndScan(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF07A60), // Orange color
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  child: const Text(
                    'OK',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  static void navigateToDashboardAndScan(BuildContext context) {
    // Navigate to dashboard
    context.go(AppRoutes.dashboard);
    
    // Start scanning for devices after navigation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bluetoothService = BluetoothService();
      bluetoothService.startScanning();
    });
  }
}
