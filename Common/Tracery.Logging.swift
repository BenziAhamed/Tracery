//
//  Tracery.Logging.swift
//  Tracery
//
//  Created by Benzi on 10/03/17.
//  Copyright © 2017 Benzi Ahamed. All rights reserved.
//

import Foundation


extension Tracery {

    public enum LoggingLevel : Int {
        case none = 0
        case errors
        case warnings
        case info
        case verbose
    }
    
    public static var logLevel = LoggingLevel.errors
    
    static func log(level: LoggingLevel, message: @autoclosure () -> String) {
        guard logLevel.rawValue >= level.rawValue else { return }
        print(message())
    }

    func trace(_ message: @autoclosure () -> String) {
        let indent = String(repeating: "   ", count: stackDepth)
        Tracery.log(level: .verbose, message: "\(indent)\(message())")
    }
    
}

func info(_ message: @autoclosure () -> String) {
    Tracery.log(level: .info, message: "ℹ️ \(message())")
}

func warn(_ message: @autoclosure () -> String) {
    Tracery.log(level: .warnings, message: "⚠️ \(message())")
}

func error(_ message: @autoclosure () -> String) {
    Tracery.log(level: .errors, message: "⛔️ \(message())")
}

func trace(_ message: @autoclosure () -> String) {
    Tracery.log(level: .verbose, message: message)
}














