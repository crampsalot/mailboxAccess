//
//  MailboxManager.swift
//  MailboxAccess
//
//  Created by Isa Hashim on 2/23/21.
//

import CoreBluetooth

class MailboxManager: NSObject {
    private let BRIGHTDROP_MBOX_NAME = "BD_MBOX"

    static let sharedInstance = MailboxManager()

    var centralMgr: CBCentralManager?
    var mailboxPeripheral: CBPeripheral?

    private override init() {
        super.init()
        initBLE()
    }
    
    func lock() {
        
    }
    
    func unlock() {
        
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

        if !name.contains(BRIGHTDROP_MBOX_NAME) {
            return
        }

        print("Found device: " + peripheral.description)

        mailboxPeripheral = peripheral
        peripheral.delegate = self

        centralMgr?.stopScan()
        centralMgr?.connect(peripheral, options: nil)
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Connected: " + peripheral.description)
        mailboxPeripheral?.discoverServices(nil)
    }
}

extension MailboxManager: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }

        for service in services {
//            print(service)
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }

        print(service)
        for characteristic in characteristics {
            print(" " + characteristic.description)
        }
    }
}
