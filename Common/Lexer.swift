//
//  Lexer.swift
//  Tracery
//
//  Created by Benzi on 10/03/17.
//  Copyright © 2017 Benzi Ahamed. All rights reserved.
//

import Foundation

// MARK:- Lexical Analysis

enum Token : CustomStringConvertible {
    
    case text(String)
    case op(String)
    case keyword(String)
    case number(Int)
    
    var rawText: String {
        switch self {
        case let .text(text): return text
        case let .op(c): return c
        case let .keyword(text): return text
        case let .number(value): return "\(value)"
        }
    }
    
    var description: String {
        switch self {
        case let .text(text): return "txt(\(text))"
        case let .op(c): return "op(\(c))"
        case let .keyword(text): return "key(\(text.uppercased()))"
        case let .number(value): return "num(\(value))"
        }
    }
    
    static let LEFT_SQUARE_BRACKET = Token.op("[")
    static let RIGHT_SQUARE_BRACKET = Token.op("]")
    static let COLON = Token.op(":")
    static let HASH = Token.op("#")
    static let COMMA = Token.op(",")
    static let DOT = Token.op(".")
    static let LEFT_ROUND_BRACKET = Token.op("(")
    static let RIGHT_ROUND_BRACKET = Token.op(")")
    static let LEFT_CURLY_BRACKET = Token.op("{")
    static let RIGHT_CURLY_BRACKET = Token.op("}")
    
    static let EQUAL_TO = Token.op("==")
    static let NOT_EQUAL_TO = Token.op("!=")
    
    static let KEYWORD_IF = Token.keyword("if")
    static let KEYWORD_THEN = Token.keyword("then")
    static let KEYWORD_ELSE = Token.keyword("else")
    static let KEYWORD_WHILE = Token.keyword("while")
    static let KEYWORD_DO = Token.keyword("do")
    static let KEYWORD_IN = Token.keyword("in")
    static let KEYWORD_NOT_IN = Token.keyword("not in")
    
    static let SPACE = Token.text(" ")
    
    var isConditionalOperator: Bool {
        return self == .EQUAL_TO
            || self == .NOT_EQUAL_TO
            || self == .KEYWORD_IN
            || self == .KEYWORD_NOT_IN
    }
}

extension Token : Equatable { }

func ==(lhs: Token, rhs: Token) -> Bool {
    switch (lhs, rhs) {
    case let (.op(lhs), .op(rhs)): return lhs == rhs
    case let (.text(lhs), .text(rhs)): return lhs == rhs
    case let (.keyword(lhs), .keyword(rhs)): return lhs == rhs
    case let (.number(lhs), .number(rhs)): return lhs == rhs
    default: return false
    }
}

extension Character {
    var isReserved: Bool {
        switch self {
        case "[","]",":","#",",","(",")",".","{","}": return true
        default: return false
        }
    }
}

struct Lexer {
    
    static func tokens(_ input: String) -> [Token] {
        
        var index = input.startIndex
        var tokens = [Token]()
        
        func advance() {
            input.formIndex(after: &index)
        }
        
        func rewind(count: Int) {
            input.formIndex(&index, offsetBy: -count)
        }
        
        var current: Character? {
            return index < input.endIndex ? input[index] : nil
        }
        
        var lookahead: Character? {
            let next = input.index(after: index)
            return next < input.endIndex ? input[next] : nil
        }
        
        func getEscapedCharacter() -> Character? {
            if current == "\\" {
                advance()
                if let c = current {
                    advance()
                    return c
                }
            }
            return nil
        }
        
        func getToken() -> Token? {
            guard let c = current else { return nil }
            
            // two character operators
            
            if let next = lookahead {
                let token: Token?
                switch (c, next) {
                case ("=","="): token = .op("==")
                case ("!","="): token = .op("!=")
                default: token = nil
                }
                if token != nil {
                    advance()
                    advance()
                    return token
                }
            }
            
            
            // everything else
            
            switch c {
                
            case let x where x.isReserved:
                advance()
                return .op("\(c)")
                
            case let x where "0"..."9" ~= x:
                var number = ""
                while let c = current, "0"..."9" ~= c {
                    number.append(c)
                    advance()
                }
                guard let value = Int(number) else { return .text(number) }
                return .number(value)
                
            case let c where c == " ":
                advance()
                return Token.SPACE
                
            default:
                var text = ""
                while let c = current, !c.isReserved  {
                    
                    // if next batch is a dual character op
                    // return immediately, the op will be consumed
                    // in the next call
                    if !text.isEmpty, let next = lookahead {
                        switch (c, next) {
                        case ("=","="), ("!","="):
                            return .text(text)
                        default:
                            break
                        }
                    }
                    
                    // escape sequences
                    if c == "\\" {
                        if let c = getEscapedCharacter() {
                            text.append(c)
                        }
                        return .text(text)
                    }
                    
                    // consume current character
                    text.append(c)
                    advance()
                    
                    // key word check needs to be performed
                    // only if we have consumed at least 3 characters
                    guard text.count >= 3 else { continue }
                    
                    // check if we greedily consumed a keyword
                    // keywords must be preceded by white space
                    // unless its if or while, in which case
                    // it must be preceded by [
                    // all keywords must be followed by a space
                    let keywords = [
                        "if ",
                        "then ",
                        "else ",
                        "while ",
                        "do ",
                        "not in ",
                        "in ",
                    ]
                    for keyword in keywords {
                        
                        // check if we have consumed at least x character
                        // as the keyword
                        guard let prevCharIndex = input.index(index, offsetBy: -keyword.count-1, limitedBy: input.startIndex) else { continue }
                        let prevChar = input[prevCharIndex]
                        
                        if text == keyword {
                            if prevChar == " " {
                                rewind(count: 1)
                                return .keyword(text.trim(fromEnd: 1))
                            }
                            if prevChar == "[", keyword == "if " || keyword == "while " {
                                rewind(count: 1)
                                return .keyword(text.trim(fromEnd: 1))
                            }
                            
                        }
                        else if text.hasSuffix(keyword), prevChar == " " {
                            let end = text.index(text.endIndex, offsetBy: -keyword.count)
                            rewind(count: keyword.count)
                            return .text(text.substring(to: end))
                        }
                    }
                    
                }
                return .text(text)
            }
            
        }
        
        
        
        while let token = getToken() {
            tokens.append(token)
        }
        return tokens
        
    }
    
}


extension String {
    func trim(fromEnd i: Int) -> String {
        return substring(to: index(endIndex, offsetBy: -i))
    }
    func trim(fromStart i: Int) -> String {
        return substring(from: index(startIndex, offsetBy: i))
    }
}
