import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as ble;
import 'package:permission_handler/permission_handler.dart';

enum BluetoothConnectionState {
  disconnected,
  scanning,
  connecting,
  connected,
  error,
}

class BluetoothService extends ChangeNotifier {
  static final BluetoothService _instance = BluetoothService._internal();
  factory BluetoothService() => _instance;
  BluetoothService._internal();

  BluetoothConnectionState _connectionState = BluetoothConnectionState.disconnected;
  String _statusMessage = 'Connect';
  String _errorMessage = '';
  ble.BluetoothDevice? _connectedDevice;
  List<ble.BluetoothDevice> _scannedDevices = [];
  StreamSubscription<List<ble.ScanResult>>? _scanSubscription;
  Timer? _scanTimer;
  Timer? _countdownTimer;
  int _scanCountdown = 0;
  bool _isExecutingCommands = false;
  bool _isSendingPlayCommands = false;
  bool _isPlaySuccessful = false;
  String _selectedBcuFile = 'Uplift_Mood.bcu'; // Default file
  List<String> _playCommandResponses = [];
  
  // Command handling
  ble.BluetoothService? _uartService;
  ble.BluetoothCharacteristic? _writeCharacteristic;
  ble.BluetoothCharacteristic? _notifyCharacteristic;
  StreamSubscription<List<int>>? _notificationSubscription;
  List<String> _fifthCommandResponses = [];
  bool _isWaitingForFifthCommand = false;

  // Nordic UART Service UUIDs
  static const String nordicUartServiceUUID = '6e400001-b5a3-f393-e0a9-e50e24dcca9e';
  static const String nordicUartWriteCharacteristicUUID = '6e400002-b5a3-f393-e0a9-e50e24dcca9e';
  static const String nordicUartNotifyCharacteristicUUID = '6e400003-b5a3-f393-e0a9-e50e24dcca9e';

  // Getters
  BluetoothConnectionState get connectionState => _connectionState;
  String get statusMessage => _statusMessage;
  String get errorMessage => _errorMessage;
  ble.BluetoothDevice? get connectedDevice => _connectedDevice;
  List<ble.BluetoothDevice> get scannedDevices => _scannedDevices;
  bool get isConnected => _connectionState == BluetoothConnectionState.connected;
  bool get isScanning => _connectionState == BluetoothConnectionState.scanning;
  int get scanCountdown => _scanCountdown;
  bool get isExecutingCommands => _isExecutingCommands;
  bool get isSendingPlayCommands => _isSendingPlayCommands;
  bool get isPlaySuccessful => _isPlaySuccessful;
  String get selectedBcuFile => _selectedBcuFile;
  List<String> get playCommandResponses => _playCommandResponses;

  Future<void> initialize() async {
    // Check permissions
    await _requestPermissions();
    
    // Listen to adapter state changes
    ble.FlutterBluePlus.adapterState.listen((state) {
      if (state == ble.BluetoothAdapterState.on) {
        _clearError();
      } else {
        _setError('Bluetooth is turned off');
      }
    });
  }

  Future<void> _requestPermissions() async {
    try {
      // Request location permission (required for BLE scanning on Android)
      final locationStatus = await Permission.location.request();
      
      if (!locationStatus.isGranted) {
        _setError('Location permission required for Bluetooth scanning');
      }
    } catch (e) {
      _setError('Error requesting permissions: $e');
    }
  }

  Future<void> startScanning() async {
    if (_connectionState == BluetoothConnectionState.scanning) return;

    try {
      // Check if Bluetooth is on
      if (await ble.FlutterBluePlus.adapterState.first != ble.BluetoothAdapterState.on) {
        _setError('Bluetooth is turned off');
        return;
      }

      _connectionState = BluetoothConnectionState.scanning;
      _statusMessage = 'Scanning for devices...';
      _scannedDevices.clear();
      _scanCountdown = 10; // Initialize countdown to 10 seconds
      print('Initialized countdown: $_scanCountdown');
      _clearError();
      notifyListeners();

      // Start scanning for 10 seconds
      await ble.FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 10),
        androidUsesFineLocation: true,
      );

