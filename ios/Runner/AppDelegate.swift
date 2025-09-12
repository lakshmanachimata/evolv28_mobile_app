import Flutter
import UIKit
import CoreBluetooth

@main
@objc class AppDelegate: FlutterAppDelegate, CBCentralManagerDelegate {
  private var bluetoothChannel: FlutterMethodChannel?
  private var centralManager: CBCentralManager?
  private var bluetoothState: CBManagerState = .unknown
  
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    
    // Setup Bluetooth method channel
    if let controller = window?.rootViewController as? FlutterViewController {
      bluetoothChannel = FlutterMethodChannel(name: "bluetooth_manager", binaryMessenger: controller.binaryMessenger)
      bluetoothChannel?.setMethodCallHandler(handleBluetoothMethodCall)
    }
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  private func handleBluetoothMethodCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getBluetoothStatus":
      getBluetoothStatus(result: result)
    case "getBluetoothPermissionStatus":
      getBluetoothPermissionStatus(result: result)
    case "requestBluetoothPermission":
      requestBluetoothPermission(result: result)
    case "startScanning":
      startScanning(result: result)
    case "stopScanning":
      stopScanning(result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
  
  private func getBluetoothStatus(result: @escaping FlutterResult) {
    if centralManager == nil {
      centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    let status = getBluetoothStateString()
    result(status)
  }
  
  private func getBluetoothPermissionStatus(result: @escaping FlutterResult) {
    if centralManager == nil {
      centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    let permissionStatus = getPermissionStatusString()
    result(permissionStatus)
  }
  
  private func requestBluetoothPermission(result: @escaping FlutterResult) {
    if centralManager == nil {
      centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    // Try to start scanning to trigger permission request
    centralManager?.scanForPeripherals(withServices: nil, options: nil)
    
    result("permission_requested")
  }
  
  private func startScanning(result: @escaping FlutterResult) {
    if centralManager == nil {
      centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    if bluetoothState == .poweredOn {
      centralManager?.scanForPeripherals(withServices: nil, options: nil)
      result("scanning_started")
    } else {
      result("bluetooth_not_available")
    }
  }
  
  private func stopScanning(result: @escaping FlutterResult) {
    centralManager?.stopScan()
    result("scanning_stopped")
  }
  
  private func getBluetoothStateString() -> String {
    switch bluetoothState {
    case .unknown:
      return "unknown"
    case .resetting:
      return "resetting"
    case .unsupported:
      return "unsupported"
    case .unauthorized:
      return "unauthorized"
    case .poweredOff:
      return "powered_off"
    case .poweredOn:
      return "powered_on"
    @unknown default:
      return "unknown"
    }
  }
  
  private func getPermissionStatusString() -> String {
    switch bluetoothState {
    case .unknown:
      return "unknown"
    case .resetting:
      return "resetting"
    case .unsupported:
      return "unsupported"
    case .unauthorized:
      return "denied"
    case .poweredOff:
      return "granted_but_off"
    case .poweredOn:
      return "granted"
    @unknown default:
      return "unknown"
    }
  }
  
  // MARK: - CBCentralManagerDelegate
  func centralManagerDidUpdateState(_ central: CBCentralManager) {
    bluetoothState = central.state
    
    // Notify Flutter about state changes
    let stateString = getBluetoothStateString()
    let permissionString = getPermissionStatusString()
    
    bluetoothChannel?.invokeMethod("onBluetoothStateChanged", arguments: [
      "state": stateString,
      "permission": permissionString
    ])
  }
  
  func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
    // Filter only devices with "evolv28" in the name
    let deviceName = peripheral.name ?? ""
    if deviceName.lowercased().contains("evolv28") {
      // Notify Flutter about discovered evolv28 devices
      let deviceInfo: [String: Any] = [
        "id": peripheral.identifier.uuidString,
        "name": deviceName,
        "rssi": RSSI.intValue
      ]
      
      bluetoothChannel?.invokeMethod("onDeviceDiscovered", arguments: deviceInfo)
    }
  }
}
