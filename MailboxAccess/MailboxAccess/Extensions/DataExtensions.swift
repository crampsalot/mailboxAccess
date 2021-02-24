//
//  DataExtensions.swift
//  MailboxAccess
//
//  Created by Isa Hashim on 2/23/21.
//

import Foundation

// Data Extensions:
// Taken from:
//  https://stackoverflow.com/questions/38023838/round-trip-swift-number-types-to-from-data
// so that we can do things like:
//
//  if let val = characteristic.value {
//      let intDataVal = Int(data: val)  // <=====
//      ...
//  }
//
protocol DataConvertible {
    init?(data: Data)
    var data: Data { get }
}

extension DataConvertible where Self: ExpressibleByIntegerLiteral{
    init?(data: Data) {
        var value: Self = 0
        guard data.count == MemoryLayout.size(ofValue: value) else { return nil }
        _ = withUnsafeMutableBytes(of: &value, { data.copyBytes(to: $0)} )
        self = value
    }

    var data: Data {
        return withUnsafeBytes(of: self) { Data($0) }
    }
}

extension Int : DataConvertible { }
extension UInt8 : DataConvertible { }
