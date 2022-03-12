//
//  FileReaderTests.swift
//  
//
//  Created by Wang Wei on 2021/10/19.
//

import Foundation
import XCTest
@testable import APNGKit

class FileReaderTests: XCTestCase {
    
    static let fileName: String = "sample-\(UUID().uuidString)"
    static let emptyFileName: String = "sample-empty-\(UUID().uuidString)"
    
    static var tmpFileURL: URL {
        let tmp = NSTemporaryDirectory().appending(fileName)
        return URL(fileURLWithPath: tmp)
    }
    
    static var tmpEmptyFile: URL {
        let tmp = NSTemporaryDirectory().appending(emptyFileName)
        return URL(fileURLWithPath: tmp)
    }
    
    static override func setUp() {
        let data = Data([1,2,3,4,5])
        do {
            try data.write(to: tmpFileURL)
            try Data().write(to: tmpEmptyFile)
        } catch {
            XCTFail("Cannot write temp file data for testing.")
        }
    }
    
    override class func tearDown() {
        try? FileManager.default.removeItem(at: tmpFileURL)
        try? FileManager.default.removeItem(at: tmpEmptyFile)
    }
    
    func testReadZeroByteEmpty() throws {
        let reader = try FileReader(url: Self.tmpEmptyFile)
        let data = try reader.read(upToCount: 0)
        XCTAssertNil(data)
    }
    
    func testReadOneByteEmpty() throws {
        let reader = try FileReader(url: Self.tmpEmptyFile)
        let data = try reader.read(upToCount: 1)
        XCTAssertNil(data)
    }
    
    func testReadNegativeByteEmpty() throws {
        let reader = try FileReader(url: Self.tmpEmptyFile)
        let data = try reader.read(upToCount: -1)
        XCTAssertNil(data)
    }
    
    func testReadAll() throws {
        let reader = try FileReader(url: Self.tmpFileURL)
        let data = try reader.read(upToCount: 100)
        XCTAssertEqual([1,2,3,4,5], data?.bytes)
        
        XCTAssertNil(try reader.read(upToCount: 1))
    }
    
    func testReadZeroByteData() throws {
        let reader = try FileReader(url: Self.tmpFileURL)
        let data1 = try reader.read(upToCount: 0)
        let data2 = try reader.read(upToCount: 1)
        let data3 = try reader.read(upToCount: 0)
        let data4 = try reader.read(upToCount: 2)
        let data5 = try reader.read(upToCount: 0)
        let data6 = try reader.read(upToCount: 3)
        let data7 = try reader.read(upToCount: 0)
        let data8 = try reader.read(upToCount: 4)
        
        XCTAssertEqual([], data1?.bytes)
        XCTAssertEqual([1], data2?.bytes)
        XCTAssertEqual([], data3?.bytes)
        XCTAssertEqual([2,3], data4?.bytes)
        XCTAssertEqual([], data5?.bytes)
        XCTAssertEqual([4,5], data6?.bytes)
        XCTAssertNil(data7)
        XCTAssertNil(data8)
    }

    func testReadAllByByte() throws {
        let reader = try FileReader(url: Self.tmpFileURL)
        let data1 = try reader.read(upToCount: 1)
        let data2 = try reader.read(upToCount: 1)
        let data3 = try reader.read(upToCount: 1)
        XCTAssertEqual([1], data1?.bytes)
        XCTAssertEqual([2], data2?.bytes)
        XCTAssertEqual([3], data3?.bytes)
    }
    
    func testReadAllByGroup() throws {
        let reader = try FileReader(url: Self.tmpFileURL)
        let data1 = try reader.read(upToCount: 1)
        let data2 = try reader.read(upToCount: 2)
        let data3 = try reader.read(upToCount: 3)
        let data4 = try reader.read(upToCount: 4)
        XCTAssertEqual([1], data1?.bytes)
        XCTAssertEqual([2,3], data2?.bytes)
        XCTAssertEqual([4,5], data3?.bytes)
        XCTAssertNil(data4)
    }
    
    func testCanSeek() throws {
        let reader = try FileReader(url: Self.tmpFileURL)
        try reader.seek(toOffset: 1)
        let data = try reader.read(upToCount: 100)
        XCTAssertEqual([2, 3, 4, 5], data?.bytes)
    }
    
    func testReadThenSeek() throws {
        let reader = try FileReader(url: Self.tmpFileURL)
        let data1 = try reader.read(upToCount: 1)
        XCTAssertEqual([1], data1?.bytes)
        
        try reader.seek(toOffset: 2)
        let data2 = try reader.read(upToCount: 1)
        XCTAssertEqual([3], data2?.bytes)
    }
    
    func testReadThenSeekBack() throws {
        let reader = try FileReader(url: Self.tmpFileURL)
        let data1 = try reader.read(upToCount: 1)
        XCTAssertEqual([1], data1?.bytes)
        
        try reader.seek(toOffset: 0)
        let data2 = try reader.read(upToCount: 1)
        XCTAssertEqual([1], data2?.bytes)
    }
    
    func testSeekTooMuch() throws {
        let reader = try FileReader(url: Self.tmpFileURL)
        try reader.seek(toOffset: 100)
        let data = try reader.read(upToCount: 1)
        XCTAssertNil(data)
    }
    
    func testGetOffset() throws {
        let zeroReader = try FileReader(url: Self.tmpEmptyFile)
        XCTAssertEqual(0, try zeroReader.offset())
        _ = try zeroReader.read(upToCount: 10)
        XCTAssertEqual(0, try zeroReader.offset())
        
        let normalReader = try FileReader(url: Self.tmpFileURL)
        XCTAssertEqual(0, try normalReader.offset())
        _ = try normalReader.read(upToCount: 1)
        XCTAssertEqual(1, try normalReader.offset())
        _ = try normalReader.read(upToCount: 2)
        XCTAssertEqual(3, try normalReader.offset())
        _ = try normalReader.read(upToCount: 3)
        XCTAssertEqual(5, try normalReader.offset())
        _ = try normalReader.read(upToCount: 4)
        XCTAssertEqual(5, try normalReader.offset())
    }
    
    func testFileReaderClone() throws {
        let reader1 = try FileReader(url: Self.tmpFileURL)
        let data1 = try reader1.read(upToCount: 1)
        XCTAssertEqual([1], data1?.bytes)
        
        let reader2 = try reader1.clone()
        
        let data2_1 = try reader1.read(upToCount: 2)
        let data2_2 = try reader2.read(upToCount: 2)
        XCTAssertEqual([2,3], data2_1?.bytes)
        XCTAssertEqual([2,3], data2_2?.bytes)
        
        let data3_1 = try reader1.read(upToCount: 2)
        XCTAssertEqual([4,5], data3_1?.bytes)
        
        try reader1.seek(toOffset: 0)
        let data1_1 = try reader1.read(upToCount: 2)
        XCTAssertEqual([1, 2], data1_1?.bytes)
        
        let data3_2 = try reader2.read(upToCount: 2)
        XCTAssertEqual([4,5], data3_2?.bytes)
    }
}
