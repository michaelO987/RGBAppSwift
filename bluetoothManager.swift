// Michael Oliva
// 7/9/26
// Bluetooth Manager

import Foundation
import CoreBluetooth
import Combine

// service: FFE0
// characteristic: FFE1
// ONLY SUPPORTS WRITE W/O RESPONSE

class BluetoothManager: NSObject, ObservableObject {
    @Published var isConnected = false
    @Published var recievedText = ""
    
    private var centralManager: CBCentralManager!
    private var peripheral: CBPeripheral?
    private var txCharacteristic: CBCharacteristic?
    
    // HM-10 UUIDs
    let serviceUUID = CBUUID(string: "FFE0")
    let characteristicUUID = CBUUID(string: "FFE1")
    
    override init() {
        super.init()
        print("BluetoothManager Initialized")
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    // command recieved has \n automatically appended
    func send(_ text: String) {
        print("send() called")
        guard
            let peripheral = peripheral,
            let characteristic = txCharacteristic
        else {
            print("No peripheral or characteristic!")
            return
        }
        
        let data = text.data(using: .utf8)!

        print("Sending '\(text)'")
        print("Characteristic: ", characteristic.uuid)
        print("Properties: ", characteristic.properties)

        if (characteristic.properties.contains(.write)) {
            peripheral.writeValue(data,
                                  for: characteristic,
                                  type: .withResponse)
        }
        else if (characteristic.properties.contains(.writeWithoutResponse)) {
            peripheral.writeValue(data,
                                  for: characteristic,
                                  type: .withoutResponse)
        }
        else {
            print("Characteristic is not writable!")
        }
        
    }
}

extension BluetoothManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            print("Bluetooth is ON")
            central.scanForPeripherals(withServices: nil, options: nil)
            
        case .poweredOff:
            print("Bluetooth is OFF")
        
        case .unauthorized:
            print("Bluetooth Unauthorized")
        
        case .unsupported:
            print("Bluetooth Unsupported")
        
        default:
            print("Bluetooth state: \(central.state.rawValue)")
        }
        
        if central.state == .poweredOn {
            print("Scanning...")
            central.scanForPeripherals(withServices: nil, options: nil)
        }
    }
    
    func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String : Any],
                        rssi RSSI: NSNumber) {
        let name = peripheral.name ?? ""
        print("Found: \(name)")
        if (name == "DSD TECH") {
            print("Connecting to \(name)...")
            self.peripheral = peripheral
            peripheral.delegate = self
            
            central.stopScan()
            central.connect(peripheral)
        }
        /*
        self.peripheral = peripheral
        central.stopScan()
        
        peripheral.delegate = self
        central.connect(peripheral)*/
    }
    
    func centralManager(_ central: CBCentralManager,
                        didConnect peripheral: CBPeripheral) {
        print("CONNECTED TO: \(peripheral.name ?? "Unknown")")
        isConnected = true
        peripheral.discoverServices([serviceUUID])
    }
    
    func centralManager(_ central: CBCentralManager,
                        didDisconnectPeripheral peripheral: CBPeripheral,
                        error: Error?) {
        isConnected = false
    }
}

extension BluetoothManager: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral,
                    didDiscoverServices error: Error?) {
        guard
            let services = peripheral.services
        else { return }
        
        for service in services {
            peripheral.discoverCharacteristics([characteristicUUID], for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral,
                    didDiscoverCharacteristicsFor service: CBService,
                    error: Error?) {
        guard
            let characteristics = service.characteristics
        else { return }
        
        for characteristic in characteristics {
            print(characteristic.uuid)
            print(characteristic.properties)

            if (characteristic.uuid == characteristicUUID) {
                print("FOUND FFE1")
                txCharacteristic = characteristic
                peripheral.setNotifyValue(true, for: characteristic)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral,
                    didUpdateValueFor characteristic: CBCharacteristic,
                    error: Error?) {
        guard
            let value = characteristic.value,
            let string = String(data: value, encoding: .utf8)
        else { return }
        
        DispatchQueue.main.async {
            self.recievedText += string
        }
    }

    func peripheral(_ peripheral: CBPeripheral,
                    didWriteValueFor characteristic: CBCharacteristic,
                    error: Error?) {
        if let error = error {
            print("Write failed: ", error)
        }
        else {
            print("Write Succeeded")
        }
    }
}
