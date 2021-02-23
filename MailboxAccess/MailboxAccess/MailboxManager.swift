//
//  MailboxManager.swift
//  MailboxAccess
//
//  Created by Isa Hashim on 2/23/21.
//

import CoreBluetooth

class MailboxManager: NSObject {
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
}
