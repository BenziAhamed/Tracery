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
    
    var rawText: String {
        switch self {
        case let .text(text): return text
        case let .op(c): return c
        case let .keyword(text): return text
        }
    }
    
    var description: String {
        switch self {
        case let .text(text): return "'\(text)'"
        case let .op(c): return "op\(c)"
        case let .keyword(text): return "key_\(text)"
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
    
    static let EQUAL_TO = Token.op("==")
    static let NOT_EQUAL_TO = Token.op("!=")
    
    static let KEYWORD_IF = Token.keyword("if")
    static let KEYWORD_THEN = Token.keyword("then")
    static let KEYWORD_ELSE = Token.keyword("else")
}

extension Token : Equatable { }

func ==(lhs: Token, rhs: Token) -> Bool {
    switch (lhs, rhs) {
    case let (.op(lhs), .op(rhs)): return lhs == rhs
    case let (.text(lhs), .text(rhs)): return lhs == rhs
    case let (.keyword(lhs), .keyword(rhs)): return lhs == rhs
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

extension String {
    var isKeyword: Bool {
        switch self {
        case "if", "then", "else":
            return true
        default:
            return false
        }
    }
}

struct Lexer {
    
    static func tokens(input: String) -> [Token] {
        
        var index = input.startIndex
        
        
        func advance() {
            input.characters.formIndex(after: &index)
        }
        
        func rewind(count: Int) {
            input.characters.formIndex(&index, offsetBy: -count)
        }
        
        var current: Character? {
            return index < input.endIndex ? input[index] : nil
        }
        
        var lookahead: Character? {
            let next = input.characters.index(after: index)
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
                        continue
                    }
                    
                    // consume current character
                    text.append(c)
                    advance()
                    
                    // if we have consumed free text that ends with
                    // a keyword, split text into (previous, keyword)
                    // and return previous, rewind by count of keyword
                    let keywords = ["if","then","else"]
                    for keyword in keywords {
                        if text == keyword {
                            return .keyword(text)
                        }
                        if text.hasSuffix(keyword) {
                            let end = text.index(text.endIndex, offsetBy: -keyword.characters.count)
                            rewind(count: keyword.characters.count)
                            return .text(text.substring(to: end))
                        }
                    }
                    
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
