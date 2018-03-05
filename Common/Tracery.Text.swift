//
//  Tracery.Text.swift
//  Tracery
//
//  Created by Benzi on 21/03/17.
//  Copyright © 2017 Benzi Ahamed. All rights reserved.
//

import Foundation


// File format that can scan plain text

extension Tracery {
    
    convenience public init(path: String) {
        if let reader = StreamReader(path: path) {
            self.init { TextParser.parse(lines: reader) }
        }
        else {
            warn("unable to parse input file: \(path)")
            self.init()
        }
    }
    
    convenience public init(lines: [String]) {
        self.init { TextParser.parse(lines: lines) }
    }
    
}

struct TextParser {
    
    enum State {
        case consumeRule
        case consumeDefinitions
    }
    
    static func parse<S: Sequence>(lines: S) -> [String: Any] where S.Iterator.Element == String {
        
        var ruleSet = [String: Any]()
        var state = State.consumeRule
        var rule = ""
        var candidates = [String]()
        
        func createRule() {
            if ruleSet[rule] != nil {
                warn("rule '\(rule)' defined twice, will be overwritten")
            }
            if candidates.count == 0 {
                candidates.append("")
            }
            ruleSet[rule] = candidates
        }
        
        for line in lines {
            switch state {
            case .consumeRule:
                if line.count > 2, line.hasPrefix("["), line.hasSuffix("]") {
                    let start = line.index(after: line.startIndex)
                    let end = line.index(before: line.endIndex)
					rule = String(line[start..<end])
                    state = .consumeDefinitions
                }
            case .consumeDefinitions:
                if line == "" {
                    createRule()
                    candidates.removeAll()
                    state = .consumeRule
                }
                else {
                    candidates.append(line)
                }
            }
        }
        // if we reached the end, and
        // we are in the midst of consuming
        // definitions, create a rule
        if state == .consumeDefinitions  {
            createRule()
        }
        
        return ruleSet
    }
    
}

class StreamReader  {
    
    let encoding : String.Encoding
    let chunkSize : Int
    
    var fileHandle : FileHandle!
    let buffer : NSMutableData!
    let delimData : Data!
    var atEof : Bool = false
    
    init?(path: String, delimiter: String = "\n", encoding: String.Encoding = .utf8, chunkSize : Int = 4096) {
        self.chunkSize = chunkSize
        self.encoding = encoding
        
        if let fileHandle = FileHandle(forReadingAtPath: path),
            let delimData = delimiter.data(using: encoding),
            let buffer = NSMutableData(capacity: chunkSize)
        {
            self.fileHandle = fileHandle
            self.delimData = delimData
            self.buffer = buffer
        } else {
            self.fileHandle = nil
            self.delimData = nil
            self.buffer = nil
            return nil
        }
    }
    
    deinit {
        self.close()
    }
    
    /// Return next line, or nil on EOF.
    func nextLine() -> String? {
        precondition(fileHandle != nil, "Attempt to read from closed file")
        
        if atEof {
            return nil
        }
        
        // Read data chunks from file until a line delimiter is found:
        var range = buffer.range(of: delimData, options: [], in: NSMakeRange(0, buffer.length))
        while range.location == NSNotFound {
            let tmpData = fileHandle.readData(ofLength: chunkSize)
            if tmpData.count == 0 {
                // EOF or read error.
                atEof = true
                if buffer.length > 0 {
                    // Buffer contains last line in file (not terminated by delimiter).
                    let line = String(data: buffer as Data, encoding: encoding)
                    
                    buffer.length = 0
                    return line as String?
                }
                // No more lines.
                return nil
            }
            buffer.append(tmpData)
            range = buffer.range(of: delimData, options: [], in: NSMakeRange(0, buffer.length))
        }
        
        // Convert complete line (excluding the delimiter) to a string:
        let line = String(data: buffer.subdata(with: NSMakeRange(0, range.location)),
                            encoding: encoding)
        // Remove line (and the delimiter) from the buffer:
        buffer.replaceBytes(in: NSMakeRange(0, range.location + range.length), withBytes: nil, length: 0)
        
        return line
    }
    
    /// Start reading from the beginning of file.
    func rewind() -> Void {
        fileHandle.seek(toFileOffset: 0)
        buffer.length = 0
        atEof = false
    }
    
    /// Close the underlying file. No reading must be done after calling this method.
    func close() -> Void {
        fileHandle?.closeFile()
        fileHandle = nil
    }
}

extension StreamReader: Sequence {
    func makeIterator() -> AnyIterator<String> {
        return AnyIterator<String> {
            return self.nextLine()
        }
    }
}


