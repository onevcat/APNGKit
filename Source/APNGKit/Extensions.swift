//
//  Extensions.swift
//  
//
//  Created by Wang Wei on 2021/10/05.
//

import Foundation

extension Data {
    var bytes: [Byte] { [Byte](self) }
    
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
    
    var characters: [Character] { map { .init(.init($0)) } }
    
    subscript(_ index: Int) -> Byte {
        self[index ... index].byte
    }
}

extension Int {
    // Convert an `Int` to four bytes of data, in network endian.
    var fourBytesData: Data {
        withUnsafeBytes(of: UInt32(self).bigEndian) {
            Data($0)
        }
    }
}

extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        return min(max(self, limits.lowerBound), limits.upperBound)
    }
}

extension FixedWidthInteger {
    public var bigEndianBytes: [Byte] {
        [Byte](withUnsafeBytes(of: self.bigEndian) { Data($0) })
    }
}

extension UnsignedInteger {
    // Convert some bytes (network endian) into a number.
    init(_ bytes: [Byte]) {
        precondition(bytes.count <= MemoryLayout<Self>.size)
        var value: UInt64 = 0
        for byte in bytes {
            value <<= 8
            value |= UInt64(byte)
        }
        self.init(value)
    }
}

func printLog(_ item: Any, logLevel: LogLevel = .default) {
    if logLevel == .off || LogLevel.current == .off {
        return
    }
    if logLevel <= LogLevel.current {
        print("[APNGKit] \(item)")
    }
}
