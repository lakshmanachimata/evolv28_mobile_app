// Example usage of LoggingService.addLog() method
// This file shows how to use the addLog method for custom logging

import 'package:flutter/material.dart';
import 'logging_service.dart';
import '../di/injection_container.dart';

class AddLogExample {
  final LoggingService _loggingService = sl<LoggingService>();

  // Example 1: Simple object logging
  Future<void> simpleObjectLogging() async {
    final logData = {
      'action': 'user_login',
      'timestamp': DateTime.now().toIso8601String(),
      'device_info': {
        'platform': 'android',
        'version': '1.0.0',
      },
      'user_data': {
        'user_id': '12345',
        'email': 'user@example.com',
      },
    };

    try {
      final response = await _loggingService.addLog(logData);
      print('Log added successfully: $response');
    } catch (e) {
      print('Error adding log: $e');
    }
  }

  // Example 2: Array logging
  Future<void> arrayLogging() async {
    final logData = [
      {
        'event': 'button_click',
        'screen': 'dashboard',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
      {
        'event': 'navigation',
        'from': 'dashboard',
        'to': 'programs',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    ];

    try {
      final response = await _loggingService.addLog(logData);
      print('Array log added successfully: $response');
    } catch (e) {
      print('Error adding array log: $e');
    }
  }

  // Example 3: String logging
  Future<void> stringLogging() async {
    final logData = 'Simple string log message';

    try {
      final response = await _loggingService.addLog(logData);
      print('String log added successfully: $response');
    } catch (e) {
      print('Error adding string log: $e');
    }
  }

  // Example 4: Complex nested object
  Future<void> complexObjectLogging() async {
    final logData = {
      'session': {
        'session_id': 'sess_12345',
        'start_time': DateTime.now().toIso8601String(),
        'user_agent': 'Evolv28App/1.0.0',
      },
      'events': [
        {
          'type': 'bluetooth_scan',
          'duration': 10000,
          'devices_found': 2,
          'success': true,
        },
        {
          'type': 'device_connect',
          'device_name': 'evolv28-CBBE11',
          'success': true,
          'connection_time': 2500,
        },
      ],
      'performance': {
        'memory_usage': '45MB',
        'cpu_usage': '12%',
        'battery_level': 85,
      },
    };

    try {
      final response = await _loggingService.addLog(logData);
      print('Complex log added successfully: $response');
    } catch (e) {
      print('Error adding complex log: $e');
    }
  }

  // Example 5: Error logging
  Future<void> errorLogging() async {
    final logData = {
      'error_type': 'connection_timeout',
      'error_message': 'Failed to connect to device after 10 seconds',
      'error_code': 'BLE_TIMEOUT',
      'timestamp': DateTime.now().toIso8601String(),
      'context': {
        'device_name': 'evolv28-CBBE11',
        'retry_count': 3,
        'last_successful_connection': '2025-01-20T10:30:00Z',
      },
      'stack_trace': 'Connection timeout at BluetoothService._connectToDevice:216',
    };

    try {
      final response = await _loggingService.addLog(logData);
      print('Error log added successfully: $response');
    } catch (e) {
      print('Error adding error log: $e');
    }
  }

  // Example 6: Analytics logging
  Future<void> analyticsLogging() async {
    final logData = {
      'analytics': {
        'event_name': 'program_played',
        'properties': {
          'program_name': 'Sleep Better',
          'duration': 600, // seconds
          'volume_level': 80,
          'user_satisfaction': 5, // rating out of 5
        },
        'user_properties': {
          'age_group': '25-34',
          'gender': 'male',
          'subscription_type': 'premium',
        },
        'session_properties': {
          'session_duration': 1800, // seconds
          'programs_played_today': 3,
          'total_session_time': 5400, // seconds
        },
      },
    };

    try {
      final response = await _loggingService.addLog(logData);
      print('Analytics log added successfully: $response');
    } catch (e) {
      print('Error adding analytics log: $e');
    }
  }

  // Example 7: Using in a Widget
  Widget buildExampleWidget() {
    return Column(
      children: [
        ElevatedButton(
          onPressed: () async {
            final logData = {
              'action': 'button_press',
              'button_name': 'example_button',
              'timestamp': DateTime.now().toIso8601String(),
            };
            
            try {
              final response = await _loggingService.addLog(logData);
              print('Button press logged: $response');
            } catch (e) {
              print('Error logging button press: $e');
            }
          },
          child: const Text('Log Button Press'),
        ),
        
        ElevatedButton(
          onPressed: () async {
            final logData = {
              'action': 'screen_view',
              'screen_name': 'example_screen',
              'timestamp': DateTime.now().toIso8601String(),
              'user_id': '12345',
            };
            
            try {
              final response = await _loggingService.addLog(logData);
              print('Screen view logged: $response');
            } catch (e) {
              print('Error logging screen view: $e');
            }
          },
          child: const Text('Log Screen View'),
        ),
      ],
    );
  }

  // Example 8: Batch logging
  Future<void> batchLogging() async {
    final logs = [
      {
        'type': 'app_start',
        'timestamp': DateTime.now().toIso8601String(),
      },
      {
        'type': 'permission_check',
        'permission': 'location',
        'granted': true,
        'timestamp': DateTime.now().toIso8601String(),
      },
      {
        'type': 'bluetooth_scan',
        'devices_found': 1,
        'scan_duration': 10000,
        'timestamp': DateTime.now().toIso8601String(),
      },
    ];

    try {
      final response = await _loggingService.addLog(logs);
      print('Batch logs added successfully: $response');
    } catch (e) {
      print('Error adding batch logs: $e');
    }
  }
}
