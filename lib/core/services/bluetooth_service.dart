import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as ble;
import 'package:permission_handler/permission_handler.dart';

import '../di/injection_container.dart';
import 'logging_service.dart';
import 'native_bluetooth_service.dart';

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

  final LoggingService _loggingService = sl<LoggingService>();

  BluetoothConnectionState _connectionState =
      BluetoothConnectionState.disconnected;
  String _statusMessage = 'Connect';
  String _errorMessage = '';
  ble.BluetoothDevice? _connectedDevice;
  List<ble.BluetoothDevice> _scannedDevices = [];
  Map<String, int> _deviceRssiMap = {}; // Store RSSI for each device
  StreamSubscription<List<ble.ScanResult>>? _scanSubscription;
  Timer? _scanTimer;
  Timer? _countdownTimer;
  int _scanCountdown = 0;
  bool _isExecutingCommands = false;
  bool _isSendingPlayCommands = false;
  bool _isPlaySuccessful = false;
  String _selectedBcuFile = 'Uplift_Mood.bcu'; // Default file
  String? _currentPlayingFile; // Currently playing file from player status
  List<String> _playCommandResponses = [];

  // Command handling
  ble.BluetoothService? _uartService;
  ble.BluetoothCharacteristic? _writeCharacteristic;
  ble.BluetoothCharacteristic? _notifyCharacteristic;
  StreamSubscription<List<int>>? _notificationSubscription;
  StreamSubscription<ble.BluetoothConnectionState>?
  _connectionStateSubscription;
  List<String> _fifthCommandResponses = [];
  bool _isWaitingForFifthCommand = false;
  Completer<String?>? _playerStatusCompleter;
  Completer<bool>? _stopCommandCompleter;
  Completer<String>? _responseCompleter;
  String? _lastNotificationResponse;

  // Command logging tracking
  String? _pendingCommandForLogging;
  DateTime? _pendingCommandTimestamp;

  // User devices for validation
  List<dynamic> _userDevices = [];

  // Callback for unknown devices
  Function(List<Map<String, dynamic>>)? _onUnknownDevicesFound;

  // Callback for when no devices are found
  VoidCallback? _onNoDevicesFound;

  // Callback for device disconnection
  Function(String deviceName)? _onDeviceDisconnected;

  // WiFi and Download callbacks
  Function(List<String>)? _onWifiListReceived;
  Function(bool)? _onWifiConnected;
  Function(int)? _onDownloadProgress;
  Function(bool)? _onDownloadComplete;
  Function(String)? _onWifiError;
  Function(String)? _onWifiEnableResponse;
  Function(String)?
  _onWifiConnectionResponse; // For #ESP,47,01! and #ESP,47,06!
  Function(String)?
  _onWifiStatusResponse; // For #WIFI_CONNECTED! and #WIFI_DIS_CONNECTED!

  // Download status callbacks
  Function(String)?
  _onDownloadStatusResponse; // For all download status responses
  Function(int)? _onDownloadProgressUpdate; // For download progress percentage
  Function(String, int)?
  _onDownloadProgressWithFilename; // For progress with filename

  // WiFi list storage
  List<String> _wifiList = [];
  bool _wifiScanCompleted = false; // Flag to prevent multiple callbacks

  // Nordic UART Service UUIDs
  static const String nordicUartServiceUUID =
      '6e400001-b5a3-f393-e0a9-e50e24dcca9e';
  static const String nordicUartWriteCharacteristicUUID =
      '6e400002-b5a3-f393-e0a9-e50e24dcca9e';
  static const String nordicUartNotifyCharacteristicUUID =
      '6e400003-b5a3-f393-e0a9-e50e24dcca9e';

  // WiFi and Download Command constants
  static const String DISABLE_WIFI = "#ESP32DIS!";
  static const String ENABLE_WIFI = "#ESP32CON!";
  static const String WIFI_SCAN = "#020Cmd:39WIFI_SCAN!";
  static const String WIFI_CONNECT = "#023Cmd:37WIFI_CONNECT!";
  static const String WIFI_STATUS = "#WIFISTAT!";

  // WiFi connection response codes
  static const String WIFI_CONNECTED = "#WIFI_CONNECTED!";
  static const String WIFI_DISCONNECTED = "#WIFI_DIS_CONNECTED!";
  static const String WIFI_CREDENTIALS_MATCH = "#ESP,47,01!";
  static const String WIFI_CREDENTIALS_MISMATCH = "#ESP,47,06!";
  static const String PASSWORD_ACCEPTED = "#ESP,42,01!";

  // Download status constants
  static const String DOWNLOAD_SUCCESS =
      "#ESP,40,01!"; // Successfully Downloaded
  static const String DOWNLOAD_INTERNET_ERROR =
      "#ESP,40,02!"; // Internet not Available
  static const String DOWNLOAD_SD_CARD_ERROR = "#ESP,40,03!"; // SD card error
  static const String DOWNLOAD_WRONG_LINK =
      "#ESP,40,04!"; // Download fail, wrong link
  static const String DOWNLOAD_LINK_RECEIVED = "#ESP,40,05!"; // Link Received
  static const String DOWNLOAD_WIFI_CONNECT_ERROR =
      "#ESP,40,06!"; // Wifi Connect error
  static const String DOWNLOAD_SOCKET_CLOSED =
      "#ESP,40,07!"; // Socket closed during download
  static const String DOWNLOAD_UNSTABLE_NETWORK =
      "#ESP,40,08!"; // Unstable network cause download failure
  static const String DOWNLOAD_FORBIDDEN_ERROR =
      "#ESP,40,403!"; // file forbidden_error
  static const String DOWNLOAD_FILE_LINK_ERROR =
      "#ESP,40,404!"; // file link error
  static const String DOWNLOAD_FILE_LENGTH_ERROR =
      "#ESP,40,11!"; // FILE_LENGTH_ERROR
  static const String DOWNLOAD_PROGRESS =
      "#ESP,50,"; // Download progress percentage
  static const String DOWNLOAD_STATUS_COMMAND =
      "#DOWNLOAD_STATUS!"; // Command to get download status

  // Getters
  BluetoothConnectionState get connectionState => _connectionState;
  String get statusMessage => _statusMessage;
  String get errorMessage => _errorMessage;
  ble.BluetoothDevice? get connectedDevice => _connectedDevice;
  List<ble.BluetoothDevice> get scannedDevices => _scannedDevices;
  bool get isConnected =>
      _connectionState == BluetoothConnectionState.connected;
  bool get isScanning => _connectionState == BluetoothConnectionState.scanning;
  int get scanCountdown => _scanCountdown;
  bool get isExecutingCommands => _isExecutingCommands;
  bool get isSendingPlayCommands => _isSendingPlayCommands;
  bool get isPlaySuccessful => _isPlaySuccessful;
  String get selectedBcuFile => _selectedBcuFile;
  String? get currentPlayingFile => _currentPlayingFile;
  List<String> get playCommandResponses => _playCommandResponses;
  List<dynamic> get userDevices => _userDevices;

  // Get RSSI for a specific device
  int getDeviceRssi(ble.BluetoothDevice device) {
    return _deviceRssiMap[device.remoteId.toString()] ??
        -100; // Default to -100 if not found
  }

  // Calculate signal strength percentage from RSSI
  int _calculateSignalStrength(int rssi) {
    // RSSI ranges from -100 (weak) to -30 (strong)
    // Convert to percentage (0-100)
    if (rssi >= -30) return 100;
    if (rssi <= -100) return 0;

    // Linear interpolation between -100 and -30
    return ((rssi + 100) * 100 / 70).round().clamp(0, 100);
  }

  Future<void> initialize() async {
    // Don't request permissions automatically - let the calling view handle permission flow
    // await _requestPermissions();

    if (Platform.isMacOS) {
      // Initialize native Bluetooth service for macOS
      print(
        '🔵 BluetoothService: macOS detected, initializing native Bluetooth service',
      );
      await NativeBluetoothService.initialize();

      // Listen to native Bluetooth state changes
      NativeBluetoothService.bluetoothStateStream.listen((stateData) {
        final isEnabled = stateData['isEnabled'] as bool? ?? false;
        final state = stateData['state'] as String? ?? 'unknown';

        print(
          '🔵 BluetoothService: Native Bluetooth state changed - enabled: $isEnabled, state: $state',
        );

        if (isEnabled) {
          _clearError();
        } else {
          _setError('Bluetooth is turned off');
        }
      });

      // Check initial Bluetooth state
      final isEnabled = await NativeBluetoothService.isBluetoothEnabled();
      if (isEnabled) {
        _clearError();
      } else {
        _setError('Bluetooth is turned off');
      }

      return;
    }

    // Listen to adapter state changes for other platforms
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

  /// Call this method after permissions are granted to ensure proper initialization
  Future<void> initializeAfterPermissions() async {
    await _requestPermissions();
  }

  /// Set user's registered devices for validation during auto-connection
  void setUserDevices(List<dynamic> devices) {
    _userDevices = devices;
    print(
      '🔵 BluetoothService: Set ${_userDevices.length} user devices for validation',
    );
  }

  /// Set callback for when unknown devices are found
  void setOnUnknownDevicesFoundCallback(
    Function(List<Map<String, dynamic>>) callback,
  ) {
    _onUnknownDevicesFound = callback;
  }

  /// Set callback for when no devices are found
  void setOnNoDevicesFoundCallback(VoidCallback callback) {
    _onNoDevicesFound = callback;
  }

  /// Set callback for when device gets disconnected
  void setOnDeviceDisconnectedCallback(Function(String deviceName) callback) {
    _onDeviceDisconnected = callback;
  }

  /// Set callback for WiFi list received
  void setOnWifiListReceivedCallback(Function(List<String>) callback) {
    _onWifiListReceived = callback;
  }

  /// Set callback for WiFi connection status
  void setOnWifiConnectedCallback(Function(bool) callback) {
    _onWifiConnected = callback;
  }

  /// Set callback for download progress
  void setOnDownloadProgressCallback(Function(int) callback) {
    _onDownloadProgress = callback;
  }

  /// Set callback for download completion
  void setOnDownloadCompleteCallback(Function(bool) callback) {
    _onDownloadComplete = callback;
  }

  /// Set callback for WiFi errors
  void setOnWifiErrorCallback(Function(String) callback) {
    _onWifiError = callback;
  }

  /// Set callback for WiFi enable response
  void setOnWifiEnableResponseCallback(Function(String)? callback) {
    _onWifiEnableResponse = callback;
  }

  /// Set callback for WiFi connection response (#ESP,47,01! and #ESP,47,06!)
  void setOnWifiConnectionResponseCallback(Function(String) callback) {
    _onWifiConnectionResponse = callback;
  }

  /// Set callback for WiFi status response (#WIFI_CONNECTED! and #WIFI_DIS_CONNECTED!)
  void setOnWifiStatusResponseCallback(Function(String) callback) {
    _onWifiStatusResponse = callback;
  }

  /// Set callback for download status response (all download status codes)
  void setOnDownloadStatusResponseCallback(Function(String) callback) {
    _onDownloadStatusResponse = callback;
  }

  /// Set callback for download progress updates (#ESP,50,XX,00!)
  void setOnDownloadProgressUpdateCallback(Function(int) callback) {
    _onDownloadProgressUpdate = callback;
  }

  /// Set callback for download progress updates with filename (#ESP,50,XX,01,01,filename.cur,single!)
  void setOnDownloadProgressWithFilenameCallback(
    Function(String, int) callback,
  ) {
    _onDownloadProgressWithFilename = callback;
  }

  Future<void> startScanning() async {
    if (_connectionState == BluetoothConnectionState.scanning ||
        _connectionState == BluetoothConnectionState.connecting ||
        _connectionState == BluetoothConnectionState.connected)
      return;

    try {
      if (Platform.isMacOS) {
        // Check Bluetooth state using native service
        final isEnabled = await NativeBluetoothService.isBluetoothEnabled();
        if (!isEnabled) {
          _setError('Bluetooth is turned off');
          return;
        }
        print(
          '🔵 BluetoothService: macOS Bluetooth is enabled, proceeding with scan',
        );
        _clearError();
      } else {
        // Check if Bluetooth is on for other platforms
        if (await ble.FlutterBluePlus.adapterState.first !=
            ble.BluetoothAdapterState.on) {
          _setError('Bluetooth is turned off');
          return;
        }
      }

      _connectionState = BluetoothConnectionState.scanning;
      _statusMessage = 'Scanning for devices...';
      _scannedDevices.clear();
      _deviceRssiMap.clear(); // Clear RSSI map for new scan
      _scanCountdown = 10; // Initialize countdown to 10 seconds
      print('Initialized countdown: $_scanCountdown');
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
        // Only stop scanning if we're not already connected or connecting
        if (_connectionState != BluetoothConnectionState.connected &&
            _connectionState != BluetoothConnectionState.connecting) {
          _stopScanning(connectedDevice);
        }
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
        // Store RSSI for this device
        _deviceRssiMap[device.remoteId.toString()] = result.rssi;

        // Check if device already exists
        final existingIndex = _scannedDevices.indexWhere(
          (d) => d.remoteId == device.remoteId,
        );

        if (existingIndex >= 0) {
          // Update existing device
          _scannedDevices[existingIndex] = device;
        } else {
          // Add new device
          _scannedDevices.add(device);
        }

        // Check if this device matches any user devices immediately
        if (_userDevices.isNotEmpty) {
          final matchingDevices = _findMatchingUserDevices([device]);
          if (matchingDevices.isNotEmpty) {
            print(
              '🔗 Found matching user device during scan: ${device.platformName}',
            );
            // Stop scanning immediately and connect to the device

            // Auto-connect to the first matching device
            final deviceToConnect = matchingDevices.first;
            _stopScanning(deviceToConnect);
            print(
              '🔗 Auto-connecting to registered device: ${deviceToConnect.platformName}',
            );

            _connectionState = BluetoothConnectionState.connecting;
            _statusMessage = 'Connecting to ${deviceToConnect.platformName}...';
            _clearError();
            notifyListeners();

            // Connect to the device
            _connectToDevice(deviceToConnect);

            // Log auto-connection
            _loggingService.sendLogs(
              event: 'BLE Device Connect',
              status: 'success',
              notes:
                  'auto-connected to registered device: ${deviceToConnect.platformName}',
            );
            return; // Exit early since we found and are connecting to a matching device
          }
        }

        notifyListeners();
      }
    }
  }

  void _stopScanning(ble.BluetoothDevice? deviceFound) {
    // Double-check connection state before stopping scanning
    if (_connectionState == BluetoothConnectionState.connected ||
        _connectionState == BluetoothConnectionState.connecting) {
      print(
        '🛑 Skipping _stopScanning - device is already connected or connecting',
      );
      return;
    }

    _scanSubscription?.cancel();
    ble.FlutterBluePlus.stopScan();
    _scanTimer?.cancel();
    _countdownTimer?.cancel();
    _scanCountdown = 0;

    // Don't show "no devices found" if we're already connected or connecting
    if (_scannedDevices.isEmpty &&
        _connectionState != BluetoothConnectionState.connected &&
        _connectionState != BluetoothConnectionState.connecting) {
      _connectionState = BluetoothConnectionState.disconnected;
      _statusMessage = 'No Evolv28 devices found';
      _setError('No Evolv28 devices found nearby');

      // Call the callback to show no device found bottom sheet
      if (_onNoDevicesFound != null) {
        _onNoDevicesFound!();
      }

      // Log when no devices are found
      _loggingService.sendLogs(
        event: 'BLE Device Connect',
        status: 'failed',
        notes: 'unable to find device',
      );
    } else if (_scannedDevices.isNotEmpty) {
      print('✅ Found ${_scannedDevices.length} Evolv28 devices');

      // Find devices that match user's registered devices
      final matchingDevices = _findMatchingUserDevices(_scannedDevices);

      if (matchingDevices.isNotEmpty) {
        // Auto-connect to the first matching device
        final deviceToConnect = matchingDevices.first;
        print(
          '🔗 Auto-connecting to registered device: ${deviceToConnect.platformName}',
        );

        _connectionState = BluetoothConnectionState.connecting;
        _statusMessage = 'Connecting to ${deviceToConnect.platformName}...';
        _clearError();
        notifyListeners();

        if (deviceFound != null &&
            deviceFound.platformName == deviceToConnect.platformName) {
        } else {
          _connectToDevice(deviceToConnect);
        }
        // Connect to the device

        // Log auto-connection
        _loggingService.sendLogs(
          event: 'BLE Device Connect',
          status: 'success',
          notes:
              'auto-connected to registered device: ${deviceToConnect.platformName}',
        );
      } else {
        // No matching devices found - show unknown devices
        final unknownDevices = <Map<String, dynamic>>[];

        for (final device in _scannedDevices) {
          final rssi = getDeviceRssi(device);
          final signalStrength = _calculateSignalStrength(rssi);

          unknownDevices.add({
            'device': device,
            'name': device.platformName,
            'id': device.remoteId.toString(),
            'rssi': rssi,
            'signalStrength': signalStrength,
          });
        }

        print('🔍 Found ${unknownDevices.length} unknown devices');

        // Call the callback to show unknown device bottom sheet
        if (_onUnknownDevicesFound != null) {
          _onUnknownDevicesFound!(unknownDevices);
        }

        _connectionState = BluetoothConnectionState.disconnected;
        _statusMessage = '${_scannedDevices.length} unknown device(s) found';
        _clearError();

        // Log unknown device discovery
        _loggingService.sendLogs(
          event: 'BLE Device Connect',
          status: 'success',
          notes: '${_scannedDevices.length} unknown devices found',
        );
      }
    }

    notifyListeners();
  }

  // Find devices that match user's registered devices
  List<ble.BluetoothDevice> _findMatchingUserDevices(
    List<ble.BluetoothDevice> scannedDevices,
  ) {
    final matchingDevices = <ble.BluetoothDevice>[];

    // If user has no devices registered, don't auto-connect to anything
    if (_userDevices.isEmpty) {
      print(
        '🔵 BluetoothService: User has no registered devices - skipping auto-connection',
      );
      return matchingDevices;
    }

    for (final scannedDevice in scannedDevices) {
      final deviceName = scannedDevice.platformName.toLowerCase();
      print('🔵 BluetoothService: Checking scanned device: $deviceName');

      // Extract last 6 alphanumeric characters from scanned device name
      final scannedDeviceSuffix = _extractLast6Alphanumeric(deviceName);
      print('🔵 BluetoothService: Scanned device suffix: $scannedDeviceSuffix');

      // Check if this scanned device matches any of user's registered devices
      for (final userDevice in _userDevices) {
        if (userDevice is Map<String, dynamic>) {
          // Check various possible device identifiers
          final deviceId = userDevice['id']?.toString().toLowerCase() ?? '';
          final deviceNameFromUser =
              userDevice['devicename']?.toString().toLowerCase() ?? '';
          final deviceMac = userDevice['mac']?.toString().toLowerCase() ?? '';
          final deviceSerial =
              userDevice['serial']?.toString().toLowerCase() ?? '';

          print(
            '🔵 BluetoothService: Checking user device: $deviceNameFromUser',
          );

          // Extract last 6 alphanumeric characters from user device name
          final userDeviceSuffix = _extractLast6Alphanumeric(
            deviceNameFromUser,
          );
          print('🔵 BluetoothService: User device suffix: $userDeviceSuffix');

          // Match by last 6 alphanumeric characters
          if (scannedDeviceSuffix.isNotEmpty &&
              userDeviceSuffix.isNotEmpty &&
              scannedDeviceSuffix == userDeviceSuffix) {
            matchingDevices.add(scannedDevice);
            print(
              '🔵 BluetoothService: Found matching authorized device by suffix match: ${scannedDevice.platformName} (suffix: $scannedDeviceSuffix)',
            );
            break; // Don't add the same device multiple times
          }

          // Fallback: Match by device name (most common case) - keep existing logic as backup
          if (deviceName.contains('evolv28') &&
              (deviceNameFromUser.contains('evolv28') ||
                  deviceId.contains('evolv28') ||
                  deviceMac.isNotEmpty ||
                  deviceSerial.isNotEmpty)) {
            matchingDevices.add(scannedDevice);
            print(
              '🔵 BluetoothService: Found matching authorized device by name match: ${scannedDevice.platformName}',
            );
            break; // Don't add the same device multiple times
          }
        } else if (userDevice is String) {
          // If user device is just a string, check if it contains evolv28
          final userDeviceString = userDevice.toLowerCase();
          final userDeviceSuffix = _extractLast6Alphanumeric(userDeviceString);

          if (scannedDeviceSuffix.isNotEmpty &&
              userDeviceSuffix.isNotEmpty &&
              scannedDeviceSuffix == userDeviceSuffix) {
            matchingDevices.add(scannedDevice);
            print(
              '🔵 BluetoothService: Found matching authorized device by string suffix match: ${scannedDevice.platformName} (suffix: $scannedDeviceSuffix)',
            );
            break;
          }

          // Fallback: original string matching logic
          if (userDeviceString.contains('evolv28') &&
              deviceName.contains('evolv28')) {
            matchingDevices.add(scannedDevice);
            print(
              '🔵 BluetoothService: Found matching authorized device by string name match: ${scannedDevice.platformName}',
            );
            break;
          }
        }
      }
    }

    return matchingDevices;
  }

  /// Extract last 6 alphanumeric characters from device name
  String _extractLast6Alphanumeric(String deviceName) {
    if (deviceName.isEmpty) return '';

    // Remove all non-alphanumeric characters and get last 6 characters
    final alphanumericOnly = deviceName.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');

    if (alphanumericOnly.length >= 6) {
      return alphanumericOnly
          .substring(alphanumericOnly.length - 6)
          .toLowerCase();
    } else {
      return alphanumericOnly.toLowerCase();
    }
  }

  Future<void> connectToDevice(ble.BluetoothDevice device) async {
    await _connectToDevice(device);
  }

  Future<void> _connectToDevice(ble.BluetoothDevice device) async {
    try {
      print('🔗 Connecting to device: ${device.platformName}');
      _connectionState = BluetoothConnectionState.connecting;
      _statusMessage = 'Connecting...';
      _clearError();
      notifyListeners();

      if (_connectedDevice != null && _connectedDevice!.isConnected) {
      } else {
        await device.connect(timeout: const Duration(seconds: 10));
      }
      _connectedDevice = device;
      _connectionState = BluetoothConnectionState.connected;
      _statusMessage = '${device.platformName} is connected';
      print('✅ Device connected: ${device.platformName}');
      print(
        '🔍 BluetoothService: Connection state changed to connected, isScanning: $isScanning',
      );

      // Immediately stop all scanning-related timers and subscriptions
      // to prevent "no devices found" message after connection
      _scanSubscription?.cancel();
      ble.FlutterBluePlus.stopScan();
      _scanTimer?.cancel();
      _countdownTimer?.cancel();
      _scanCountdown = 0;
      print('🛑 Stopped scanning immediately after device connection');

      // Start monitoring device disconnection
      _startDisconnectionMonitoring(device);

      // Log successful device connection
      _loggingService.sendLogs(
        event: 'BLE Device Connect',
        status: 'success',
        notes: 'success',
      );

      notifyListeners();

      // Start command sequence to get program list
      print('🚀 Starting command sequence to get program list...');
      await _startCommandSequence();
    } catch (e) {
      _setError('Connection failed: $e');
      _connectionState = BluetoothConnectionState.disconnected;
      _statusMessage = 'Connect';

      // Log failed device connection
      _loggingService.sendLogs(
        event: 'BLE Device Connect',
        status: 'failed',
        notes: 'not able to connect',
      );

      notifyListeners();
    }
  }

  /// Connect to device without starting command sequence (for unknown devices)
  Future<void> connectToDeviceWithoutCommandSequence(
    ble.BluetoothDevice device,
  ) async {
    try {
      print('🔗 Connecting to unknown device: ${device.platformName}');
      _connectionState = BluetoothConnectionState.connecting;
      _statusMessage = 'Connecting...';
      _clearError();
      notifyListeners();

      // Connect to device
      await device.connect(timeout: const Duration(seconds: 10));

      _connectedDevice = device;
      _connectionState = BluetoothConnectionState.connected;
      _statusMessage = '${device.platformName} is connected';
      print('✅ Unknown device connected: ${device.platformName}');
      print(
        '🔍 BluetoothService: Unknown device connection state changed to connected, isScanning: $isScanning',
      );

      // Immediately stop all scanning-related timers and subscriptions
      // to prevent "no devices found" message after connection
      _scanSubscription?.cancel();
      ble.FlutterBluePlus.stopScan();
      _scanTimer?.cancel();
      _countdownTimer?.cancel();
      _scanCountdown = 0;
      print('🛑 Stopped scanning immediately after unknown device connection');

      // Start monitoring device disconnection
      _startDisconnectionMonitoring(device);

      // Log successful device connection
      _loggingService.sendLogs(
        event: 'BLE Device Connect',
        status: 'success',
        notes: 'unknown device connected',
      );

      notifyListeners();

      // Start command sequence in background without showing popup
      print(
        '🔗 Unknown device connected - starting background command sequence',
      );
      _startCommandSequenceInBackground();
    } catch (e) {
      _setError('Connection failed: $e');
      _connectionState = BluetoothConnectionState.disconnected;
      _statusMessage = 'Connect';

      // Log failed device connection
      _loggingService.sendLogs(
        event: 'BLE Device Connect',
        status: 'failed',
        notes: 'not able to connect to unknown device',
      );

      notifyListeners();
    }
  }

  /// Public method to start command sequence to get programs from device
  Future<void> startCommandSequence() async {
    await _startCommandSequence();
  }

  /// Start monitoring device disconnection
  void _startDisconnectionMonitoring(ble.BluetoothDevice device) {
    print('🔍 Starting disconnection monitoring for: ${device.platformName}');

    // Cancel any existing connection state subscription
    _connectionStateSubscription?.cancel();

    // Listen to device connection state changes
    _connectionStateSubscription = device.connectionState.listen((state) {
      print(
        '🔍 Device ${device.platformName} connection state changed: $state',
      );

      if (state == ble.BluetoothConnectionState.disconnected) {
        print('❌ Device ${device.platformName} disconnected!');

        // Update internal state
        _connectedDevice = null;
        _connectionState = BluetoothConnectionState.disconnected;
        _statusMessage = 'Connect';
        _currentPlayingFile = null;
        _clearError();

        // Cancel subscriptions
        _notificationSubscription?.cancel();
        _connectionStateSubscription?.cancel();

        // Clear command state
        _fifthCommandResponses.clear();
        _isWaitingForFifthCommand = false;
        _playerStatusCompleter?.complete(null);
        _stopCommandCompleter?.complete(false);
        _responseCompleter?.complete('');

        // Notify listeners
        notifyListeners();

        // Call disconnection callback if set
        if (_onDeviceDisconnected != null) {
          _onDeviceDisconnected!(device.platformName);
        }

        // Log disconnection
        _loggingService.sendLogs(
          event: 'BLE Device Disconnect',
          status: 'success',
          notes: 'device disconnected: ${device.platformName}',
        );
      }
    });
  }

  /// Start command sequence in background without showing popup
  Future<void> _startCommandSequenceInBackground() async {
    if (_connectedDevice == null) return;

    try {
      print('📋 Starting background command sequence to fetch program list...');
      // Don't set _isExecutingCommands = true to avoid showing popup

      // Discover services
      final services = await _connectedDevice!.discoverServices();

      // Find Nordic UART service
      _uartService = services.firstWhere(
        (service) =>
            service.uuid.toString().toLowerCase() ==
            nordicUartServiceUUID.toLowerCase(),
        orElse: () => throw Exception('Nordic UART service not found'),
      );

      // Find write and notify characteristics
      _writeCharacteristic = _uartService!.characteristics.firstWhere(
        (char) =>
            char.uuid.toString().toLowerCase() ==
            nordicUartWriteCharacteristicUUID.toLowerCase(),
        orElse: () => throw Exception('Write characteristic not found'),
      );

      _notifyCharacteristic = _uartService!.characteristics.firstWhere(
        (char) =>
            char.uuid.toString().toLowerCase() ==
            nordicUartNotifyCharacteristicUUID.toLowerCase(),
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

      // Command sequence completed in background
      print('📋 Background command sequence completed');
    } catch (e) {
      print('📋 Background command sequence failed: $e');
      // Don't show error popup for background command sequence
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
        (service) =>
            service.uuid.toString().toLowerCase() ==
            nordicUartServiceUUID.toLowerCase(),
        orElse: () => throw Exception('Nordic UART service not found'),
      );

      // Find write and notify characteristics
      _writeCharacteristic = _uartService!.characteristics.firstWhere(
        (char) =>
            char.uuid.toString().toLowerCase() ==
            nordicUartWriteCharacteristicUUID.toLowerCase(),
        orElse: () => throw Exception('Write characteristic not found'),
      );

      _notifyCharacteristic = _uartService!.characteristics.firstWhere(
        (char) =>
            char.uuid.toString().toLowerCase() ==
            nordicUartNotifyCharacteristicUUID.toLowerCase(),
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
      final playerStatusResponse = await _sendCommandSequence();

      // Command sequence completed
      _isExecutingCommands = false;

      // Process player status from the last command response
      if (playerStatusResponse != null) {
        _processPlayerStatusFromResponse(playerStatusResponse);
      }

      notifyListeners();
    } catch (e) {
      _isExecutingCommands = false;
      notifyListeners();
      _setError('Command sequence failed: $e');
    }
  }

  Future<String?> _sendCommandSequence() async {
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

    String? lastCommandResponse;

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

      // Set up response completer before sending command
      final completer = Completer<String>();
      _responseCompleter = completer;

      // Send command
      await writeCommand(command);

      // Wait for response with timeout, pass command index for special handling
      final response = await _waitForResponse(
        timeout: const Duration(seconds: 20),
        commandIndex: i,
        preSetupCompleter: completer,
      );

      print('Response ${i + 1}: $response');

      // Store the last command response (5#SPL!) for player status
      if (i == commands.length - 1) {
        lastCommandResponse = response;
        print(
          '🎵 BluetoothService: Stored last command response for player status: $response',
        );
      }

      // Log BLE command interaction
      if (i != 4) {
        _loggingService.sendBleCommandLog(
          command: command,
          response: response,
          reqTime: DateTime.now().millisecondsSinceEpoch,
        );
      }
      // Special handling for the 5th command (7#GFL,5!) to parse program list
      if (i == 4) {
        // Use the full accumulated response for program list parsing
        final fullResponse = _fifthCommandResponses.join('\n');
        _parseProgramListResponse(fullResponse);
        _loggingService.sendBleCommandLog(
          command: command,
          response: fullResponse,
          reqTime: DateTime.now().millisecondsSinceEpoch,
        );
      }

      // Small delay between commands
      await Future.delayed(const Duration(milliseconds: 500));
    }

    print('=== COMMAND SEQUENCE COMPLETED ===');
    return lastCommandResponse;
  }

  /// Process player status from the last command response (5#SPL!)
  void _processPlayerStatusFromResponse(String response) {
    print(
      '🎵 BluetoothService: Processing player status from command sequence response: $response',
    );

    if (response.contains('#SPL,')) {
      // Check if response contains STOP status
      if (response.contains('STOP')) {
        print(
          '🎵 BluetoothService: No program currently playing (from command sequence)',
        );
        _currentPlayingFile = null;
      } else {
        // Extract filename that contains .bcu or .cur from the entire response string
        final RegExp fileRegex = RegExp(r'([A-Za-z0-9_]+\.(?:bcu|cur))');
        final Match? match = fileRegex.firstMatch(response);

        if (match != null) {
          final filename = match.group(1);
          if (filename != null && filename.isNotEmpty) {
            print(
              '🎵 BluetoothService: Program is playing: $filename (from command sequence)',
            );
            _currentPlayingFile = filename;
          } else {
            print(
              '🎵 BluetoothService: Playing status but no .bcu/.cur filename found (from command sequence)',
            );
            _currentPlayingFile = null;
          }
        } else {
          print(
            '🎵 BluetoothService: Playing status but no .bcu/.cur filename found in response (from command sequence)',
          );
          _currentPlayingFile = null;
        }
      }
    } else {
      print(
        '🎵 BluetoothService: Response does not contain player status (from command sequence)',
      );
      _currentPlayingFile = null;
    }
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
      // _setError('Write characteristic error: $e');
      return;
    }
  }

  Future<String> _waitForResponse({
    required Duration timeout,
    int? commandIndex,
    Completer<String>? preSetupCompleter,
  }) async {
    final completer = preSetupCompleter ?? Completer<String>();
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
      while (!completer.isCompleted) {
        // Check if we have received the completion signal
        if (_fifthCommandResponses.isNotEmpty &&
            _fifthCommandResponses.any(
              (response) => response.contains('#Completed!'),
            )) {
          // Wait a bit more to ensure all responses are collected
          await Future.delayed(const Duration(milliseconds: 20));
          final fullResponse = _fifthCommandResponses.join('\n');
          print(
            '5th command - Final response with ${_fifthCommandResponses.length} parts',
          );
          completer.complete(fullResponse);
          break;
        }

        // Wait a bit before checking again
        await Future.delayed(const Duration(milliseconds: 1));
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
      // If completer wasn't pre-setup, set it up now
      if (preSetupCompleter == null) {
        _responseCompleter = completer;
      }

      // Set timeout
      timeoutTimer = Timer(timeout, () {
        if (!completer.isCompleted) {
          completer.complete(lastResponse ?? 'Timeout - No response received');
        }
      });

      // Wait for the response to be completed by the main notification handler
      final response = await completer.future;
      timeoutTimer.cancel();
      _responseCompleter = null; // Clear the completer
      print(
        '🎵 BluetoothService: Response for command $commandIndex: $response',
      );
      return response;
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

    // Debug: Log all responses for WiFi debugging
    if (stringValue.contains("#ESP,") ||
        stringValue.contains("WIFI") ||
        stringValue.contains("wifi")) {
      print('📶 Potential WiFi response: $stringValue');
    }

    // Store the latest notification response for play command waiting
    _lastNotificationResponse = stringValue;

    // Check if we're waiting for a general response first
    if (_responseCompleter != null && !_responseCompleter!.isCompleted) {
      // Only complete with non-empty responses
      if (stringValue.isNotEmpty) {
        _responseCompleter!.complete(stringValue);
        _responseCompleter = null;
        return;
      }
    }

    // Check if this is a player status response
    if (_playerStatusCompleter != null &&
        !_playerStatusCompleter!.isCompleted &&
        stringValue.contains('#SPL,')) {
      print(
        '🎵 BluetoothService: Player status response received: $stringValue',
      );
      _playerStatusCompleter!.complete(stringValue);
      _playerStatusCompleter = null;
      return;
    }

    // Check if this is a stop command response
    if (_stopCommandCompleter != null &&
        !_stopCommandCompleter!.isCompleted &&
        stringValue.contains('#ACK!')) {
      print(
        '🎵 BluetoothService: Stop command response received: $stringValue',
      );
      _stopCommandCompleter!.complete(true);
      _stopCommandCompleter = null;
      return;
    }

    // If we're waiting for the 5th command, accumulate the response
    if (_isWaitingForFifthCommand) {
      _fifthCommandResponses.add(stringValue);
      print(
        '5th command - Accumulated response: "$stringValue" (Total: ${_fifthCommandResponses.length})',
      );
    }

    // Handle WiFi scan results
    if (stringValue.contains("#ESP,49,") &&
        !stringValue.contains("#ESP,49,01!")) {
      // WiFi scan results
      String ssid = stringValue.split(',')[2].replaceAll('!', '').trim();
      // Filter out invalid SSIDs (like command codes) and avoid duplicates
      if (ssid.isNotEmpty &&
          !ssid.startsWith('0') &&
          ssid.length > 2 &&
          !_wifiList.contains(ssid)) {
        _wifiList.add(ssid);
        print('📶 WiFi scan result: $ssid');
      }
    } else if (stringValue.contains("#ESP,49,01!")) {
      // WiFi scan complete - only process once
      if (!_wifiScanCompleted) {
        _wifiScanCompleted = true;
        print('📶 WiFi scan complete, found ${_wifiList.length} networks');
        // Create a copy of the list before clearing
        List<String> finalList = List<String>.from(_wifiList);
        _onWifiListReceived?.call(finalList);
        _wifiList.clear();
        _logCommandWithResponse(stringValue);
      }
    } else if (stringValue.contains("#ACK!")) {
      // WiFi enable success response
      print('📶 WiFi enable success: $stringValue');
      _onWifiEnableResponse?.call('SUCCESS');
      _logCommandWithResponse(stringValue);
    } else if (stringValue.contains("#NACK!")) {
      // WiFi enable failure response
      print('📶 WiFi enable failure: $stringValue');
      _onWifiEnableResponse?.call('FAILURE');
      _logCommandWithResponse(stringValue);
    } else if (stringValue.contains(WIFI_CONNECTED)) {
      // WiFi status: connected
      print('📶 WiFi status: Connected');
      _onWifiStatusResponse?.call('CONNECTED');
      _logCommandWithResponse(stringValue);
    } else if (stringValue.contains(WIFI_DISCONNECTED)) {
      // WiFi status: disconnected
      print('📶 WiFi status: Disconnected');
      _onWifiStatusResponse?.call('DISCONNECTED');
      _logCommandWithResponse(stringValue);
    } else if (stringValue.contains(WIFI_CREDENTIALS_MATCH)) {
      // WiFi connection: credentials match
      print('📶 WiFi connection: Credentials match');
      _onWifiConnectionResponse?.call('SUCCESS');
      _logCommandWithResponse(stringValue);
    } else if (stringValue.contains(WIFI_CREDENTIALS_MISMATCH)) {
      // WiFi connection: credentials mismatch
      print('📶 WiFi connection: Credentials mismatch');
      _onWifiConnectionResponse?.call('FAILURE');
      _logCommandWithResponse(stringValue);
    } else if (stringValue.contains(DOWNLOAD_LINK_RECEIVED)) {
      print('📥 Download: Link received - Command received');
      _onDownloadStatusResponse?.call('LINK_RECEIVED');
      _logCommandWithResponse(stringValue);
    } else if (stringValue.contains(DOWNLOAD_SUCCESS)) {
      print('📥 Download: Successfully downloaded');
      _onDownloadStatusResponse?.call('SUCCESS');
      _onDownloadComplete?.call(true);
      _logCommandWithResponse(stringValue);
    } else if (stringValue.contains(DOWNLOAD_INTERNET_ERROR)) {
      print('📥 Download: Internet not available');
      _onDownloadStatusResponse?.call('INTERNET_ERROR');
      _logCommandWithResponse(stringValue);
    } else if (stringValue.contains(DOWNLOAD_SD_CARD_ERROR)) {
      print('📥 Download: SD card error');
      _onDownloadStatusResponse?.call('SD_CARD_ERROR');
      _logCommandWithResponse(stringValue);
    } else if (stringValue.contains(DOWNLOAD_WRONG_LINK)) {
      print('📥 Download: Wrong link - Download fail');
      _onDownloadStatusResponse?.call('WRONG_LINK');
      _logCommandWithResponse(stringValue);
    } else if (stringValue.contains(DOWNLOAD_WIFI_CONNECT_ERROR)) {
      print('📥 Download: WiFi connect error');
      _onDownloadStatusResponse?.call('WIFI_CONNECT_ERROR');
      _logCommandWithResponse(stringValue);
    } else if (stringValue.contains(DOWNLOAD_SOCKET_CLOSED)) {
      print('📥 Download: Socket closed during download');
      _onDownloadStatusResponse?.call('SOCKET_CLOSED');
      _logCommandWithResponse(stringValue);
    } else if (stringValue.contains(DOWNLOAD_UNSTABLE_NETWORK)) {
      print('📥 Download: Unstable network cause download failure');
      _onDownloadStatusResponse?.call('UNSTABLE_NETWORK');
      _logCommandWithResponse(stringValue);
    } else if (stringValue.contains(DOWNLOAD_FORBIDDEN_ERROR)) {
      print('📥 Download: File forbidden error (403)');
      _onDownloadStatusResponse?.call('FORBIDDEN_ERROR');
      _logCommandWithResponse(stringValue);
    } else if (stringValue.contains(DOWNLOAD_FILE_LINK_ERROR)) {
      print('📥 Download: File link error (404)');
      _onDownloadStatusResponse?.call('FILE_LINK_ERROR');
      _logCommandWithResponse(stringValue);
    } else if (stringValue.contains(DOWNLOAD_FILE_LENGTH_ERROR)) {
      print('📥 Download: File length error');
      _onDownloadStatusResponse?.call('FILE_LENGTH_ERROR');
      _logCommandWithResponse(stringValue);
    } else if (stringValue.contains(DOWNLOAD_PROGRESS)) {
      // Handle download progress: #ESP,50,XX,01,01,filename.cur,single!
      try {
        List<String> parts = stringValue.split(',');
        if (parts.length >= 6) {
          String percentage = parts[2];
          String filename = parts[5].replaceAll('!', ''); // Remove trailing !
          int progress = int.tryParse(percentage) ?? 0;

          print('📥 Download progress: $progress% - File: $filename');
          _onDownloadProgress?.call(progress);
          _onDownloadProgressUpdate?.call(progress);
          _onDownloadProgressWithFilename?.call(filename, progress);
        } else {
          // Fallback for old format: #ESP,50,XX,00!
          String percentage = parts[2];
          int progress = int.tryParse(percentage) ?? 0;
          print('📥 Download progress: $progress%');
          _onDownloadProgress?.call(progress);
          _onDownloadProgressUpdate?.call(progress);
        }
      } catch (e) {
        print('📥 Download: Error parsing progress: $e');
      }
      _logCommandWithResponse(stringValue);
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
              responseFileName.toLowerCase().contains(
                _selectedBcuFile!.toLowerCase(),
              )) {
            _isPlaySuccessful = true;
            _isSendingPlayCommands = false; // Stop showing loader
            print(
              '✅ Play successful! File $_selectedBcuFile found in response: $stringValue',
            );
            print('✅ Extracted filename from response: $responseFileName');
            print(
              '✅ Setting _isPlaySuccessful = true, _isSendingPlayCommands = false',
            );
            print('🎵 Program switched successfully to: $_selectedBcuFile');
            notifyListeners();
          } else {
            print(
              '❌ Filename mismatch: expected $_selectedBcuFile, got $responseFileName',
            );
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

      // Parse the response to extract .bcu and .cur files
      final lines = response.split('\n');
      final programFiles = <String>[];

      for (final line in lines) {
        final trimmedLine = line.trim();
        if (trimmedLine.toLowerCase().contains('.bcu') ||
            trimmedLine.toLowerCase().contains('.cur')) {
          // Use regex to find all .bcu and .cur filenames
          final filePattern = RegExp(
            r'([a-zA-Z0-9_\-\.]+\.(?:bcu|cur))',
            caseSensitive: false,
          );
          final matches = filePattern.allMatches(trimmedLine);

          for (final match in matches) {
            String filename = match.group(1) ?? '';
            if (filename.isNotEmpty && filename.length > 4) {
              // Clean up any trailing punctuation
              filename = filename.replaceAll(RegExp(r'[,;:\s]+$'), '');
              if (filename.toLowerCase().endsWith('.bcu') ||
                  filename.toLowerCase().endsWith('.cur')) {
                programFiles.add(filename);
              }
            }
          }
        }
      }

      // Remove duplicates and sort
      programFiles.toSet().toList()..sort();

      print(
        'Found ${programFiles.length} program files (.bcu/.cur): $programFiles',
      );

      // Convert .bcu files to wellness programs format
      _availablePrograms = _convertBcuFilesToWellnessPrograms(programFiles);

      print(
        'Converted to ${_availablePrograms.length} wellness programs: $_availablePrograms',
      );
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

    return text
        .split(' ')
        .map((word) {
          if (word.isEmpty) return word;
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');
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

  // Public methods for error handling
  void setErrorMessage(String error) {
    _setError(error);
  }

  void clearErrorMessage() {
    _clearError();
    notifyListeners();
  }

  void setStatusMessage(String message) {
    _statusMessage = message;
    notifyListeners();
  }

  Future<void> disconnect() async {
    try {
      if (_connectedDevice != null && _connectedDevice!.isConnected) {
        await _connectedDevice!.disconnect();
      }

      // Cancel subscriptions
      _notificationSubscription?.cancel();
      _connectionStateSubscription?.cancel();

      _connectedDevice = null;
      _connectionState = BluetoothConnectionState.disconnected;
      _statusMessage = 'Connect';
      _scannedDevices.clear();
      _availablePrograms.clear();
      _currentPlayingFile = null;
      _clearError();
      notifyListeners();
    } catch (e) {
      _setError('Disconnect error: $e');
    }
  }

  // Play command methods
  Future<void> playProgram(String bcuFileName) async {
    print('🎵 BluetoothService: playProgram called with: $bcuFileName');
    print('🎵 BluetoothService: _connectedDevice: $_connectedDevice');
    print('🎵 BluetoothService: _connectionState: $_connectionState');

    if (_connectedDevice == null ||
        _connectionState != BluetoothConnectionState.connected) {
      print('🎵 BluetoothService: Device not connected, cannot play program');
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
      print(
        'DEBUG: Starting play commands - _isPlaySuccessful: $_isPlaySuccessful, _isSendingPlayCommands: $_isSendingPlayCommands',
      );
      notifyListeners();

      // Generate current timestamp for #ST command
      final now = DateTime.now();
      final timestamp =
          '${now.year.toString().padLeft(4, '0')}'
          '${now.month.toString().padLeft(2, '0')}'
          '${now.day.toString().padLeft(2, '0')}'
          '${now.hour.toString().padLeft(2, '0')}'
          '${now.minute.toString().padLeft(2, '0')}'
          '${now.second.toString().padLeft(2, '0')}';

      // Generate timestamp for 24#PL command (1 second later)
      final plTime = now.add(const Duration(seconds: 1));
      final plTimestamp =
          '${plTime.year.toString().padLeft(4, '0')}'
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
        print(
          'Sending play command ${i + 1}/${dynamicPlayCommands.length}: $command',
        );

        // Send command
        await writeCommand(command);

        // Wait for response
        final response = await _waitForPlayCommandResponse(
          timeout: const Duration(seconds: 10),
        );

        // Add command response
        _playCommandResponses.add('$command -> $response');
        print('Play command response: $command -> $response');

        // Log BLE command interaction
        _loggingService.sendBleCommandLog(
          command: command,
          response: response,
          reqTime: DateTime.now().millisecondsSinceEpoch,
        );

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
      print(
        'DEBUG: Final state - _isPlaySuccessful: $_isPlaySuccessful, _isSendingPlayCommands: $_isSendingPlayCommands',
      );
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

    // Wait for actual response from the device
    // The _handleNotification method will handle the response
    while (!completer.isCompleted) {
      await Future.delayed(const Duration(milliseconds: 100));

      // Check if we have received any response in the notification handler
      // For play commands, we expect responses like #ACK! for most commands
      // and #SPL,filename for the final 5#SPL! command
      if (_lastNotificationResponse != null &&
          _lastNotificationResponse!.isNotEmpty) {
        final response = _lastNotificationResponse!;
        _lastNotificationResponse = null; // Clear after using
        timeoutTimer.cancel();
        completer.complete(response);
        break;
      }
    }

    return await completer.future;
  }

  // Set the selected BCU file (used when checking player status)
  void setSelectedBcuFile(String bcuFileName) {
    _selectedBcuFile = bcuFileName;
    print('🎵 BluetoothService: Selected BCU file set to: $bcuFileName');
  }

  // Set the play success state (used when stopping programs)
  void setPlaySuccessState(bool success) {
    _isPlaySuccessful = success;
    print('🎵 BluetoothService: Play success state set to: $success');
  }

  // Stop the currently playing program
  Future<bool> stopProgram() async {
    print('🎵 BluetoothService: stopProgram called');

    if (_connectedDevice == null ||
        _connectionState != BluetoothConnectionState.connected) {
      print('🎵 BluetoothService: Device not connected, cannot stop program');
      return false;
    }

    if (_writeCharacteristic == null || _notifyCharacteristic == null) {
      print('🎵 BluetoothService: UART characteristics not available');
      return false;
    }

    try {
      print('🎵 BluetoothService: Sending #STP! to stop program...');

      // Create a completer to wait for the response
      final completer = Completer<bool>();
      Timer? timeoutTimer;

      // Set timeout
      timeoutTimer = Timer(Duration(seconds: 5), () {
        if (!completer.isCompleted) {
          print('🎵 BluetoothService: Stop command timeout');
          completer.complete(false);
        }
      });

      // Store the completer so _handleNotification can complete it
      _stopCommandCompleter = completer;

      // Send the #STP! command
      await writeCommand('#STP!');

      // Wait for response
      final success = await completer.future;
      print('🎵 BluetoothService: Stop command result: $success');

      // Log BLE command interaction
      _loggingService.sendBleCommandLog(
        command: '#STP!',
        response: success ? '#ACK!' : 'timeout',
        reqTime: DateTime.now().millisecondsSinceEpoch,
      );

      return success;
    } catch (e) {
      print('🎵 BluetoothService: Error stopping program: $e');
      return false;
    }
  }

  // Check if a program is currently playing by sending 5#SPL! command
  Future<String?> checkPlayerCommand() async {
    print('🎵 BluetoothService: checkPlayerCommand called');

    if (_connectedDevice == null ||
        _connectionState != BluetoothConnectionState.connected) {
      print(
        '🎵 BluetoothService: Device not connected, cannot check player status',
      );
      return null;
    }

    if (_writeCharacteristic == null || _notifyCharacteristic == null) {
      print('🎵 BluetoothService: UART characteristics not available');
      return null;
    }

    try {
      print('🎵 BluetoothService: Sending 5#SPL! to check player status...');

      // Create a completer to wait for the response
      final completer = Completer<String?>();
      Timer? timeoutTimer;

      // Set timeout
      timeoutTimer = Timer(Duration(seconds: 5), () {
        if (!completer.isCompleted) {
          print('🎵 BluetoothService: Player status check timeout');
          completer.complete(null);
        }
      });

      // Store the completer so _handleNotification can complete it
      _playerStatusCompleter = completer;

      // Send the 5#SPL! command
      await writeCommand('5#SPL!');

      // Wait for response
      final response = await completer.future;
      print('🎵 BluetoothService: Player check response: $response');

      // Log BLE command interaction
      _loggingService.sendBleCommandLog(
        command: '5#SPL!',
        response: response ?? 'timeout',
        reqTime: DateTime.now().millisecondsSinceEpoch,
      );

      if (response != null && response.contains('#SPL,')) {
        // Parse the response to extract the filename
        final parts = response.split(',');
        if (parts.length > 7) {
          final filename = parts[7];
          print('🎵 BluetoothService: Currently playing file: $filename');
          return filename;
        }
      }

      print('🎵 BluetoothService: No program currently playing');
      return null;
    } catch (e) {
      print('🎵 BluetoothService: Error checking player status: $e');
      return null;
    }
  }

  // Helper method to log command and wait for response
  void _logCommandAndWaitForResponse(String command) {
    _pendingCommandForLogging = command;
    _pendingCommandTimestamp = DateTime.now();
    print('📶 BluetoothService: Command logged for response: $command');
  }

  // Helper method to log command with actual response
  void _logCommandWithResponse(String response) {
    if (_pendingCommandForLogging != null && _pendingCommandTimestamp != null) {
      _loggingService.sendBleCommandLog(
        command: _pendingCommandForLogging!,
        response: response,
        reqTime: _pendingCommandTimestamp!.millisecondsSinceEpoch,
      );
      print(
        '📶 BluetoothService: Logged command with response: $_pendingCommandForLogging -> $response',
      );

      // Clear pending command
      _pendingCommandForLogging = null;
      _pendingCommandTimestamp = null;
    }
  }

  // WiFi Commands
  Future<void> disableWifi() async {
    await writeCommand(DISABLE_WIFI);
  }

  Future<void> enableWifi() async {
    print('📶 BluetoothService: Enabling WiFi with command: $ENABLE_WIFI');
    await writeCommand(ENABLE_WIFI);
    print('📶 BluetoothService: Enable WiFi command sent');

    // Log command and wait for response
    _logCommandAndWaitForResponse(ENABLE_WIFI);
  }

  Future<void> scanWifi() async {
    _wifiList.clear(); // Clear previous results
    _wifiScanCompleted = false; // Reset scan completion flag
    print('📶 BluetoothService: Starting WiFi scan with command: $WIFI_SCAN');
    await writeCommand(WIFI_SCAN);
    print('📶 BluetoothService: WiFi scan command sent');

    // Add a temporary debug to see if device responds at all
    print('📶 BluetoothService: Waiting for any device responses...');

    // Log command and wait for response
    _logCommandAndWaitForResponse(WIFI_SCAN);
  }

  Future<void> sendSSID(String ssid) async {
    String basicCommand = "Cmd:31$ssid!";
    int commandLength =
        basicCommand.length + 2 + basicCommand.length.toString().length;
    String command = "#0$commandLength$basicCommand";
    print('📶 BluetoothService: Sending SSID: $ssid with command: $command');
    await writeCommand(command);

    // Log command and wait for response
    _logCommandAndWaitForResponse(command);
  }

  Future<void> sendPassword(String password) async {
    String basicCommand = "Cmd:32$password!";
    int commandLength =
        basicCommand.length + 2 + basicCommand.length.toString().length;
    String finalCommand = "#0$commandLength$basicCommand";
    print('📶 BluetoothService: Sending password with command: $finalCommand');
    await writeCommand(finalCommand);

    // Log command and wait for response
    _logCommandAndWaitForResponse(finalCommand);
  }

  Future<void> connectWifi() async {
    print(
      '📶 BluetoothService: Connecting to WiFi with command: $WIFI_CONNECT',
    );
    await writeCommand(WIFI_CONNECT);
    // Log command and wait for response
    _logCommandAndWaitForResponse(WIFI_CONNECT);
  }

  Future<void> checkWifiStatus() async {
    print(
      '📶 BluetoothService: Checking WiFi status with command: $WIFI_STATUS',
    );
    await writeCommand(WIFI_STATUS);

    // Log command and wait for response
    _logCommandAndWaitForResponse(WIFI_STATUS);
  }

  /// Send download status command to get current download progress
  Future<void> checkDownloadStatus() async {
    print(
      '📶 BluetoothService: Checking download status with command: $DOWNLOAD_STATUS_COMMAND',
    );
    await writeCommand(DOWNLOAD_STATUS_COMMAND);

    // Log command and wait for response
    _logCommandAndWaitForResponse(DOWNLOAD_STATUS_COMMAND);
  }

  // Download Commands
  Future<void> downloadSingleFile(String url, String programSize) async {
    const String defaultValue = "Cmd:30";

    // Construct the basic command: #defaultValue,fileSize,url!
    String constructCmd = "#$defaultValue,$programSize,$url!";
    int constructCmdLength = constructCmd.length;
    int finalLength = constructCmdLength + constructCmdLength.toString().length;

    String finalCommand;

    if (finalLength.toString().length > 2) {
      int finalCommandLength =
          constructCmdLength + finalLength.toString().length;
      finalCommand = "#$finalCommandLength$defaultValue,$programSize,$url!";
    } else {
      if (finalLength >= 99) {
        finalCommand = "#${finalLength + 1}$defaultValue,$programSize,$url!";
      } else {
        finalCommand = "#0${finalLength + 1}$defaultValue,$programSize,$url!";
      }
    }

    print('📶 BluetoothService: Download command: $finalCommand');
    await writeCommand(finalCommand);

    // Log command and wait for response
    _logCommandAndWaitForResponse(finalCommand);
  }

  Future<void> downloadBulkFiles(String url, int fileSize) async {
    String basicCommand = "Cmd:35,$fileSize,$url!";
    int commandLength = basicCommand.length;
    int totalLength = commandLength + commandLength.toString().length;

    String finalCommand;
    if (totalLength.toString().length > 2) {
      int finalCommandLength = commandLength + totalLength.toString().length;
      finalCommand = "#$finalCommandLength:35,$fileSize,$url!";
    } else {
      finalCommand = totalLength >= 99
          ? "#${totalLength + 1}Cmd:35,$fileSize,$url!"
          : "#0${totalLength + 1}Cmd:35,$fileSize,$url!";
    }

    await writeCommand(finalCommand);
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    _scanTimer?.cancel();
    _countdownTimer?.cancel();
    _notificationSubscription?.cancel();

    // Clean up native Bluetooth service
    if (Platform.isMacOS) {
      NativeBluetoothService.dispose();
    }

    super.dispose();
  }
}
