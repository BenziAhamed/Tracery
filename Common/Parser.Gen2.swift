//
//  Parser.Gen2.swift
//  Tracery
//
//  Created by Benzi on 25/03/17.
//  Copyright © 2017 Benzi Ahamed. All rights reserved.
//

import Foundation


extension Parser {
    
    static func gen2(_ tokens: [Token]) throws -> [ParserNode] {
        return try gen2(tokens[0..<tokens.count])
    }
    
    // parses rules, tags, weights and plaintext
    static func gen2(_ tokens: ArraySlice<Token>) throws -> [ParserNode] {
        
        var index = tokens.startIndex
        var endIndex = tokens.endIndex
        
        func advance() {
            index += 1
        }
        
        var currentToken: Token? {
            return index < endIndex ? tokens[index] : nil
        }
        
        var nextToken: Token? {
            return index+1 < endIndex ? tokens[index+1] : nil
        }
        
        func parseOptionalText() -> String? {
            guard let token = currentToken, case let .text(text) = token else { return nil }
            advance()
            return text
        }
        
        func parseText(_ error: @autoclosure () -> String? = nil) throws -> String {
            guard let token = currentToken, case let .text(text) = token else {
                throw ParserError.error(error() ?? "expected text")
            }
            advance()
            return text
        }
        
        func parseRule() throws -> [ParserNode] {
            
            var nodes = [ParserNode]()
            
            // rules will alwatys start with a hash
            try parse(.HASH)
            
            // a rule may contain sub rules
            // or tags
            while let token = currentToken, token == .LEFT_SQUARE_BRACKET {
                nodes.append(contentsOf: try parseTag())
            }
            
            // empty rule
            // ##
            if currentToken == .HASH {
                try parse(.HASH)
                nodes.append(.text(""))
                return nodes
            }
            
            // lonely hash? 
            // input = "...#"
            if currentToken == nil {
                nodes.append(.text("#"))
                return nodes
            }
            
            let name = parseOptionalText() ?? ""
            
            // #new_rule(fragment_list)#
            if currentToken == .LEFT_ROUND_BRACKET {
                if name == "" {
                    throw ParserError.error("new rule must have a name")
                }
                try parse(.LEFT_ROUND_BRACKET)
                let list = try parseFragmentList(context: "rule candidate", stopParsingFragmentBlockOnToken: Token.RIGHT_ROUND_BRACKET)
                var candidates = [ValueCandidate]()
                // we can clear an existing rule
                // or create an empty rule
                // using #rule()# syntax
                if list[0].count == 0 {
                    candidates.append(ValueCandidate(nodes: [.text("")]))
                }
                else {
                    candidates = list.map { return ValueCandidate(nodes: $0) }
                }
                nodes.append(.createRule(name: name, values: candidates))
                try parse(.RIGHT_ROUND_BRACKET, "expected ) after rule candidates list")
                try parse(.HASH, "expected # after rule definition")
                return nodes
            }
            
            // #rule?.mod1.mod2().mod3(list)#
            var modifiers = [Modifier]()
            while let token = currentToken, token == .DOT {
                try parse(.DOT)
                let modName = try parseText("expected modifier name after . in rule '\(name)'")
                var params = [ValueCandidate]()
                if currentToken == .LEFT_ROUND_BRACKET {
                    try parse(.LEFT_ROUND_BRACKET)
                    let argsList = try parseFragmentList(context: "parameter", stopParsingFragmentBlockOnToken: Token.RIGHT_ROUND_BRACKET)
                    params = argsList.map {
                        return ValueCandidate.init(nodes: $0)
                    }
                    try parse(.RIGHT_ROUND_BRACKET, "expected ) to close modifier call")
                }
                modifiers.append(Modifier(name: modName, parameters: params))
            }
            
            nodes.append(ParserNode.rule(name: name, mods: modifiers))
            
            try parse(.HASH, "closing # not found for rule '\(name)'")
            
            return nodes
        }
        
        func parseTag() throws -> [ParserNode] {
            
            var nodes = [ParserNode]()
            try parse(.LEFT_SQUARE_BRACKET)
            scanning: while let token = currentToken {
                switch token {
                case Token.HASH:
                    nodes.append(contentsOf: try parseRule())
                case Token.LEFT_SQUARE_BRACKET:
                    nodes.append(contentsOf: try parseTag())
                case Token.RIGHT_SQUARE_BRACKET:
                    break scanning
                default:
                    let name = try parseText("expected tag name")
                    try parse(.COLON, "expected : after tag '\(name)'")
                    let values = try parseFragmentList(context: "tag value", stopParsingFragmentBlockOnToken: Token.RIGHT_SQUARE_BRACKET)
                    if values[0].count == 0 {
                        throw ParserError.error("expected a tag value")
                    }
                    let tagValues = values.map { return ValueCandidate.init(nodes: $0) }
                    nodes.append(ParserNode.tag(name: name, values: tagValues))
                }
            }
            try parse(.RIGHT_SQUARE_BRACKET)
            return nodes
        }
        
        func parseWeight() throws -> ParserNode {
            try parse(.COLON)
            // if there is a next token, and it is a number
            // then we have a weight, else treat colon as raw text
            guard let token = currentToken, case let .number(value) = token else {
                return .text(":")
            }
            advance() // since we can consume the number
            return .weight(value: value)
        }
        
        
        func parseCondition() throws -> ParserCondition {
            var lhs = try parseFragmentSequence()
            stripTrailingSpace(from: &lhs)
            
            let op: ParserConditionOperator
            var rhs: [ParserNode]
            
            switch currentToken {
            case let x where x == Token.EQUAL_TO:
                advance()
                parseOptional(.SPACE)
                op = .equalTo
                rhs = try parseFragmentSequence()
                if rhs.count == 0 {
                    throw ParserError.error("expected rule or text after == in condition")
                }
            case let x where x == Token.NOT_EQUAL_TO:
                advance()
                parseOptional(.SPACE)
                op = .notEqualTo
                rhs = try parseFragmentSequence()
                if rhs.count == 0 {
                    throw ParserError.error("expected rule or text after != in condition")
                }
            case let x where x == Token.KEYWORD_IN || x == Token.KEYWORD_NOT_IN:
                advance()
                parseOptional(.SPACE)
                rhs = try parseFragmentSequence()
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
            stripTrailingSpace(from: &rhs)
            return ParserCondition.init(lhs: lhs, rhs: rhs, op: op)
        }
        
        func parseIfBlock() throws -> [ParserNode] {
            try parse(.LEFT_SQUARE_BRACKET)
            try parse(.KEYWORD_IF)
            try parse(.SPACE, "expected space after if")
            let condition = try parseCondition()
            try parse(.KEYWORD_THEN, "expected 'then' after condition")
            try parse(.SPACE, "expected space after 'then'")
            var thenBlock = try parseFragmentSequence()
            guard thenBlock.count > 0 else { throw ParserError.error("'then' must be followed by rule(s)") }
            var elseBlock:[ParserNode]? = nil
            if currentToken == .KEYWORD_ELSE {
                stripTrailingSpace(from: &thenBlock)
                try parse(.KEYWORD_ELSE)
                try parse(.SPACE, "expected space after else")
                let checkedElseBlock = try parseFragmentSequence()
                if checkedElseBlock.count > 0 {
                    elseBlock = checkedElseBlock
                }
                else {
                    throw ParserError.error("'else' must be followed by rule(s)")
                }
            }
            let block = ParserNode.ifBlock(condition: condition, thenBlock: thenBlock, elseBlock: elseBlock)
            try parse(.RIGHT_SQUARE_BRACKET)
            return [block]
        }
        
        func parseWhileBlock() throws -> [ParserNode] {
            try parse(.LEFT_SQUARE_BRACKET)
            try parse(.KEYWORD_WHILE)
            try parse(.SPACE, "expected space after while")
            let condition = try parseCondition()
            try parse(.KEYWORD_DO, "expected `do` in while after condition")
            try parse(.SPACE, "expected space after do in while")
            let doBlock = try parseFragmentSequence()
            guard doBlock.count > 0 else { throw ParserError.error("'do' must be followed by rule(s)") }
            let whileBlock = ParserNode.whileBlock(condition: condition, doBlock: doBlock)
            try parse(.RIGHT_SQUARE_BRACKET)
            return [whileBlock]
        }
        
        func parseFragmentList(context: String, stopParsingFragmentBlockOnToken: Token) throws -> [[ParserNode]] {
            let stoppers = [Token.COMMA, stopParsingFragmentBlockOnToken]
            var list = [[ParserNode]]()
            
            // list -> fragment more_fragments
            // more_fragments -> , fragment more_fragments | e
            func parseMoreFragments(list: inout [[ParserNode]]) throws {
                if currentToken != Token.COMMA { return }
                try parse(.COMMA)
                let moreFragments = try parseFragmenSequenceWithContext(until: stoppers)
                if moreFragments.count == 0 {
                    throw ParserError.error("expected \(context) after ,")
                }
                list.append(moreFragments)
                try parseMoreFragments(list: &list)
            }
            
            let block = try parseFragmenSequenceWithContext(until: stoppers)
            list.append(block)
            try parseMoreFragments(list: &list)
            
            return list
        }
        
        func parse(_ token: Token, _ error: @autoclosure () -> String? = nil) throws {
            guard let c = currentToken else {
                throw ParserError.error(error() ?? "unexpected eof")
            }
            guard c == token else {
                throw ParserError.error(error() ?? "token mismatch expected \(token), got: \(c)")
            }
            advance()
        }
        
        func parseOptional(_ token: Token) {
            guard let c = currentToken, c == token else { return }
            advance()
        }
        
        // a fragment is the most basic block in tracery
        // a fragement can contain multiple parser nodes though
        // #rule# is a fragment with 1 node
        // #[tag:value]rule# is a fragment with 2 nodes
        func parseFragment() throws -> [ParserNode]? {
            var nodes = [ParserNode]()
            guard let token = currentToken else { return nil }
            switch token {
            case Token.HASH:
                nodes.append(contentsOf: try parseRule())
            case Token.LEFT_SQUARE_BRACKET:
                guard let next = nextToken else { return nil }
                switch next {
                case Token.KEYWORD_IF:
                    nodes.append(contentsOf: try parseIfBlock())
                case Token.KEYWORD_WHILE:
                    nodes.append(contentsOf: try parseWhileBlock())
                default:
                    nodes.append(contentsOf: try parseTag())
                }
            case Token.COLON:
                nodes.append(try parseWeight())
            case .text, .number:
                nodes.append(.text(token.rawText))
                advance()
            default:
                return nil
                
            }
            return nodes
        }
        
        
        // parses a sequence of fragments
        // i.e. until a 'hanging' token is found
        // - #r##r# parses 2 rules
        // - #r#,#r# parses 1 rule
        // more context is required to decide if the hanging ','
        // part of a fragment list e.g. as tag value candidates
        // or just part of raw text, as in the entire input
        // was '#r#,#r#' which will parse to RULE,TXT(,),RULE nodes
        func parseFragmentSequence() throws -> [ParserNode] {
            var block = [ParserNode]()
            while let fragment = try parseFragment() {
                block.append(contentsOf: fragment)
            }
            return block
        }
        
        // consume as many fragments as possible, until any of the stopper
        // tokens are reached
        // the default behaviour is to parse an valid input string entirely
        // in one shot, since no stopper tokens are specified
        // stopper tokens can be used to separate greedy calls, 
        // for example:
        // parsing a comma separated list of fragments
        // #r1#,#r2#,[t:1],#[t:2]# can be parsed by calling greedy 3 times
        // with a stopper of 1 comma
        func parseFragmenSequenceWithContext(until stoppers: [Token] = []) throws -> [ParserNode] {
            var nodes = [ParserNode]()
            while currentToken != nil {
                nodes.append(contentsOf: try parseFragmentSequence())
                guard let token = currentToken, !stoppers.contains(token) else {
                    break
                }
                // at this stage, we may have consumed
                // all tokens, or reached a lone token that we can
                // treat as text since it is not a stopper
                nodes.append(.text(token.rawText))
                advance()
            }
            return flattenText(nodes)
        }
        
        do {
            // we parse as much as possible, until we hit
            // a lone non-text token. If we were able to
            // parse out previous tokens, this lone
            // token is stopping us from moving forward,
            // so treat it as a text token, and move forward
            // this scheme allows us to consume hanging non-text
            // nodes as plain-text, and avoids unnecessarily
            // escaping tokens
            // "hello world."
            // tokens: txt(hello world), op(.)
            // nodes : TXT(hello world), TXT(.)
            return try parseFragmenSequenceWithContext()
        }
        catch ParserError.error(let message) {
            
            // generate a readable error message like so
            //
            // expected : after tag 'tag'     # the underlying message
            //     #[tag❌]#                  # the full input text, with marker
            //     .....^                     # location highlighter

            
            let end = min(index, endIndex-1)
            let consumed = tokens[0...end].map { $0.rawText }.joined()
            var all = tokens.map { $0.rawText }.joined()
            let location = index == endIndex ? consumed.characters.count : consumed.characters.count-1
            all.insert("❌", at: all.index(all.startIndex, offsetBy: location, limitedBy: all.endIndex)!)
            let lines = [
                message,
                "    " + all,
                "    " + String(repeating: ".", count: location) + "^",
                ""
            ]
            throw ParserError.error(lines.joined(separator: "\n"))
        }
        
    }
    
    
    // combine a stream of text nodes into a single node
    // affects debug legibility and reduces interpretation time
    // (by a very very miniscule amount only though)
    // hence, this is mainly for sane and legible trace output
    private static func flattenText(_ nodes: [ParserNode]) -> [ParserNode] {
        var output = [ParserNode]()
        var i = nodes.startIndex
        while i < nodes.endIndex {
            switch nodes[i] {
            case .text(let text):
                var t = text
                i += 1
                while i < nodes.endIndex, case let .text(text) = nodes[i] {
                    t.append(text)
                    i += 1
                }
                output.append(.text(t))
            default:
                output.append(nodes[i])
                i += 1
            }
        }
        return output
    }
    
    
    private static func stripTrailingSpace(from nodes: inout [ParserNode]) {
        guard let last = nodes.last, case let .text(content) = last else { return }
        if content == " " {
            nodes.removeLast()
        }
        else if content.hasSuffix(" ") {
            nodes[nodes.count-1] = .text(content.substring(to: content.index(before: content.endIndex)))
        }
    }

}
