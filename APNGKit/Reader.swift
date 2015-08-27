//
//  Reader.swift
//  APNGKit
//
//  Created by WANG WEI on 2015/08/27.
//  Copyright © 2015年 OneV's Den. All rights reserved.
//

import Foundation

class Reader {
    
    static let dataEnd = -1
    
    private let stream: NSInputStream
    private var totalBytesRead = 0
    private let dataLength: Int
    
    private var buffers = [Int: Array<UInt8>]()
    
    let maxBufferCount: Int
    
    init(data: NSData, maxBuffer: Int) {
        stream = NSInputStream(data: data)
        maxBufferCount = maxBuffer
        dataLength = data.length
        
        for i in 1...maxBuffer {
            buffers[i] = Array<UInt8>(count: i, repeatedValue: 0)
        }
    }
    
    func beginReading() {
        stream.open()
    }
    
    func endReading() {
        stream.close()
    }
    
    func read(bytesCount: Int) -> (data: [UInt8], bytesCount: Int) {
        
        if stream.streamStatus == NSStreamStatus.AtEnd {
            return ([], Reader.dataEnd)
        }
        
        if stream.streamStatus != NSStreamStatus.Open {
            fatalError("The stream is not in Open status. This may occur when you try to read before calling beginReading() or after endReading(). It could also be caused by you are trying to read from multiple threads. Reader is not support multithreads reading! Current status is: \(stream.streamStatus.rawValue)")
        }
        
        if bytesCount > maxBufferCount {
            fatalError("Can not read byte count: \(bytesCount) since it beyonds the maxBufferCount of the reader, which is \(maxBufferCount). Please try to use a larger buffer.")
        }
        
        if bytesCount == 0 {
            print("Trying to read ")
            return ([], 0)
        }
        
        if totalBytesRead < dataLength {
            var buffer = buffers[bytesCount]!
            let dataRead = stream.read(&buffer, maxLength: buffer.count)
            totalBytesRead += dataRead
            
            return (buffer, dataRead)
        } else {
            return ([], Reader.dataEnd)
        }
    }
}