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
    case op(Character)
    
    var rawText: String {
        switch self {
        case let .text(text): return text
        case let .op(c): return "\(c)"
        }
    }
    
    var description: String {
        switch self {
        case let .text(text): return "'\(text)'"
        case let .op(c): return "op:\(c)"
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
}

extension Token : Equatable { }

func ==(lhs: Token, rhs: Token) -> Bool {
    switch (lhs, rhs) {
    case let (.op(lhs), .op(rhs)): return lhs == rhs
    case let (.text(lhs), .text(rhs)): return lhs == rhs
    default: return false
    }
}

extension Character {
    var isReserved: Bool {
        switch self {
        case "[","]",":","#",",","(",")",".": return true
        default: return false
        }
    }
}

struct Lexer {
    
    static func tokens(input: String) -> [Token] {
        
        var index = input.startIndex
        
        
        func advance() {
            input.characters.formIndex(after: &index)
        }
        
        var current: Character? {
            return index < input.endIndex ? input[index] : nil
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
            switch c {
            case let x where x.isReserved:
                advance()
                return .op(c)
            default:
                var text = ""
                while let c = current, !c.isReserved  {
                    if c == "\\" {
                        if let c = getEscapedCharacter() {
                            text.append(c)
                        }
                        continue
                    }
                    text.append(c)
                    advance()
                }
                return .text(text)
            }
        }
        
        
        var tokens = [Token]()
        while let token = getToken() {
            tokens.append(token)
        }
        return tokens
        
    }
    
}
