//
//  Parser.swift
//  Tracery
//
//  Created by Benzi on 10/03/17.
//  Copyright © 2017 Benzi Ahamed. All rights reserved.
//

import Foundation


// MARK:- Parsing


struct Modifier : CustomStringConvertible {
    var name: String
    var parameters: [ModifierParameter]
    
    var description: String {
        return ".\(name)(\(parameters))"
    }
}

struct ModifierParameter: CustomStringConvertible {
    var rawText: String
    var nodes: [ParserNode]
    
    var description: String {
        return rawText
    }
}

struct TagValue : CustomStringConvertible {
    var rawText: String
    var nodes: [ParserNode]
    
    var description: String { return rawText }
}

enum ParserNode : CustomStringConvertible {
    
    case text(String)
    case rule(name:String, mods:[Modifier])
    case tag(name:String, values:[TagValue])
    
    case mod(Modifier)
    case param(ModifierParameter)
    case exec(command: String)
    
    case tagValue(TagValue)
    case createTag(name: String)
    
    public var description: String {
        switch self {
            
        case let .rule(name, mods):
            if mods.count > 0 {
                let mods = mods.map { "." + $0.name }.reduce("") { $0.0 + $0.1 }
                return "rule(\(name) \(mods))"
            }
            return "rule(\(name))"
            
        case let .tag(name, values):
            if values.count == 1 { return "tag(\(name)=\(values[0]))" }
            return "tag(\(name)=\(values))"
            
        case let .text(text):
            return "text(\(text))"
            
        case let .mod(mod):
            return "mod(\(mod))"
            
        case let .param(param):
            return "param(\(param))"
            
        case let .exec(command):
            return "exec(\(command))"
            
        case let .tagValue(value):
            return "tagValue(\(value.rawText))"
            
        case let .createTag(name):
            return "createTag(\(name))"
            
        }
    }
}



enum ParserError : Error, CustomStringConvertible {
    case unexpectedEOF
    case error(String)
    var description: String {
        switch self {
        case .unexpectedEOF: return "unexpected EOF"
        case let .error(msg): return msg
        }
    }
}



struct Parser {
    
