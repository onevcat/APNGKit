//
//  LogLevel.swift
//  
// 
//  Created by: onevcat (Wei Wang) on 2022/05/29
//

import Foundation

/// Log level when APNGKit to determine if the log should be printed into console.
public enum LogLevel: Int32, Comparable {
    public static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
    
    /// The log should be turned off.
    case off       = 0
    /// The default log level. Only critical issues or errors will be printed
    case `default` = 0x00000001
    /// Also log some ignorable logs for diagnose purpose.
    case info      = 0x00001000
    /// Verbose log can be used to show all information. Not in use now.
    case verbose   = 0x10000000
    
    /// The global setting of the log printed by APNGKit.
    public static var current: LogLevel = .default
}
