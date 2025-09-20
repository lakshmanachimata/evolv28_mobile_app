// Example usage of LoggingService.atnUpdateLog() method
// This file shows how to use the atnUpdateLog method for BLE command logging

import 'package:flutter/material.dart';
import 'logging_service.dart';
import '../di/injection_container.dart';

class AtnUpdateLogExample {
  final LoggingService _loggingService = sl<LoggingService>();

  // Example 1: Log BLE command interaction
  Future<void> logBleCommandInteraction() async {
    final command = '#GET_MAC_ID!';
    final response = 'MAC_ID: CB:6F:0F:CB:BE:11';
    final reqTime = DateTime.now().millisecondsSinceEpoch;

    await _loggingService.atnUpdateLog(
      command: command,
      response: response,
      reqTime: reqTime,
    );
  }

  // Example 2: Log program list command
  Future<void> logProgramListCommand() async {
    final command = '7#GFL,5!';
    final response = 'sleep_better.bcu,focus_better.bcu,calm_mind.bcu';
    final reqTime = DateTime.now().millisecondsSinceEpoch;

    await _loggingService.atnUpdateLog(
      command: command,
      response: response,
      reqTime: reqTime,
    );
  }

  // Example 3: Log play command
  Future<void> logPlayCommand() async {
    final command = '#PS,1,sleep_better.bcu,48,5.0,4,10!';
    final response = '#ACK!';
    final reqTime = DateTime.now().millisecondsSinceEpoch;

    await _loggingService.atnUpdateLog(
      command: command,
      response: response,
      reqTime: reqTime,
    );
  }

  // Example 4: Log stop command
  Future<void> logStopCommand() async {
    final command = '#STP!';
    final response = '#ACK!';
    final reqTime = DateTime.now().millisecondsSinceEpoch;

    await _loggingService.atnUpdateLog(
      command: command,
      response: response,
      reqTime: reqTime,
    );
  }

  // Example 5: Log error response
  Future<void> logErrorResponse() async {
    final command = '#INVALID_COMMAND!';
    final response = '#ERROR!';
    final reqTime = DateTime.now().millisecondsSinceEpoch;

    await _loggingService.atnUpdateLog(
      command: command,
      response: response,
      reqTime: reqTime,
    );
  }

  // Example 6: Log multiple commands in sequence
  Future<void> logCommandSequence() async {
    final commands = [
      {'cmd': '#GET_MAC_ID!', 'resp': 'MAC_ID: CB:6F:0F:CB:BE:11'},
      {'cmd': '#ESP32DIS!', 'resp': '#ACK!'},
      {'cmd': '#BSV!', 'resp': '#ACK!'},
      {'cmd': '#GM!', 'resp': '#ACK!'},
      {'cmd': '7#GFL,5!', 'resp': 'sleep_better.bcu,focus_better.bcu'},
    ];

    for (final cmdData in commands) {
      await _loggingService.atnUpdateLog(
        command: cmdData['cmd']!,
        response: cmdData['resp']!,
        reqTime: DateTime.now().millisecondsSinceEpoch,
      );
      
      // Small delay between commands
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  // Example 7: Log with timing information
  Future<void> logWithTiming() async {
    final startTime = DateTime.now().millisecondsSinceEpoch;
    
    // Simulate command execution
    await Future.delayed(const Duration(milliseconds: 500));
    
    final command = '5#SPL!';
    final response = 'sleep_better.bcu';
    final reqTime = startTime;

    await _loggingService.atnUpdateLog(
      command: command,
      response: response,
      reqTime: reqTime,
    );
  }

  // Example 8: Using in a Widget
  Widget buildExampleWidget() {
    return Column(
      children: [
        ElevatedButton(
          onPressed: () async {
            await _loggingService.atnUpdateLog(
              command: '#GET_MAC_ID!',
              response: 'MAC_ID: CB:6F:0F:CB:BE:11',
              reqTime: DateTime.now().millisecondsSinceEpoch,
            );
          },
          child: const Text('Log MAC ID Command'),
        ),
        
        ElevatedButton(
          onPressed: () async {
            await _loggingService.atnUpdateLog(
              command: '7#GFL,5!',
              response: 'sleep_better.bcu,focus_better.bcu',
              reqTime: DateTime.now().millisecondsSinceEpoch,
            );
          },
          child: const Text('Log Program List Command'),
        ),
        
        ElevatedButton(
          onPressed: () async {
            await _loggingService.atnUpdateLog(
              command: '#PS,1,sleep_better.bcu,48,5.0,4,10!',
              response: '#ACK!',
              reqTime: DateTime.now().millisecondsSinceEpoch,
            );
          },
          child: const Text('Log Play Command'),
        ),
      ],
    );
  }

  // Example 9: Log from BluetoothService integration
  Future<void> logFromBluetoothService() async {
    // This would be called from BluetoothService when commands are sent/received
    final command = '#BSV!';
    final response = '#ACK!';
    final reqTime = DateTime.now().millisecondsSinceEpoch;

    // Log the command interaction
    await _loggingService.atnUpdateLog(
      command: command,
      response: response,
      reqTime: reqTime,
    );
  }

  // Example 10: Log with error handling
  Future<void> logWithErrorHandling() async {
    try {
      final command = '#TEST_COMMAND!';
      final response = '#ERROR!';
      final reqTime = DateTime.now().millisecondsSinceEpoch;

      await _loggingService.atnUpdateLog(
        command: command,
        response: response,
        reqTime: reqTime,
      );
    } catch (e) {
      // Handle error appropriately
    }
  }
}

// Example 11: Integration with BluetoothService
class BluetoothServiceIntegration {
  final LoggingService _loggingService = sl<LoggingService>();

  // This method would be called from BluetoothService when sending commands
  Future<void> logCommandSent(String command) async {
    final reqTime = DateTime.now().millisecondsSinceEpoch;
    
    // Store the request time for when we get the response
    // You might want to store this in a map or similar structure
  }

  // This method would be called from BluetoothService when receiving responses
  Future<void> logCommandResponse(String command, String response, int reqTime) async {
    await _loggingService.atnUpdateLog(
      command: command,
      response: response,
      reqTime: reqTime,
    );
  }
}
