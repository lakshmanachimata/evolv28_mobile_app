# LoggingService

A service for sending logs to the server for troubleshooting and analytics purposes.

## Overview

The `LoggingService` provides a centralized way to send logs to the server using the `/devicetroubleshotlog` API endpoint. It automatically handles authentication using stored user tokens and provides convenient methods for common logging scenarios.

## Features

- **Automatic Authentication**: Uses stored user token and user ID from SharedPreferences
- **Convenience Methods**: Pre-built methods for common scenarios (Bluetooth, Auth, Permissions, etc.)
- **Error Handling**: Logging failures won't break your app flow
- **Singleton Pattern**: Single instance throughout the app
- **Dependency Injection**: Registered in the DI container

## Basic Usage

### 1. Get the Service Instance

```dart
import '../../core/services/logging_service.dart';
import '../../core/di/injection_container.dart';

final LoggingService _loggingService = sl<LoggingService>();
```

### 2. Basic Logging

```dart
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
```

### 3. Convenience Methods

```dart
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
```

## Specialized Logging Methods

### Bluetooth Operations

```dart
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
```

### Authentication Events

```dart
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
```

### Permission Events

```dart
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
```

### Program Playback Events

```dart
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
```

## API Reference

### Core Method

```dart
Future<void> sendLogs({
  required String event,      // Event name/type
  required String status,     // 'success' or 'failed'
  String? notes,              // Optional additional notes
})
```

### Convenience Methods

```dart
Future<void> logSuccess({required String event, String? notes})
Future<void> logFailed({required String event, String? notes})
```

### Specialized Methods

```dart
Future<void> logBluetoothOperation({
  required String operation,
  required bool success,
  String? deviceName,
  String? errorMessage,
})

Future<void> logAuthEvent({
  required String event,
  required bool success,
  String? notes,
})

Future<void> logPermissionEvent({
  required String permission,
  required bool granted,
  String? notes,
})

Future<void> logProgramPlayback({
  required String programName,
  required bool success,
  String? notes,
})
```

## Error Handling

The service is designed to be fail-safe:

- If no token or user ID is found, logging is skipped silently
- Network errors are caught and logged to console but don't throw exceptions
- Logging failures won't break your app flow

## Best Practices

1. **Use Descriptive Event Names**: Use clear, descriptive event names like `user_login`, `bluetooth_connect`, `permission_location`

2. **Include Relevant Context**: Add notes that provide context about what happened

3. **Log Both Success and Failure**: Log both successful and failed operations for better analytics

4. **Use Appropriate Methods**: Use specialized methods when available (e.g., `logBluetoothOperation` instead of generic `sendLogs`)

5. **Don't Log Sensitive Data**: Avoid logging passwords, tokens, or other sensitive information

## Example Integration

```dart
class MyViewModel extends ChangeNotifier {
  final LoggingService _loggingService = sl<LoggingService>();

  Future<void> performOperation() async {
    try {
      // Perform your operation
      await someAsyncOperation();
      
      // Log success
      await _loggingService.logSuccess(
        event: 'operation_completed',
        notes: 'Operation completed successfully',
      );
    } catch (e) {
      // Log failure
      await _loggingService.logFailed(
        event: 'operation_failed',
        notes: 'Error: ${e.toString()}',
      );
      
      rethrow;
    }
  }
}
```

## Server API

The service sends logs to: `POST /devicetroubleshotlog`

**Request Body:**
```json
{
  "user_id": "string",
  "data": {
    "event": "string",
    "status": "success|failed",
    "notes": "string (optional)"
  }
}
```

**Headers:**
```
Accept: application/json
Content-Type: application/json
authorization: <user_token>
```
