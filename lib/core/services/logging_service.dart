import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../constants/api_constants.dart';
import '../di/injection_container.dart';
import 'bluetooth_service.dart';

class LoggingService {
  static final LoggingService _instance = LoggingService._internal();
  factory LoggingService() => _instance;
  LoggingService._internal();

  final Dio _dio = Dio();

  /// Send logs to the server
  /// 
  /// [event] - The event name/type
  /// [status] - 'success' or 'failed'
  /// [notes] - Optional additional notes
  Future<void> sendLogs({
    required String event,
    required String status,
    String? notes,
  }) async {
    try {
      print('📝 LoggingService: Sending log - Event: $event, Status: $status');
      
      // Get stored token and user ID for authorization
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('user_token') ?? '';
      final userId = prefs.getString('user_id') ?? '';
      
      if (token.isEmpty || userId.isEmpty) {
        print('📝 LoggingService: No token or user ID found, skipping log');
        return;
      }

      final payload = {
        'event': event,
        'status': status,
        if (notes != null) 'notes': notes,
      };

      final response = await _dio.post(
        '${ApiConstants.baseUrl}${ApiConstants.deviceTroubleshotLog}',
        options: Options(
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
            'authorization': token,
          },
        ),
        data: {
          'user_id': userId,
          'data': payload,
        },
      );

      print('📝 LoggingService: Log sent successfully - Status: ${response.statusCode}');
    } catch (e) {
      print('📝 LoggingService: Error sending log: $e');
      // Don't throw error - logging should not break the app flow
    }
  }

  /// Convenience method for success logs
  Future<void> logSuccess({
    required String event,
    String? notes,
  }) async {
    await sendLogs(
      event: event,
      status: 'success',
      notes: notes,
    );
  }

  /// Convenience method for failed logs
  Future<void> logFailed({
    required String event,
    String? notes,
  }) async {
    await sendLogs(
      event: event,
      status: 'failed',
      notes: notes,
    );
  }

  /// Log Bluetooth operations
  Future<void> logBluetoothOperation({
    required String operation,
    required bool success,
    String? deviceName,
    String? errorMessage,
  }) async {
    await sendLogs(
      event: 'bluetooth_$operation',
      status: success ? 'success' : 'failed',
      notes: success 
        ? (deviceName != null ? 'Device: $deviceName' : null)
        : errorMessage,
    );
  }

  /// Log authentication events
  Future<void> logAuthEvent({
    required String event,
    required bool success,
    String? notes,
  }) async {
    await sendLogs(
      event: 'auth_$event',
      status: success ? 'success' : 'failed',
      notes: notes,
    );
  }

  /// Log permission events
  Future<void> logPermissionEvent({
    required String permission,
    required bool granted,
    String? notes,
  }) async {
    await sendLogs(
      event: 'permission_$permission',
      status: granted ? 'success' : 'failed',
      notes: notes,
    );
  }

  /// Log program playback events
  Future<void> logProgramPlayback({
    required String programName,
    required bool success,
    String? notes,
  }) async {
    await sendLogs(
      event: 'program_playback',
      status: success ? 'success' : 'failed',
      notes: 'Program: $programName${notes != null ? ', $notes' : ''}',
    );
  }

  /// Add custom log with flexible body data
  /// 
  /// [body] - The data to send in the request body
  /// Returns the response from the server
  Future<dynamic> addLog(dynamic body) async {
    try {
      print('📝 LoggingService: Adding custom log');
      
      // Get stored token for authorization
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('user_token') ?? '';
      
      if (token.isEmpty) {
        print('📝 LoggingService: No token found, skipping log');
        return null;
      }

      final response = await _dio.post(
        '${ApiConstants.baseUrl}${ApiConstants.logsNewInsert}',
        options: Options(
          headers: {
            'authorization': token,
          },
        ),
        data: body,
      );

      print('📝 LoggingService: Custom log added successfully - Status: ${response.statusCode}');
      print('📝 LoggingService: Response data: ${response.data}');
      
      return response.data;
    } catch (e) {
      print('📝 LoggingService: Error adding custom log: $e');
      if (e is DioException) {
        if (e.response != null) {
          print('📝 LoggingService: Server error: ${e.response!.statusCode}');
          print('📝 LoggingService: Server response: ${e.response!.data}');
          return e.response!.data;
        }
      }
      rethrow;
    }
  }

  /// Update log for BLE command interactions with location and device details
  /// 
  /// [command] - The BLE command that was sent
  /// [response] - The response received from the device
  /// [reqTime] - The timestamp when the request was made
  /// [includeLocation] - Whether to include location data (default: true)
  Future<void> sendBleCommandLog({
    required String command,
    required String response,
    required int reqTime,
    bool includeLocation = true,
  }) async {
    try {
      print('📝 LoggingService: Updating BLE command log');
      
      // Get stored user data
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString('user_data');
      final token = prefs.getString('user_token') ?? '';
      
      if (userDataString == null || token.isEmpty) {
        print('📝 LoggingService: No user data or token found, skipping log');
        return;
      }

      final userData = jsonDecode(userDataString);
      final user = userData['data'];
      
      if (user == null) {
        print('📝 LoggingService: Invalid user data, skipping log');
        return;
      }

      // Get location permission and coordinates (non-blocking)
      Map<String, double>? coords;
      if (includeLocation) {
        try {
          final hasLocationPermission = await _checkLocationPermission();
          if (hasLocationPermission) {
            // Use a timeout to prevent blocking the logging process
            coords = await _getCurrentLocation().timeout(
              const Duration(seconds: 2), // Reduced timeout
              onTimeout: () {
                print('📝 LoggingService: Location request timed out, continuing without location');
                return null;
              },
            );
          }
        } catch (e) {
          print('📝 LoggingService: Error getting location: $e');
          // Continue without location data
          coords = null;
        }
      }

      // Get device MAC ID from Bluetooth service
      final deviceMacId = await _getDeviceMacId();

      // Get current timezone in proper format (e.g., Asia/Kolkata)
      // For now, defaulting to Asia/Kolkata as per the example
      final currentTimeZone = 'Asia/Kolkata';
      
      // Calculate response time in milliseconds since epoch
      final responseTime = DateTime.now().millisecondsSinceEpoch;

      // Build log body matching the example structure
      final body = {
        'userid': user['id'] ?? user['userId'],
        'timezone': currentTimeZone,
        'log': [
          {
            'cmdrequest': command,
            'msg': command,
            'sessionid': user['sessid'] ?? user['sessionId'] ?? '',
            'devicemac': deviceMacId,
            'resptime': responseTime,
            'reqtime': reqTime,
            'cmdresponse': response,
            'location': coords != null 
              ? "{'latitude': ${coords['latitude']}, 'longitude': ${coords['longitude']}}"
              : "{'latitude': undefined, 'longitude': undefined}",
          },
        ],
      };

      // Send log using addLog method
      await addLog(body);
      
      print('📝 LoggingService: BLE command log updated successfully');
    } catch (e) {
      print('📝 LoggingService: Error updating BLE command log: $e');
      // Don't rethrow - logging should not break the app flow
    }
  }

  /// Check if location permission is granted
  Future<bool> _checkLocationPermission() async {
    try {
      final permission = await Geolocator.checkPermission();
      return permission == LocationPermission.whileInUse || 
             permission == LocationPermission.always;
    } catch (e) {
      print('📝 LoggingService: Error checking location permission: $e');
      return false;
    }
  }

  /// Get current location coordinates
  Future<Map<String, double>?> _getCurrentLocation() async {
    try {
      // Try to get last known position first (faster)
      final lastKnownPosition = await Geolocator.getLastKnownPosition();
      if (lastKnownPosition != null) {
        return {
          'latitude': lastKnownPosition.latitude,
          'longitude': lastKnownPosition.longitude,
        };
      }

      // If no last known position, try to get current position with shorter timeout
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low, // Use low accuracy for faster response
        timeLimit: const Duration(seconds: 2), // Reduced timeout
      );
      
      return {
        'latitude': position.latitude,
        'longitude': position.longitude,
      };
    } catch (e) {
      print('📝 LoggingService: Error getting current location: $e');
      return null;
    }
  }

  /// Get device MAC ID from Bluetooth service
  Future<String> _getDeviceMacId() async {
    try {
      // Get BluetoothService instance to access device MAC ID
      final bluetoothService = BluetoothService();
      
      // Check if device is connected and get MAC ID
      if (bluetoothService.isConnected && bluetoothService.connectedDevice != null) {
        final device = bluetoothService.connectedDevice!;
        return device.remoteId.toString();
      }
      
      return '';
    } catch (e) {
      print('📝 LoggingService: Error getting device MAC ID: $e');
      return '';
    }
  }
}
