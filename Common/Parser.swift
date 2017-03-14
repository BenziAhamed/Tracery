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

enum ParserConditionOperator : String {
    case equalTo = "=="
    case notEqualTo = "!="
}

struct ParserCondition: CustomStringConvertible {
    let lhs: ParserNode
    let rhs: ParserNode
    let op: ParserConditionOperator
    var description: String {
        return "\(lhs) \(op) \(rhs)"
    }
}

enum ParserNode : CustomStringConvertible {
    
    case text(String)
    case rule(name:String, mods:[Modifier])
    case tag(name:String, values:[TagValue])
    
    indirect case ifBlock(condition:ParserCondition, thenBlock:[ParserNode], elseBlock:[ParserNode]?)
    indirect case whileBlock(condition:ParserCondition, doBlock:[ParserNode])
    
    case runMod(name: String)
    case createTag(name: String)
    
    indirect case evaluateArg(nodes: [ParserNode])
    case clearArgs
    indirect case branch(check:ParserConditionOperator, thenBlock:[ParserNode], elseBlock:[ParserNode]?)
    
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
            
        case let .runMod(name):
            return "runMod(\(name))"
            
        case let .createTag(name):
            return "createTag(\(name))"
            
        case let .evaluateArg(nodes):
            return "evaluateArg(\(nodes))"
            
        case .clearArgs:
            return "clearArgs"
            
        case let .ifBlock(condition, thenBlock, elseBlock):
            return "if(\(condition) then:\(thenBlock) else:\(elseBlock))"
            
        case let .branch(check, thenBlock, elseBlock):
            return "branch(args\(check.rawValue) then:\(thenBlock) else:\(elseBlock))"
            
        case let .whileBlock(condition, doBlock):
            return "while(\(condition) then:\(doBlock))"
            
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
        
