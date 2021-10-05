//
//  Extensions.swift
//  
//
//  Created by Wang Wei on 2021/10/05.
//

import Foundation


extension Data {
    var bytes: [Byte] { [UInt8](self) }
    
    var intValue: Int {
        Int(UInt32(bytes))
    }
    
    var byte: Byte {
        guard count == 1 else {
            assertionFailure("Trying to converting wrong number of data to a single byte")
            return 0
        }
        return withUnsafeBytes { $0.load(as: Byte.self) }
    }
    
    subscript(_ index: Int) -> Byte {
        self[index ... index].byte
    }
}

extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        return min(max(self, limits.lowerBound), limits.upperBound)
    }
}

extension FixedWidthInteger {
    public var bigEndianBytes: [UInt8] {
        [UInt8](withUnsafeBytes(of: self.bigEndian) { Data($0) })
    }
}

extension UnsignedInteger {
    init(_ bytes: [UInt8]) {
        precondition(bytes.count <= MemoryLayout<Self>.size)
        var value: UInt64 = 0
        for byte in bytes {
            value <<= 8
            value |= UInt64(byte)
        }
        self.init(value)
    }
}
