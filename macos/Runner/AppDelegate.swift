import Cocoa
import FlutterMacOS
import CoreBluetooth

@objc class BluetoothManager: NSObject, ObservableObject {
    static let shared = BluetoothManager()
    
    @Published var isBluetoothEnabled: Bool = false
    @Published var bluetoothState: String = "unknown"
    
    private var centralManager: CBCentralManager?
    private var methodChannel: FlutterMethodChannel?
    
    override init() {
        super.init()
        setupBluetoothManager()
    }
    
    func setupMethodChannel(binaryMessenger: FlutterBinaryMessenger) {
        methodChannel = FlutterMethodChannel(name: "bluetooth_manager", binaryMessenger: binaryMessenger)
        
        methodChannel?.setMethodCallHandler { [weak self] (call, result) in
            switch call.method {
            case "getBluetoothState":
                self?.getBluetoothState(result: result)
            case "requestBluetoothPermission":
                self?.requestBluetoothPermission(result: result)
            case "isBluetoothEnabled":
                self?.isBluetoothEnabled(result: result)
            case "startScanning":
                self?.startScanning(result: result)
            case "stopScanning":
                self?.stopScanning(result: result)
            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }
    
    private func setupBluetoothManager() {
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    private func getBluetoothState(result: @escaping FlutterResult) {
        DispatchQueue.main.async {
            let state = self.getBluetoothStateString()
            result(state)
        }
    }
    
    private func requestBluetoothPermission(result: @escaping FlutterResult) {
        DispatchQueue.main.async {
            // On macOS, Bluetooth permissions are typically granted automatically
            // when the app requests to use Bluetooth services
            if self.centralManager?.state == .poweredOn {
                result(true)
            } else {
                result(false)
            }
        }
    }
    
    private func isBluetoothEnabled(result: @escaping FlutterResult) {
        DispatchQueue.main.async {
            result(self.isBluetoothEnabled)
        }
    }
    
    private func startScanning(result: @escaping FlutterResult) {
        DispatchQueue.main.async {
            if self.centralManager?.state == .poweredOn {
                print("🔵 BluetoothManager: Starting BLE scanning")
                result(true)
            } else {
                print("🔵 BluetoothManager: Cannot start scanning - Bluetooth not powered on")
                result(false)
            }
        }
    }
    
    private func stopScanning(result: @escaping FlutterResult) {
        DispatchQueue.main.async {
            print("🔵 BluetoothManager: Stopping BLE scanning")
            result(true)
        }
    }
    
    private func getBluetoothStateString() -> String {
        guard let centralManager = centralManager else {
            return "unknown"
        }
        
        switch centralManager.state {
        case .poweredOn:
            return "powered_on"
        case .poweredOff:
            return "powered_off"
        case .resetting:
            return "resetting"
        case .unauthorized:
            return "unauthorized"
        case .unsupported:
            return "unsupported"
        case .unknown:
            return "unknown"
        @unknown default:
            return "unknown"
        }
    }
    
    private func updateBluetoothState() {
        DispatchQueue.main.async {
            guard let centralManager = self.centralManager else { return }
            
            switch centralManager.state {
            case .poweredOn:
                self.isBluetoothEnabled = true
                self.bluetoothState = "powered_on"
                print("🔵 BluetoothManager: Bluetooth is ON")
            case .poweredOff:
                self.isBluetoothEnabled = false
                self.bluetoothState = "powered_off"
                print("🔵 BluetoothManager: Bluetooth is OFF")
            case .resetting:
                self.isBluetoothEnabled = false
                self.bluetoothState = "resetting"
                print("🔵 BluetoothManager: Bluetooth is RESETTING")
            case .unauthorized:
                self.isBluetoothEnabled = false
                self.bluetoothState = "unauthorized"
                print("🔵 BluetoothManager: Bluetooth is UNAUTHORIZED")
            case .unsupported:
                self.isBluetoothEnabled = false
                self.bluetoothState = "unsupported"
                print("🔵 BluetoothManager: Bluetooth is UNSUPPORTED")
            case .unknown:
                self.isBluetoothEnabled = false
                self.bluetoothState = "unknown"
                print("🔵 BluetoothManager: Bluetooth state is UNKNOWN")
            @unknown default:
                self.isBluetoothEnabled = false
                self.bluetoothState = "unknown"
                print("🔵 BluetoothManager: Bluetooth state is UNKNOWN (default)")
            }
            
            // Notify Flutter about state change
            self.methodChannel?.invokeMethod("onBluetoothStateChanged", arguments: [
                "isEnabled": self.isBluetoothEnabled,
                "state": self.bluetoothState
            ])
        }
    }
}

extension BluetoothManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print("🔵 BluetoothManager: Central manager state changed to: \(central.state.rawValue)")
        updateBluetoothState()
    }
}

@main
class AppDelegate: FlutterAppDelegate {
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }
  
  override func applicationDidFinishLaunching(_ notification: Notification) {
    super.applicationDidFinishLaunching(notification)
    
    // Setup Bluetooth manager
    guard let controller = self.mainFlutterWindow?.contentViewController as? FlutterViewController else {
      return
    }
    
    BluetoothManager.shared.setupMethodChannel(binaryMessenger: controller.engine.binaryMessenger)
  }
}