      // Listen to scan results
      _scanSubscription = ble.FlutterBluePlus.scanResults.listen((results) {
        _processScanResults(results);
      });

      // Start countdown timer
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        _scanCountdown--;
        print('Countdown: $_scanCountdown');
        notifyListeners();
        
        if (_scanCountdown <= 0) {
          timer.cancel();
        }
      });

      // Stop scanning after 10 seconds
      _scanTimer = Timer(const Duration(seconds: 10), () {
        _stopScanning();
      });

    } catch (e) {
      _setError('Error starting scan: $e');
    }
  }

  void _processScanResults(List<ble.ScanResult> results) {
    for (final result in results) {
      final device = result.device;
      final deviceName = device.platformName.isNotEmpty 
          ? device.platformName 
          : device.remoteId.toString();

      // Check if it's an Evolv28 device
      if (deviceName.toLowerCase().contains('evolv28')) {
        // Check if device already exists
        final existingIndex = _scannedDevices.indexWhere((d) => d.remoteId == device.remoteId);
        
        if (existingIndex >= 0) {
          // Update existing device
          _scannedDevices[existingIndex] = device;
        } else {
          // Add new device
          _scannedDevices.add(device);
        }
        
        notifyListeners();
      }
    }
  }

  void _stopScanning() {
    _scanSubscription?.cancel();
    ble.FlutterBluePlus.stopScan();
    _scanTimer?.cancel();
    _countdownTimer?.cancel();
    _scanCountdown = 0;

    if (_scannedDevices.isEmpty) {
      _connectionState = BluetoothConnectionState.disconnected;
      _statusMessage = 'No Evolv28 devices found';
      _setError('No Evolv28 devices found nearby');
    } else if (_scannedDevices.length == 1) {
      // Auto-connect to the single device found
      print('✅ Single device found: ${_scannedDevices.first.platformName}');
      print('✅ Auto-connecting and starting command sequence...');
      _connectToDevice(_scannedDevices.first);
    } else {
      _connectionState = BluetoothConnectionState.disconnected;
      _statusMessage = 'Multiple devices found';
      _setError('Multiple Evolv28 devices found. Please select one.');
    }
    
    notifyListeners();
  }

  Future<void> _connectToDevice(ble.BluetoothDevice device) async {
    try {
      print('🔗 Connecting to device: ${device.platformName}');
      _connectionState = BluetoothConnectionState.connecting;
      _statusMessage = 'Connecting...';
      _clearError();
      notifyListeners();

      // Connect to device
      await device.connect(timeout: const Duration(seconds: 10));
      
      _connectedDevice = device;
      _connectionState = BluetoothConnectionState.connected;
      _statusMessage = '${device.platformName} is connected';
      print('✅ Device connected: ${device.platformName}');
      notifyListeners();

      // Start command sequence to get program list
      print('🚀 Starting command sequence to get program list...');
      await _startCommandSequence();

    } catch (e) {
      _setError('Connection failed: $e');
      _connectionState = BluetoothConnectionState.disconnected;
      _statusMessage = 'Connect';
      notifyListeners();
    }
  }

  Future<void> _startCommandSequence() async {
    if (_connectedDevice == null) return;

    try {
      print('📋 Starting command sequence to fetch program list...');
      _isExecutingCommands = true;
      notifyListeners();
      
      // Discover services
      final services = await _connectedDevice!.discoverServices();

      // Find Nordic UART service
      _uartService = services.firstWhere(
        (service) => service.uuid.toString().toLowerCase() == nordicUartServiceUUID.toLowerCase(),
        orElse: () => throw Exception('Nordic UART service not found'),
      );

      // Find write and notify characteristics
      _writeCharacteristic = _uartService!.characteristics.firstWhere(
        (char) => char.uuid.toString().toLowerCase() == nordicUartWriteCharacteristicUUID.toLowerCase(),
        orElse: () => throw Exception('Write characteristic not found'),
      );

      _notifyCharacteristic = _uartService!.characteristics.firstWhere(
        (char) => char.uuid.toString().toLowerCase() == nordicUartNotifyCharacteristicUUID.toLowerCase(),
        orElse: () => throw Exception('Notify characteristic not found'),
      );

      // Enable notifications
      await _notifyCharacteristic!.setNotifyValue(true);

      // Listen to notifications continuously (like reference implementation)
      _notificationSubscription = _notifyCharacteristic!.lastValueStream.listen(
        (value) => _handleNotification(value),
        onError: (error) => _handleError('Notification error: $error'),
      );

      // Send all commands from the reference implementation
      await _sendCommandSequence();

      // Command sequence completed
      _isExecutingCommands = false;
      notifyListeners();

    } catch (e) {
      _isExecutingCommands = false;
      notifyListeners();
      _setError('Command sequence failed: $e');
    }
  }

  Future<void> _sendCommandSequence() async {
    // Commands from the reference implementation
    const List<String> commands = [
      '#GET_MAC_ID!',
      '#ESP32DIS!',
      '#BSV!',
      '#GM!',
      '7#GFL,5!',
      '5#SPL!',
    ];

    print('=== STARTING COMMAND SEQUENCE ===');
    
    for (int i = 0; i < commands.length; i++) {
      final command = commands[i];
      print('Sending command ${i + 1}/${commands.length}: $command');

      // Set flag for 5th command (like reference implementation)
      if (i == 4) {
        _isWaitingForFifthCommand = true;
        _fifthCommandResponses.clear();
      } else {
        _isWaitingForFifthCommand = false;
      }

      // Send command
      await writeCommand(command);

      // Wait for response with timeout, pass command index for special handling
      final response = await _waitForResponse(
        timeout: const Duration(seconds: 10),
        commandIndex: i,
      );

      print('Response ${i + 1}: $response');
      
      // Special handling for the 5th command (7#GFL,5!) to parse program list
      if (i == 4) {
        _parseProgramListResponse(response);
      }
      
      // Small delay between commands
      await Future.delayed(const Duration(milliseconds: 500));
    }
    
    print('=== COMMAND SEQUENCE COMPLETED ===');
  }

  Future<void> writeCommand(String command) async {
    try {
      final commandData = command.codeUnits;
      return await _writeCharacteristic!.write(
        commandData,
        withoutResponse: false,
        allowLongWrite: true,
      );
    } catch (e) {
      _setError('Write characteristic error: $e');
      return;
    }
  }

  Future<String> _waitForResponse({
    required Duration timeout,
    int? commandIndex,
  }) async {
    final completer = Completer<String>();
    Timer? timeoutTimer;
    String? lastResponse;

    // Special handling for 5th command (7#GFL,5!) - accumulate all responses
    if (commandIndex == 4) {
      // 5th command (0-indexed)

      // Set timeout
      timeoutTimer = Timer(timeout, () {
        if (!completer.isCompleted) {
          final fullResponse = _fifthCommandResponses.join('\n');
          completer.complete(
            fullResponse.isNotEmpty
                ? fullResponse
                : 'Timeout - No response received',
          );
        }
      });

      // For the 5th command, wait for the completion signal
      // The responses are being accumulated in _handleNotification
      while (!completer.isCompleted && _fifthCommandResponses.isNotEmpty) {
        // Check if we have received the completion signal
        if (_fifthCommandResponses.any(
          (response) => response.contains('#Completed!'),
        )) {
          // Wait a bit more to ensure all responses are collected
          await Future.delayed(const Duration(milliseconds: 500));
          final fullResponse = _fifthCommandResponses.join('\n');
          print(
            '5th command - Final response with ${_fifthCommandResponses.length} parts',
          );
          completer.complete(fullResponse);
          break;
        }

        // Wait a bit before checking again
        await Future.delayed(const Duration(milliseconds: 100));
      }

      // If we haven't completed yet, use what we have
      if (!completer.isCompleted) {
        final fullResponse = _fifthCommandResponses.join('\n');
        completer.complete(
          fullResponse.isNotEmpty ? fullResponse : 'No responses received',
        );
      }
    } else {
      // Original behavior for other commands
      // Set timeout
      timeoutTimer = Timer(timeout, () {
        if (!completer.isCompleted) {
          completer.complete(lastResponse ?? 'Timeout - No response received');
        }
      });

      // Listen for next notification
      if (_notifyCharacteristic != null) {
        final subscription = _notifyCharacteristic!.lastValueStream.listen(
          (value) {
            if (!completer.isCompleted) {
              lastResponse = String.fromCharCodes(value);
              completer.complete(lastResponse!);
            }
          },
          onError: (error) {
            if (!completer.isCompleted) {
              completer.complete('Error: $error');
            }
          },
        );

        final response = await completer.future;
        timeoutTimer.cancel();
        subscription.cancel();

        return response;
      } else {
        timeoutTimer.cancel();
        return 'Error: Notify characteristic not available';
      }
    }

    // Cancel timeout timer if it's still active
    timeoutTimer.cancel();

    return await completer.future;
  }

  void _handleNotification(List<int> value) {
    // This will be handled by the specific waitForResponse calls
    final stringValue = String.fromCharCodes(value);
    print('=== NOTIFICATION RECEIVED ===');
    print('Raw bytes: $value');
    print('As string: "$stringValue"');
    print('Length: ${value.length}');
    print('=============================');

    // If we're waiting for the 5th command, accumulate the response
    if (_isWaitingForFifthCommand) {
      _fifthCommandResponses.add(stringValue);
      print(
        '5th command - Accumulated response: "$stringValue" (Total: ${_fifthCommandResponses.length})',
      );
    }

    // If we're sending play commands, check for play command responses
    if (_isSendingPlayCommands && stringValue.isNotEmpty) {
      print('🎵 Play command notification received: "$stringValue"');
      
      // Check if this is a response to the last play command (5#SPL!)
      if (stringValue.contains('#SPL,')) {
        print('✅ Received 5#SPL! response: "$stringValue"');
        
        // Parse the response to extract the filename
        final parts = stringValue.split(',');
        print('DEBUG: Response parts count: ${parts.length}');
        
        if (parts.length >= 8) {
          final responseFileName = parts[7]; // Filename is at index 7
          print('DEBUG: Extracted filename: $responseFileName');
          
          // Check if this matches our expected filename
          if (_selectedBcuFile != null && 
              responseFileName.toLowerCase().contains(_selectedBcuFile!.toLowerCase())) {
            _isPlaySuccessful = true;
            _isSendingPlayCommands = false; // Stop showing loader
            print('✅ Play successful! File $_selectedBcuFile found in response: $stringValue');
            print('✅ Extracted filename from response: $responseFileName');
            print('✅ Setting _isPlaySuccessful = true, _isSendingPlayCommands = false');
            print('🎵 Program switched successfully to: $_selectedBcuFile');
            notifyListeners();
          } else {
            print('❌ Filename mismatch: expected $_selectedBcuFile, got $responseFileName');
          }
        } else {
          print('❌ Not enough parts in response: ${parts.length}');
        }
      }
    }
  }

  void _handleError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _parseProgramListResponse(String response) {
    try {
      print('=== PROGRAM LIST RESPONSE ===');
      print('Full response: $response');
      
      // Parse the response to extract .bcu files
      final lines = response.split('\n');
      final programFiles = <String>[];
      
      for (final line in lines) {
        final trimmedLine = line.trim();
        if (trimmedLine.toLowerCase().contains('.bcu')) {
          // Use regex to find all .bcu filenames
          final bcuPattern = RegExp(r'([a-zA-Z0-9_\-\.]+\.bcu)', caseSensitive: false);
          final matches = bcuPattern.allMatches(trimmedLine);
          
          for (final match in matches) {
            String filename = match.group(1) ?? '';
            if (filename.isNotEmpty && filename.length > 4) {
              // Clean up any trailing punctuation
              filename = filename.replaceAll(RegExp(r'[,;:\s]+$'), '');
              if (filename.toLowerCase().endsWith('.bcu')) {
                programFiles.add(filename);
              }
            }
          }
        }
      }
      
      // Remove duplicates and sort
      programFiles.toSet().toList()..sort();
      
      print('Found ${programFiles.length} .bcu program files: $programFiles');
      
      // Convert .bcu files to wellness programs format
      _availablePrograms = _convertBcuFilesToWellnessPrograms(programFiles);
      
      print('Converted to ${_availablePrograms.length} wellness programs: $_availablePrograms');
      
    } catch (e) {
      print('Error parsing program list: $e');
    }
  }

  List<String> _convertBcuFilesToWellnessPrograms(List<String> bcuFiles) {
    final wellnessPrograms = <String>[];
    
    for (final bcuFile in bcuFiles) {
      // Remove .bcu extension
      String programName = bcuFile.replaceAll('.bcu', '');
      
      // Replace underscore with space and convert to title case
      programName = programName.replaceAll('_', ' ');
      programName = _toTitleCase(programName);
      
      // Keep file ID as same as original filename
      String fileId = bcuFile;
      
      // Create formatted program entry
      String formattedProgram = '$programName|$fileId';
      wellnessPrograms.add(formattedProgram);
      
      print('Converted: $bcuFile -> $programName (ID: $fileId)');
    }
    
    return wellnessPrograms;
  }

  String _toTitleCase(String text) {
    if (text.isEmpty) return text;
    
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  List<String> _availablePrograms = [];
  List<String> get availablePrograms => _availablePrograms;
  
  // Helper methods to get program names and IDs
  List<String> get programNames {
    return _availablePrograms.map((program) {
      final parts = program.split('|');
      return parts.isNotEmpty ? parts[0] : '';
    }).toList();
  }
  
  List<String> get programIds {
    return _availablePrograms.map((program) {
      final parts = program.split('|');
      return parts.length > 1 ? parts[1] : '';
    }).toList();
  }
  
  // Get program name by ID
  String getProgramNameById(String id) {
    for (final program in _availablePrograms) {
      final parts = program.split('|');
      if (parts.length > 1 && parts[1] == id) {
        return parts[0];
      }
    }
    return '';
  }
  
  // Get program ID by name
  String getProgramIdByName(String name) {
    for (final program in _availablePrograms) {
      final parts = program.split('|');
      if (parts.isNotEmpty && parts[0] == name) {
        return parts.length > 1 ? parts[1] : '';
      }
    }
    return '';
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = '';
  }

  Future<void> disconnect() async {
    try {
      if (_connectedDevice != null && _connectedDevice!.isConnected) {
        await _connectedDevice!.disconnect();
      }
      
      _connectedDevice = null;
      _connectionState = BluetoothConnectionState.disconnected;
      _statusMessage = 'Connect';
      _scannedDevices.clear();
      _availablePrograms.clear();
      _clearError();
      notifyListeners();
    } catch (e) {
      _setError('Disconnect error: $e');
    }
  }

  // Play command methods
  Future<void> playProgram(String bcuFileName) async {
    if (_connectedDevice == null || _connectionState != BluetoothConnectionState.connected) {
      _setError('Device not connected');
      return;
    }

    try {
      print('🎵 Starting play program: $bcuFileName');
      print('🎵 Previous file: $_selectedBcuFile');
      
      _selectedBcuFile = bcuFileName;
      _isSendingPlayCommands = true;
      _isPlaySuccessful = false;
      _playCommandResponses.clear();
      print('DEBUG: Starting play commands - _isPlaySuccessful: $_isPlaySuccessful, _isSendingPlayCommands: $_isSendingPlayCommands');
      notifyListeners();

      // Generate current timestamp for #ST command
      final now = DateTime.now();
      final timestamp = '${now.year.toString().padLeft(4, '0')}'
          '${now.month.toString().padLeft(2, '0')}'
          '${now.day.toString().padLeft(2, '0')}'
          '${now.hour.toString().padLeft(2, '0')}'
          '${now.minute.toString().padLeft(2, '0')}'
          '${now.second.toString().padLeft(2, '0')}';

      // Generate timestamp for 24#PL command (1 second later)
      final plTime = now.add(const Duration(seconds: 1));
      final plTimestamp = '${plTime.year.toString().padLeft(4, '0')}'
          '${plTime.month.toString().padLeft(2, '0')}'
          '${plTime.day.toString().padLeft(2, '0')}'
          '${plTime.hour.toString().padLeft(2, '0')}'
          '${plTime.minute.toString().padLeft(2, '0')}'
          '${plTime.second.toString().padLeft(2, '0')}';

      print('=== STARTING PLAY COMMANDS ===');
      print('Selected file: $bcuFileName');
      print('Current timestamp: $timestamp');
      print('PL timestamp: $plTimestamp');

      // Create dynamic play commands
      final dynamicPlayCommands = [
        '#BSV!',
        '5#STP!',
        '5#CPS!',
        '#PS,1,$bcuFileName,48,5.0,4,10!',
        '#ST,$timestamp!',
        '#GAIN,27!',
        '24#PL,3341,$plTimestamp,!',
        '5#SPL!',
      ];

      for (int i = 0; i < dynamicPlayCommands.length; i++) {
        final command = dynamicPlayCommands[i];
        print('Sending play command ${i + 1}/${dynamicPlayCommands.length}: $command');

        // Send command
        await writeCommand(command);

        // Wait for response
        final response = await _waitForPlayCommandResponse(
          timeout: const Duration(seconds: 10),
        );

        // Add command response
        _playCommandResponses.add('$command -> $response');
        print('Play command response: $command -> $response');

        notifyListeners();

        // Special delay for #ST command - wait 1 second before sending 24#PL
        if (command.startsWith('#ST,')) {
          print('Waiting 1 second before sending 24#PL command...');
          await Future.delayed(const Duration(seconds: 1));
        } else {
          // Small delay between other commands
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }

      _isSendingPlayCommands = false;
      print('=== PLAY COMMANDS COMPLETED ===');
      print('File: $bcuFileName');
      print('Total responses: ${_playCommandResponses.length}');
      print('DEBUG: Final state - _isPlaySuccessful: $_isPlaySuccessful, _isSendingPlayCommands: $_isSendingPlayCommands');
      notifyListeners();

    } catch (e) {
      _isSendingPlayCommands = false;
      _setError('Play commands error: $e');
    }
  }

  Future<String> _waitForPlayCommandResponse({
    required Duration timeout,
  }) async {
    final completer = Completer<String>();
    Timer? timeoutTimer;
    String? lastResponse;

    // Set timeout
    timeoutTimer = Timer(timeout, () {
      if (!completer.isCompleted) {
        completer.complete(lastResponse ?? 'Timeout - No response received');
      }
    });

    // Use a simple delay approach instead of creating a new subscription
    // The _handleNotification method will handle the response
    await Future.delayed(const Duration(milliseconds: 1000));
    
    // For now, return a placeholder - the actual response will be handled
    // by the existing notification system
    timeoutTimer.cancel();
    return 'Response handled by existing notification system';
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    _scanTimer?.cancel();
    _countdownTimer?.cancel();
    _notificationSubscription?.cancel();
    super.dispose();
  }
}