        func parseRule(allowingTagsInside: Bool = true) throws -> ParserNode? {
            
            // #id#
            // #[set_tag]#
            // #id.mod1.mod2#
            // #id.mod(params)#
            
            try parse(.HASH, error: nil)
            
            let foundSomethingInsideHash = currentToken != .HASH
            
            if currentToken == .LEFT_SQUARE_BRACKET {
                if !allowingTagsInside {
                    throw ParserError.error("setting tags not allowed in this context")
                }
                while currentToken == .LEFT_SQUARE_BRACKET {
                    try parseBrackets()
                }
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
        
        func parseOptional(token: Token) {
            if let current = currentToken, current == token {
                advance()
            }
        }
        
        func consumeOptionalWhitespace() {
            guard let tok = currentToken else { return }
            for c in tok.rawText.characters {
                if c != " " { return }
            }
            advance()
        }
        
        
        // allows consuming matched [ ] pairs
        func consumeTokensUntilRightSquareBracket(orReaching stoppers: [Token] = []) throws -> [ParserNode] {
            var text = ""
            var bracketLevel = 0
            while let token = currentToken, stoppers.count > 0 && !stoppers.contains(token) || stoppers.count == 0 {
                if token == .LEFT_SQUARE_BRACKET {
                    bracketLevel += 1
                }
                if token == .RIGHT_SQUARE_BRACKET {
                    if bracketLevel > 0 {
                        bracketLevel -= 1
                    }
                    else {
                        break
                    }
                }
                text.append(token.rawText)
                advance()
            }
            // strip trailing space
            if text.characters.last == " " {
                text = text.substring(to: text.index(before: text.endIndex))
            }
            let nodes = try Parser.gen(tokens: Lexer.tokens(input: text))
            return nodes
        }
        
        func parseConditionRuleComponent(error: @autoclosure ()->String) throws -> ParserNode {
            // parse a rule component of a condition
            // i.e. its lhs or rhs node
            // it can be either a text or rule
            guard let token = currentToken else { throw ParserError.error(error()) }
            
            // if we have a text token consume it,
            // if it ends with a space, strip it
            if case var .text(text) = token {
                advance()
                if text.hasSuffix(" ") {
                    text = text.substring(to: text.index(before: text.endIndex))
                }
                return .text(text)
            }
            
            // if we have a rule, parse it
            if token == .HASH {
                let rule = try parseRule(allowingTagsInside: false)
                if let rule = rule {
                    consumeOptionalWhitespace()
                    return rule
                }
            }
            
            throw ParserError.error(error())
        }
        
        func parseCondition() throws -> ParserCondition {
            
            let lhs = try parseConditionRuleComponent(error: "expected rule or text in condition clause")
            
            let op: ParserConditionOperator
            let rhs: ParserNode
            
            switch currentToken {
                
            case let x where x == Token.EQUAL_TO:
                advance()
                consumeOptionalWhitespace()
                op = .equalTo
                rhs = try parseConditionRuleComponent(error: "expected rule or text after \(op.rawValue)")
                
            case let x where x == Token.NOT_EQUAL_TO:
                advance()
                consumeOptionalWhitespace()
                op = .notEqualTo
                rhs = try parseConditionRuleComponent(error: "expected rule or text after \(op.rawValue)")
                
            default:
                rhs = .text("")
                op = .notEqualTo
            }
            
            return ParserCondition.init(lhs: lhs, rhs: rhs, op: op)
        }
        
        func parseIfBlock() throws -> ParserNode {
            
            try parse(.KEYWORD_IF, error: "expected if block to start with if")
            try parse(.SPACE, error: "expected space after if")
            let condition = try parseCondition()
            try parse(.KEYWORD_THEN, error: "expected 'then' after condition")
            try parse(.SPACE, error: "expected space after 'then'")
            
            let thenBlock = try consumeTokensUntilRightSquareBracket(orReaching: [.KEYWORD_ELSE])
            guard thenBlock.count > 0 else { throw ParserError.error("'then' must be followed by rule(s)") }

            var elseBlock:[ParserNode]? = nil
            if currentToken == .KEYWORD_ELSE {
                try parse(.KEYWORD_ELSE, error: nil) // will be there
                try parse(.text(" "), error: "expected space after else")
                let checkedElseBlock = try consumeTokensUntilRightSquareBracket()
                if checkedElseBlock.count > 0 {
                    elseBlock = checkedElseBlock
                }
            }
            
            let block = ParserNode.ifBlock(
                condition: condition,
                thenBlock: thenBlock,
                elseBlock: elseBlock
            )
            
            trace("⚙️ parsed \(block)")
            return block
        }
        
        func parseWhileBlock() throws -> ParserNode {
            //
            // [while rule == condition do something]
            //
            try parse(.KEYWORD_WHILE, error: "expected `while`")
            try parse(.SPACE, error: "expected space after while")
            let condition = try parseCondition()
            try parse(.KEYWORD_DO, error: "expected `do` in while after condition")
            try parse(.SPACE, error: "expected space after do in while")
            let doBlock = try consumeTokensUntilRightSquareBracket()
            guard doBlock.count > 0 else { throw ParserError.error("'do' must be followed by rule(s)") }
            let whileBlock = ParserNode.whileBlock(condition: condition, doBlock: doBlock)
            trace("⚙️ parsed \(whileBlock)")
            return whileBlock
        }
        
        func parseBrackets() throws {
            
            try parse(.LEFT_SQUARE_BRACKET, error: nil)
            
            var somethingInsideBrackets = false
            
            func addToNodes(node: ParserNode) {
                nodes.append(node)
                somethingInsideBrackets = true
            }
            
            while currentToken != .RIGHT_SQUARE_BRACKET {
                if currentToken == .HASH {
                    if let rule = try parseRule() {
                        addToNodes(node: rule)
                    }
                }
                else if currentToken == .LEFT_SQUARE_BRACKET {
                    try parseBrackets()
                }
                else if currentToken == .KEYWORD_IF {
                    let ifBlock = try parseIfBlock()
                    addToNodes(node: ifBlock)
                }
                else if currentToken == .KEYWORD_WHILE {
                    let whileBlock = try parseWhileBlock()
                    addToNodes(node: whileBlock)
                }
                else {
                    let tag = try parseTag()
                    addToNodes(node: tag)
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
                // [if ...]
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
        
        
        // trace("⚙️ lexed \(tokens)")
        // trace("⚙️ parsed \(nodes)")
        
        return nodes
        
    }
    
}
