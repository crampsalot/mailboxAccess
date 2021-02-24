//
//  MailboxManager.swift
//  MailboxAccess
//
//  Created by Isa Hashim on 2/23/21.
//

import CoreBluetooth

enum MailboxState {
    case connected
    case disconnected
    case authenticated
    case authFailed
    case locked
    case unlocked
}

protocol MailboxDelegate {
    func didUpdateState(mailboxManager: MailboxManager)
}

class MailboxManager: NSObject {
    private let MBOX_PERIPHERAL_NAME = "Fore"
    private let MBOX_SERVICE_UUID = CBUUID(string: "9B012401-BC30-CE9A-E111-0F67E491ABDE")
    private let LOCK_CHAR_UUID: CBUUID = CBUUID(string: "4ACBCD28-7425-868E-F447-915C8F00D0CB")
    private let MBOX_ID_CHAR_UUID: CBUUID = CBUUID(string: "4ACBCD28-7425-868E-F447-915C8F00D0CC")

    private let UNLOCK_VALUE = UInt8(0)
    private let LOCK_VALUE = UInt8(1)

    private var centralMgr: CBCentralManager?
    private var mailboxPeripheral: CBPeripheral?
    private var user: User?

    static let sharedInstance = MailboxManager()

    var delegate: MailboxDelegate?
    var state: MailboxState = .disconnected

    private override init() {
        super.init()
    }
    
    // MARK: - connect, disconnect, lock. unlock
    func connect(user: User) {
        self.user = user
        initBLE()
    }

    func disconnect() {
        guard let peripheral = mailboxPeripheral else {
            return
        }

        centralMgr?.cancelPeripheralConnection(peripheral)
    }

    func lock() {
        guard let peripheral = mailboxPeripheral else {
            return
        }

        guard let lockChar = getLockCharacteristic() else {
            return
        }

        peripheral.writeValue(getDataForLockCharacteristic(lock: true), for: lockChar, type: .withResponse)
    }

    func unlock() {
        guard let peripheral = mailboxPeripheral else {
            return
        }

        guard let lockChar = getLockCharacteristic() else {
            return
        }

        peripheral.writeValue(getDataForLockCharacteristic(lock: false), for: lockChar, type: .withResponse)
    }

    // MARK: - Utility functions

    private func getLockService() -> CBService? {
        guard let peripheral = mailboxPeripheral else {
            return nil
        }

        guard let services = peripheral.services else {
            return nil
        }

        let firstMatch = services.first { $0.uuid == MBOX_SERVICE_UUID }

        return firstMatch
    }

    private func getLockCharacteristic() -> CBCharacteristic? {
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
        let bleOptions = [CBCentralManagerOptionShowPowerAlertKey: NSNumber(booleanLiteral: true)]

        centralMgr = CBCentralManager(delegate: self, queue: nil, options: bleOptions)
    }

    private func getDataForLockCharacteristic(lock: Bool) -> Data {
        let value = lock ? LOCK_VALUE: UNLOCK_VALUE
        let data = Data([value])

        return data
    }
}

// MARK: - Extensions

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
        state = .connected
        delegate?.didUpdateState(mailboxManager: self)
        mailboxPeripheral?.discoverServices([MBOX_SERVICE_UUID])
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        state = .disconnected
        delegate?.didUpdateState(mailboxManager: self)
        mailboxPeripheral = nil
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

        for characteristic in characteristics {
            if (characteristic.uuid == MBOX_ID_CHAR_UUID) {
                // Once the mbox id characteristic is discovered, read it's value
                peripheral.readValue(for: characteristic)
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("Error writing to or reading from characteristic: " + error.localizedDescription )
            return
        }

        if (characteristic.uuid == LOCK_CHAR_UUID) {
            // Successfully locked or unlocked mailbox
            if let val = characteristic.value {
                let byteVal = UInt8(data: val)
                state = (byteVal == LOCK_VALUE) ? .locked : .unlocked
                delegate?.didUpdateState(mailboxManager: self)
            }
        } else if (characteristic.uuid == MBOX_SERVICE_UUID) {
            // Compare mbox Id of peripheral with mailbox id in user object
            // If different, disconnect
            if let val = characteristic.value {
                let intDataVal = Int(data: val)
                if user?.mailboxId == intDataVal {
                    state = .authenticated
                    delegate?.didUpdateState(mailboxManager: self)
                } else {
                    state = .authFailed
                    delegate?.didUpdateState(mailboxManager: self)
                    disconnect()
                }
            } else {
                disconnect()
            }
        }
    }
}
