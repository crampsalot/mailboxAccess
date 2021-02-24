//
//  MailboxManager.swift
//  MailboxAccess
//
//  Created by Isa Hashim on 2/23/21.
//

import CoreBluetooth

class MailboxManager: NSObject {
    private let MBOX_PERIPHERAL_NAME = "Fore"

    private let LOCK_SERVICE_UUID = CBUUID(string: "9B012401-BC30-CE9A-E111-0F67E491ABDE")
    private let LOCK_CHAR_UUID: CBUUID = CBUUID(string: "4ACBCD28-7425-868E-F447-915C8F00D0CB")

    static let sharedInstance = MailboxManager()

    var centralMgr: CBCentralManager?
    var mailboxPeripheral: CBPeripheral?
    var user: User?

    private override init() {
        super.init()
    }
    
    func connect(user: User) {
        self.user = user
        initBLE()
    }

    func lock() {
        guard let peripheral = mailboxPeripheral else {
            return
        }

        guard let lockChar = getLockCharacteristic() else {
            return
        }

        let one = UInt8(1)
        let data = Data([one])
        peripheral.writeValue(data, for: lockChar, type: .withResponse)
    }

    func unlock() {
        guard let peripheral = mailboxPeripheral else {
            return
        }

        guard let lockChar = getLockCharacteristic() else {
            return
        }

        let zero = UInt8(0)
        let data = Data([zero])
        peripheral.writeValue(data, for: lockChar, type: .withResponse)
    }

    func getLockService() -> CBService? {
        guard let peripheral = mailboxPeripheral else {
            return nil
        }

        guard let services = peripheral.services else {
            return nil
        }

        let firstMatch = services.first { $0.uuid == LOCK_SERVICE_UUID }

        return firstMatch
    }

    func getLockCharacteristic() -> CBCharacteristic? {
        guard let service = getLockService() else {
            return nil
        }

        guard let characteristics = service.characteristics else {
            return nil
        }

        let firstMatch = characteristics.first { $0.uuid == LOCK_CHAR_UUID }

        return firstMatch
    }
    
    private func initBLE() {
        let bleOptions = [CBCentralManagerOptionShowPowerAlertKey: NSNumber.init(booleanLiteral: true)]

        centralMgr = CBCentralManager.init(delegate: self, queue: nil, options: bleOptions)
    }
}

extension MailboxManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch (central.state) {
        case .poweredOn:
            print("central.state is .poweredOn")
            // start scanning for peripherals
            central.scanForPeripherals(withServices: nil, options: nil)
        case .poweredOff:
            print("central.state is .poweredOff")
        case .resetting:
            print("central.state is .resetting")
        case .unauthorized:
            print("central.state is .unauthorized")
        case .unknown:
            print("central.state is .unknown")
        case .unsupported:
            print("central.state is .unsupported")
        @unknown default:
            print("central.state Returned unknown state")
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        guard let name = peripheral.name else {
            return
        }

        if !name.contains(MBOX_PERIPHERAL_NAME) {
            return
        }
        
        // Check advertisementData for mailbox id found in user profile

        print("Found device: " + peripheral.description)

        mailboxPeripheral = peripheral
        peripheral.delegate = self

        centralMgr?.stopScan()
        centralMgr?.connect(peripheral, options: nil)
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Connected: " + peripheral.description)
        mailboxPeripheral?.discoverServices([LOCK_SERVICE_UUID])
    }
}

extension MailboxManager: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }

        for service in services {
            peripheral.discoverCharacteristics([LOCK_CHAR_UUID], for: service)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }

        print(service)
        for characteristic in characteristics {
            print(" " + characteristic.description)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if (characteristic.uuid == LOCK_CHAR_UUID) {
            if let error = error {
                print("Error writing to lock characteristic: " + error.localizedDescription )
                return
            }

            // Successfully locked or unlocked mailbox
        }
    }
}

class MailBoxPeripheral: CBPeripheral {
    
}
