//
//  Reader.swift
//  APNGKit
//
//  Created by Wei Wang on 15/8/27.
//
//  Copyright (c) 2016 Wei Wang <onevcat@gmail.com>
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

#if os(macOS)
    import Cocoa
#else
    import UIKit
#endif

/**
*  Reader for binary data.
*  Put input data into an input stream and read it on requested.
*/
struct Reader {
    
    fileprivate var stream: InputStream
    fileprivate var totalBytesRead = 0
    fileprivate var dataLength: Int {
        return data.count
    }

    fileprivate let data: Data
    
    /// Built-in buffers. It will not be initiated until used.
    lazy var buffers: [Int: Array<UInt8>] = {
        var buffers = [Int: Array<UInt8>]()
        for i in 0...self.maxBufferCount {
            buffers[i] = Array<UInt8>(repeating: 0, count: i)
        }
        return buffers
    }()
    
    let maxBufferCount: Int
    
    init(data: Data, maxBuffer: Int = 0) {
        stream = InputStream(data: data)
        maxBufferCount = maxBuffer
        self.data = data
    }
    
    func beginReading() {
        if stream.streamStatus == .notOpen {
            stream.open()
        }
    }
    
    mutating func endReading() {
        if stream.streamStatus == .open {
            stream.close()
        }
        stream = InputStream(data: data)
    }
    
    /**
    Read some data into the input buffer.
    
    - parameter buffer:     Buffer to hold the data.
    - parameter bytesCount: The count of bytes should be read.
    
    - returns: The count of bytes read.
    */
    mutating func read(_ buffer: UnsafeMutablePointer<UInt8>, bytesCount: Int) -> Int {
        if stream.streamStatus == Stream.Status.atEnd {
            return 0
        }
        
        if stream.streamStatus != Stream.Status.open {
            fatalError("The stream is not in Open status. This may occur when you try " +
                       "to read before calling beginReading() or after endReading(). " +
                       "It could also be caused by you are trying to read from multiple threads. " +
                       "Reader is not support multithreads reading! Current status is: \(stream.streamStatus.rawValue)")
        }
        
        if bytesCount == 0 {
            print("Trying to read 0 byte.")
            return 0
        }
        
        if totalBytesRead < dataLength {
            let dataRead = stream.read(buffer, maxLength: bytesCount)
            totalBytesRead += dataRead
            
            return dataRead
        } else {
            return 0
        }
    }
    
    /**
    Use built-in buffer to read data.
    
    - parameter bytesCount: The count of bytes should be read.
    
    - returns: Raw data and the count of bytes read.
    */
    mutating func read(_ bytesCount: Int) -> (data: [UInt8], bytesCount: Int) {
        
        if stream.streamStatus == Stream.Status.atEnd {
            return ([], 0)
        }
        
        if stream.streamStatus != Stream.Status.open {
            fatalError("The stream is not in Open status. This may occur when you try to read before " +
                       "calling beginReading() or after endReading(). It could also be caused by you are " +
                       "trying to read from multiple threads. Reader is not support multithreads reading! " +
                       "Current status is: \(stream.streamStatus.rawValue)")
        }
        
        if bytesCount > maxBufferCount {
            fatalError("Can not read byte count: \(bytesCount) since it beyonds the maxBufferCount of " +
                       "the reader, which is \(maxBufferCount). Please try to use a larger buffer.")
        }
        
        if bytesCount == 0 {
            print("Trying to read 0 byte.")
            return ([], 0)
        }
        
        if totalBytesRead < dataLength {
            var buffer = buffers[bytesCount]!
            let dataRead = stream.read(&buffer, maxLength: buffer.count)
            totalBytesRead += dataRead
            
            return (buffer, dataRead)
        } else {
            return ([], 0)
        }
    }
}
