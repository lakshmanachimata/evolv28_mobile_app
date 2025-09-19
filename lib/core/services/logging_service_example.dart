// Example usage of LoggingService
// This file shows how to use the LoggingService throughout your app

import 'package:flutter/material.dart';
import 'logging_service.dart';
import '../di/injection_container.dart';

class LoggingServiceExample {
  final LoggingService _loggingService = sl<LoggingService>();

  // Example 1: Basic logging
  Future<void> basicLoggingExample() async {
    // Log a success event
    await _loggingService.sendLogs(
      event: 'user_login',
      status: 'success',
      notes: 'User logged in successfully',
    );

    // Log a failed event
    await _loggingService.sendLogs(
      event: 'api_call',
      status: 'failed',
      notes: 'Network timeout error',
    );
  }

  // Example 2: Using convenience methods
  Future<void> convenienceMethodsExample() async {
    // Log success
    await _loggingService.logSuccess(
      event: 'data_sync',
      notes: 'Data synchronized successfully',
    );

    // Log failure
    await _loggingService.logFailed(
      event: 'file_upload',
      notes: 'File size too large',
    );
  }

  // Example 3: Bluetooth operations
  Future<void> bluetoothLoggingExample() async {
    // Log successful Bluetooth connection
    await _loggingService.logBluetoothOperation(
      operation: 'connect',
      success: true,
      deviceName: 'evolv28-CBBE11',
    );

    // Log failed Bluetooth scan
    await _loggingService.logBluetoothOperation(
      operation: 'scan',
      success: false,
      errorMessage: 'Permission denied',
    );
  }

  // Example 4: Authentication events
  Future<void> authLoggingExample() async {
    // Log successful login
    await _loggingService.logAuthEvent(
      event: 'login',
      success: true,
      notes: 'Email: user@example.com',
    );

    // Log failed OTP validation
    await _loggingService.logAuthEvent(
      event: 'otp_validation',
      success: false,
      notes: 'Invalid OTP code',
    );
  }

  // Example 5: Permission events
  Future<void> permissionLoggingExample() async {
    // Log granted permission
    await _loggingService.logPermissionEvent(
      permission: 'location',
      granted: true,
      notes: 'While in use',
    );

    // Log denied permission
    await _loggingService.logPermissionEvent(
      permission: 'bluetooth_scan',
      granted: false,
      notes: 'User denied',
    );
  }

  // Example 6: Program playback events
  Future<void> programPlaybackLoggingExample() async {
    // Log successful program playback
    await _loggingService.logProgramPlayback(
      programName: 'Sleep Better',
      success: true,
      notes: 'Duration: 10 minutes',
    );

    // Log failed program playback
    await _loggingService.logProgramPlayback(
      programName: 'Focus Better',
      success: false,
      notes: 'Device disconnected',
    );
  }

  // Example 7: Custom events
  Future<void> customEventsExample() async {
    // Log custom app events
    await _loggingService.sendLogs(
      event: 'app_startup',
      status: 'success',
      notes: 'App launched successfully',
    );

    await _loggingService.sendLogs(
      event: 'settings_changed',
      status: 'success',
      notes: 'Volume level changed to 80%',
    );

    await _loggingService.sendLogs(
      event: 'error_occurred',
      status: 'failed',
      notes: 'Unexpected error in main thread',
    );
  }

  // Example 8: Using in a Widget
  Widget buildExampleWidget() {
    return ElevatedButton(
      onPressed: () async {
        // Log button press
        await _loggingService.sendLogs(
          event: 'button_press',
          status: 'success',
          notes: 'User pressed example button',
        );
        
        // Do something
        print('Button pressed!');
      },
      child: const Text('Example Button'),
    );
  }
}

// Example 9: Error handling wrapper
class LoggingWrapper {
  final LoggingService _loggingService = sl<LoggingService>();

  Future<T> executeWithLogging<T>({
    required String event,
    required Future<T> Function() operation,
    String? notes,
  }) async {
    try {
      final result = await operation();
      
      // Log success
      await _loggingService.logSuccess(
        event: event,
        notes: notes,
      );
      
      return result;
    } catch (e) {
      // Log failure
      await _loggingService.logFailed(
        event: event,
        notes: 'Error: ${e.toString()}',
      );
      
      rethrow;
    }
  }
}
