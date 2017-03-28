
//
//  Log.swift
//  QMobileDataStore
//
//  Created by Eric Marchand on 14/03/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import Foundation

import XCGLogger
public typealias Level = XCGLogger.Level
public typealias Logger = XCGLogger

let logger: Logger = Logger.forClass(Record.self)

extension Logger {

    class open func forClass(_ aClass: Swift.AnyClass) -> Logger {
         return Logger(identifier: NSStringFromClass(aClass), includeDefaultDestinations: true)
    }

    open func log(_ level: Level, _ closure: @autoclosure @escaping () -> Any?, functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line, userInfo: [String: Any] = [:]) {
        self.logln(level, functionName: functionName, fileName: fileName, lineNumber: lineNumber, userInfo: userInfo, closure: closure)
    }

}