    // code generation stage
    // tokens -> nodes
    static func gen(tokens: [Token]) throws -> [ParserNode] {
        
        var nodes = [ParserNode]()
        var index = 0
        
        func advance() {
            index += 1
        }
        
        var currentToken: Token? {
            return index < tokens.count ? tokens[index] : nil
        }
        
        func getErrorLocation() -> String {
            var parsedText = "'"
            for i in 0..<index {
                parsedText.append(tokens[i].rawText)
            }
            parsedText.append("'")
            return parsedText
        }
        
        func parse(_ token: Token, error: String?) throws -> () {
            guard let current = currentToken else {
                if let e = error {
                    throw ParserError.error("\(e)")
                }
                throw ParserError.unexpectedEOF
            }
            guard current == token else {
                if let e = error {
                    throw ParserError.error("\(e)")
                }
                throw ParserError.error("expected: \(token) got: \(current)")
            }
            advance()
        }
        
        func parseText(_ error: String?) throws -> String {
            guard let current = currentToken else {
                if let e = error {
                    throw ParserError.error("\(e)")
                }
                throw ParserError.unexpectedEOF
            }
            guard case let .text(text) = current else {
                if let e = error {
                    throw ParserError.error("\(e), but got: '\(current.rawText)' near \(getErrorLocation())")
                }
                throw ParserError.error("expected: text got: \(current)")
            }
            advance()
            return text
        }
        
        func parseOptionalText() -> String {
            if let token = currentToken, case let .text(text) = token {
                advance()
                return text
            }
            return ""
        }
        
        func parseRule() throws -> ParserNode? {
            
            // #id#
            // #[set_tag]#
            // #id.mod1.mod2#
            // #id.mod(params)#
            
            try parse(.HASH, error: nil)
            
            let foundSomethingInsideHash = currentToken != .HASH
            
            while currentToken == .LEFT_SQUARE_BRACKET {
                try parseBrackets()
            }
            
            if currentToken == .HASH {
                try parse(.HASH, error: nil)
                if !foundSomethingInsideHash {
                    warn("repeating ## treated as empty rule")
                }
                return nil
            }
            
            // a single hash token?
            if currentToken == nil {
                return .text("#")
            }
            
            let name = parseOptionalText()
            
            var modifiers = [Modifier]()
            
            while currentToken == .DOT {
                try parse(.DOT, error: nil)
                
                let modName = try parseText("expected modifier name after . for rule '\(name)'")
                
                var modifier = Modifier.init(name: modName, parameters: [])
                if currentToken == .LEFT_ROUND_BRACKET {
                    try parse(.LEFT_ROUND_BRACKET, error: nil)
                    while let tok = currentToken, tok != .RIGHT_ROUND_BRACKET {
                        
                        func parseParameter() throws {
                            var paramText = ""
                            var paramTokens = [Token]()
                            while let tok = currentToken, tok != .COMMA, tok != .RIGHT_ROUND_BRACKET {
                                paramText.append(tok.rawText)
                                paramTokens.append(tok)
                                advance()
                            }
                            if paramText.isEmpty {
                                throw ParserError.error("parameter expected, but not found in modifier '\(modName)'")
                            }
                            do {
                                let nodes = try Parser.gen(tokens: paramTokens)
                                let parameter = ModifierParameter(rawText: paramText, nodes: nodes)
                                modifier.parameters.append(parameter)
                            } catch {
                                throw ParserError.error("parameter '\(paramText)' of modifier '\(modName)' in invalid, reason - \(error)")
                            }
                        }
                        
                        try parseParameter()
                        while let tok = currentToken, tok == .COMMA {
                            try parse(.COMMA, error: "expected , or ) after parameter name")
                            try parseParameter()
                        }
                    }
                    try parse(.RIGHT_ROUND_BRACKET, error: "expected ) to close modifier call")
                }
                modifiers.append(modifier)
                
            }
            
            
            try parse(.HASH, error: "closing # not found for rule '\(name)'")
            
            let rule = ParserNode.rule(name: name, mods: modifiers)
            trace("⚙️ parsed \(rule)")
            
            return rule
        }
        
        func parseTag() throws -> ParserNode {
            
            
            let name = try parseText("expected a tag name")
            
            try parse(.COLON, error: "tag '\(name)' must be followed by a :")
            
            var values = [TagValue]()
            
            // consume a rule stream
            func consumeTagValue() throws {
                var tagValueText = ""
                var tagValueTokens = [Token]()
                while let token = currentToken, token != .COMMA, token != .RIGHT_SQUARE_BRACKET {
                    tagValueTokens.append(token)
                    tagValueText.append(token.rawText)
                    advance()
                }
                if tagValueText.isEmpty {
                    throw ParserError.error("value expected for tag '\(name)', but none found")
                }
                do {
                    let nodes = try Parser.gen(tokens: tagValueTokens)
                    let tagValue = TagValue(rawText: tagValueText, nodes: nodes)
                    values.append(tagValue)
                }
                catch  {
                    throw ParserError.error("unable to parse value '\(tagValueText)' for tag '\(name)' reason - \(error)")
                }
            }
            
            try consumeTagValue()
            while let token = currentToken, token == .COMMA {
                try parse(.COMMA, error: nil)
                try consumeTagValue()
            }
            
            
            let tag = ParserNode.tag(name: name, values: values)
            
            trace("⚙️ parsed \(tag)")
            
            return tag
        }
        
        func parseBrackets() throws {
            
            try parse(.LEFT_SQUARE_BRACKET, error: nil)
            
            var somethingInsideBrackets = false
            
            while currentToken != .RIGHT_SQUARE_BRACKET {
                if currentToken == .HASH {
                    if let rule = try parseRule() {
                        nodes.append(rule)
                        somethingInsideBrackets = true
                    }
                }
                else
                if currentToken == .LEFT_SQUARE_BRACKET {
                    try parseBrackets()
                }
                else {
                    let tag = try parseTag()
                    nodes.append(tag)
                    somethingInsideBrackets = true
                }
            }
            
            if !somethingInsideBrackets {
                throw ParserError.error("empty [] not allowed")
            }
            
            try parse(.RIGHT_SQUARE_BRACKET, error: "closing ] not found")
        }
        
        
        while let token = currentToken {
            
            switch token {
                
            // [#name#][tag:name][tag:name1,name2,...]
            case Token.LEFT_SQUARE_BRACKET:
                try parseBrackets()
                
            // rule = #name# | #BRACKETS#
            case Token.HASH:
                if let rule = try parseRule() {
                    nodes.append(rule)
                }
                
            default:
                // combine all mergeable tokens
                // as a single text node
                var combined = token.rawText
                advance()
                while let current = currentToken,
                    current != .LEFT_SQUARE_BRACKET,
                    current != .HASH
                {
                    combined.append(current.rawText)
                    advance()
                }
                let text = ParserNode.text(combined)
                nodes.append(text)
                
                trace("⚙️ parsed \(text)")
            }
        }
        
        return nodes
        
    }
    
}
