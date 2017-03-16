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

enum ParserConditionOperator {
    case equalTo
    case notEqualTo
    case valueIn
    case valueNotIn
}

struct ParserCondition: CustomStringConvertible {
    let lhs: [ParserNode]
    let rhs: [ParserNode]
    let op: ParserConditionOperator
    var description: String {
        return "\(lhs) \(op) \(rhs)"
    }
}

enum ParserNode : CustomStringConvertible {
    
    // input nodes
    
    case text(String)
    case rule(name:String, mods:[Modifier])
    case tag(name:String, values:[TagValue])
    
    // control flow
    
    indirect case ifBlock(condition:ParserCondition, thenBlock:[ParserNode], elseBlock:[ParserNode]?)
    indirect case whileBlock(condition:ParserCondition, doBlock:[ParserNode])

    // procedures
    
    case runMod(name: String)
    case createTag(name: String)
    
    // args handling
    
    indirect case evaluateArg(nodes: [ParserNode])
    case clearArgs
    
    // low level flow control
    
    indirect case branch(check:ParserConditionOperator, thenBlock:[ParserNode], elseBlock:[ParserNode]?)
    
    public var description: String {
        switch self {
            
        case let .rule(name, mods):
            if mods.count > 0 {
                let mods = mods.map { "." + $0.name }.reduce("") { $0.0 + $0.1 }
                return "RULE (\(name) \(mods))"
            }
            return "RULE (\(name))"
            
        case let .tag(name, values):
            if values.count == 1 { return "tag(\(name)=\(values[0]))" }
            return "TAG_DEFN (\(name)=\(values))"
            
        case let .text(text):
            return "TXT (\(text))"
            
        case let .runMod(name):
            return "MOD_RUN (\(name))"
            
        case let .createTag(name):
            return "TAG_CREATE (\(name))"
            
        case let .evaluateArg(nodes):
            return "ARG_EVAL (\(nodes))"
            
        case .clearArgs:
            return "ARG_CLR"
            
        case let .ifBlock(condition, thenBlock, elseBlock):
            if let elseBlock = elseBlock {
                return "IF (\(condition) THEN \(thenBlock) ELSE \(elseBlock))"
            }
            return "IF (\(condition) THEN \(thenBlock))"
            
            
        case let .branch(check, thenBlock, elseBlock):
            if let elseBlock = elseBlock {
                return "BRNCH (ARGS\(check) THEN \(thenBlock) ELSE \(elseBlock))"
            }
            return "BRNCH (args \(check) THEN \(thenBlock))"
            
        case let .whileBlock(condition, doBlock):
            return "WHILE (\(condition) THEN \(doBlock))"
            
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
    static func gen(_ tokens: [Token]) throws -> [ParserNode] {
        return try gen(tokens[tokens.startIndex..<tokens.endIndex])
    }
    
    // code generation stage
    // tokens -> nodes
    static func gen(_ tokens: ArraySlice<Token>) throws -> [ParserNode] {
        
        // make a copy of the tokens slice
        // so that we can modify it
        var tokens = tokens
        
        var nodes = [ParserNode]()
        var index = tokens.startIndex
        
        func advance() {
            index += 1
        }
        
        var currentToken: Token? {
            return index < tokens.endIndex ? tokens[index] : nil
        }
        
        func getErrorLocation() -> String {
            var parsedText = "'"
            for i in tokens.startIndex..<index {
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
                            let currentIndex = index
                            while let tok = currentToken, tok != .COMMA, tok != .RIGHT_ROUND_BRACKET {
                                paramText.append(tok.rawText)
                                advance()
                            }
                            if paramText.isEmpty {
                                throw ParserError.error("parameter expected, but not found in modifier '\(modName)'")
                            }
                            do {
                                let nodes = try Parser.gen(tokens[currentIndex..<index])
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
                let currentIndex = index
                while let token = currentToken, token != .COMMA, token != .RIGHT_SQUARE_BRACKET {
                    tagValueText.append(token.rawText)
                    advance()
                }
                if tagValueText.isEmpty {
                    throw ParserError.error("value expected for tag '\(name)', but none found")
                }
                do {
                    let nodes = try Parser.gen(tokens[currentIndex..<index])
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
        
        func consumeOptionalWhitespace() {
            guard let tok = currentToken else { return }
            for c in tok.rawText.characters {
                if c != " " { return }
            }
            advance()
        }
        
        // parse a conditional block component
        // allowing inlining of sub-rules
        // e.g.
        // [if #[tag1:name]tag# == #[tag2:name]tag2# then ok else nope]
        //
        // to skip matching start and end token sets that need to 
        // be consumed inline
        // if allowsInlineToken matches [, inline counter is incremented
        // if isEndToken matches ], inline counter is decremented
        //
        // if an end token is reached when inline counter is zero
        // or the stop token is found, consumption stops immediately
        func consumeAndParseTokens(
                isInlineStartToken: (Token) -> Bool,
                isEndToken: (Token) -> Bool,
                orStopIfToken: Token? = nil, // halt immediately
                trimmingEndSpace: Bool = true
            ) throws -> [ParserNode] {
            
            let currentIndex = index
            var inlineCount = 0
            while let token = currentToken {
                if let stopper = orStopIfToken, token == stopper {
                    break
                }
                if isEndToken(token) {
                    if inlineCount == 0 {
                        break
                    }
                    inlineCount -= 1
                }
                else if isInlineStartToken(token) {
                    inlineCount += 1
                }
                advance()
            }
            var endIndex = index
            if trimmingEndSpace {
                // strip end space if present as token
                if tokens[endIndex-1] == .SPACE {
                    endIndex -= 1
                }
                // strip end space if present in text
                if case var .text(text) = tokens[endIndex-1] {
                    if text.hasSuffix(" ") {
                        text = text.substring(to: text.index(before: text.endIndex))
                    }
                    tokens[endIndex-1] = .text(text)
                }
            }
            return try Parser.gen(tokens[currentIndex..<endIndex])
        }
        
        func parseCondition() throws -> ParserCondition {
            
            // parses a condition of the form
            // rule ==|!=|in rule
            
            let lhs = try consumeAndParseTokens(
                isInlineStartToken: { $0 == .KEYWORD_IF || $0 == .KEYWORD_WHILE },
                isEndToken: { return $0.isConditionalOperator }
            )
            if lhs.count == 0 {
                throw ParserError.error("expected rule or text in condition")
            }
            
            let op: ParserConditionOperator
            let rhs: [ParserNode]
            
            switch currentToken {
                
            case let x where x == Token.EQUAL_TO:
                advance()
                consumeOptionalWhitespace()
                op = .equalTo
                rhs =  try consumeAndParseTokens(
                    isInlineStartToken: { $0 == .KEYWORD_IF || $0 == .KEYWORD_WHILE },
                    isEndToken: { return $0 == .KEYWORD_THEN || $0 == .KEYWORD_DO }
                )
                if rhs.count == 0 {
                    throw ParserError.error("expected rule or text after == in condition")
                }

                
            case let x where x == Token.NOT_EQUAL_TO:
                advance()
                consumeOptionalWhitespace()
                op = .notEqualTo
                rhs =  try consumeAndParseTokens(
                    isInlineStartToken: { $0 == .KEYWORD_IF || $0 == .KEYWORD_WHILE },
                    isEndToken: { return $0 == .KEYWORD_THEN || $0 == .KEYWORD_DO }
                )
                if rhs.count == 0 {
                    throw ParserError.error("expected rule or text after != in condition")
                }
                
            case let x where x == Token.KEYWORD_IN || x == Token.KEYWORD_NOT_IN:
                advance()
                consumeOptionalWhitespace()
                rhs =  try consumeAndParseTokens(
                    isInlineStartToken: { $0 == .KEYWORD_IF || $0 == .KEYWORD_WHILE },
                    isEndToken: { return $0 == .KEYWORD_THEN || $0 == .KEYWORD_DO }
                )
                // the rhs should evaluate to a single token
                // that is either a text or a rule
                if rhs.count > 0 {
                    if case .text = rhs[0] {
                        op = x == Token.KEYWORD_IN ? .equalTo : .notEqualTo
                    }
                    else {
                        op = x == Token.KEYWORD_IN ? .valueIn : .valueNotIn
                    }
                }
                else {
                    throw ParserError.error("expected rule after in/not in keyword")
                }
                
            default:
                rhs = [.text("")]
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
            
            let thenBlock = try consumeAndParseTokens(
                isInlineStartToken: { $0 == Token.LEFT_SQUARE_BRACKET },
                isEndToken: {  $0 == Token.RIGHT_SQUARE_BRACKET },
                orStopIfToken: Token.KEYWORD_ELSE
            )
            guard thenBlock.count > 0 else { throw ParserError.error("'then' must be followed by rule(s)") }

            var elseBlock:[ParserNode]? = nil
            if currentToken == .KEYWORD_ELSE {
                try parse(.KEYWORD_ELSE, error: nil) // will be there
                try parse(.text(" "), error: "expected space after else")
                let checkedElseBlock = try consumeAndParseTokens(
                    isInlineStartToken: { $0 == Token.LEFT_SQUARE_BRACKET },
                    isEndToken: {  $0 == Token.RIGHT_SQUARE_BRACKET }
                )
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
            let doBlock = try consumeAndParseTokens(
                isInlineStartToken: { _ in false },
                isEndToken: { $0 == Token.RIGHT_SQUARE_BRACKET }
            )
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
        
        return nodes
        
    }
    
}
