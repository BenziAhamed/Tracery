//
//  Tracery.swift
//  
//
//  Created by Benzi on 10/03/17.
//
//

import Foundation

struct RuleMapping {
    let candidates: [RuleCandidate]
    var selector: RuleCandidateSelector
}

struct RuleCandidate {
    let text: String
    let nodes: [ParserNode]
}

struct TagMapping {
    let candidates: [String]
    let selector: RuleCandidateSelector
}


public class Tracery {
    
    private(set) var ruleSet: [String: RuleMapping]
    private(set) var tags: [String: TagMapping]
    private(set) var mods: [String: (String,[String])->String]
    
    public var ruleNames: [String] { return ruleSet.keys.map { $0 } }
    
    convenience public init() {
        self.init {[:]}
    }
    
    public init(rules: () -> [String: Any]) {
        tags = [:]
        mods = [:]
        ruleSet = [:]
        
        let rules = rules()
        
        rules.forEach { rule, value in
            add(rule: rule, definition: value)
        }
        
        analyzeRuleBook()
        
        info("tracery ready")
    }
    
    // add a rule and its definition to
    // the mapping table
    // errors if any are returned
    func add(rule: String, definition value: Any) {
        
        // validate the rule name
        let tokens = Lexer.tokens(input: rule)
        guard tokens.count == 1, case let .text(name) = tokens[0] else {
            error("rule '\(rule)' ignored - names must be plaintext")
            return
        }
        if name.contains("#") || name.contains("[") {
            error("rule '\(rule)' ignored - names cannot contain # or [")
            return
        }
        
        if ruleSet[rule] != nil {
            warn("duplicate rule '\(rule)', using latest definition")
        }
        
        let values: [String]
        
        if let provider = value as? RuleCandidatesProvider {
            values = provider.candidates
        }
        else if let string = value as? String {
            values = [string]
        }
        else if let array = value as? [String] {
            values = array
        }
        else if let array = value as? Array<CustomStringConvertible> {
            values = array.map { $0.description }
        }
        else {
            values = ["\(value)"]
        }
        
        let candidates = values.flatMap { createRuleCandidate(rule: rule, text: $0) }
        if candidates.count == 0 {
            warn("rule '\(rule)' does not have any defnitions, will be ignored")
            return
        }
        
        let selector: RuleCandidateSelector
        if let s = value as? RuleCandidateSelector {
            selector = s
        }
        else if candidates.count == 1 {
            selector = PickFirstContentSelector.shared
        }
        else {
            selector = DefaultContentSelector(candidates.count)
        }
        
        ruleSet[rule] = RuleMapping(candidates: candidates, selector: selector)
    }
    
    private func createRuleCandidate(rule:String, text: String) -> RuleCandidate? {
        let e = error
        do {
            info("checking rule '\(rule)' - \(text)")
            return RuleCandidate(text: text, nodes: try Parser.gen(tokens: Lexer.tokens(input: text)))
        }
        catch {
            e("rule '\(rule)' parse error - \(error) in definition - \(text)")
            return nil
        }
    }
    
    public func add(modifier: String, transform: @escaping (String)->String) {
        if mods[modifier] != nil {
            warn("overwriting modifier '\(modifier)'")
        }
        mods[modifier] = { input, _ in
            return transform(input)
        }
    }
    
    public func add(call: String, transform: @escaping () -> ()) {
        if mods[call] != nil {
            warn("overwriting call '\(call)'")
        }
        mods[call] = { input, _ in
            transform()
            return input
        }
    }
    
    public func add(method: String, transform: @escaping (String, [String])->String) {
        if mods[method] != nil {
            warn("overwriting method '\(method)'")
        }
        mods[method] = transform
    }
    
    public func setCandidateSelector(rule: String, selector: RuleCandidateSelector) {
        guard ruleSet[rule] != nil else {
            warn("rule '\(rule)' not found to set selector")
            return
        }
        ruleSet[rule]?.selector = selector
    }
    
    
    
    public func expand(_ input: String, resetTags: Bool = true) -> String {
        do {
            if resetTags {
                stackDepth = 0
                tags.removeAll()
            }
            return try eval(input)
        }
        catch {
            return "error: \(error)"
        }
    }
    
    public static var maxStackDepth = 256
    
    private(set) var stackDepth: Int = 0
    
    private func incrementStackDepth() throws {
        stackDepth += 1
        info("stack depth: \(stackDepth)")
        if stackDepth > Tracery.maxStackDepth {
            error("stack overflow")
            throw ParserError.error("stack overflow")
        }
    }
    
    private func decrementStackDepth() {
        info("stack depth: \(stackDepth-1)")
        stackDepth = max(stackDepth - 1, 0)
    }
    
    
    // evaluates formatted text and returns a string
    private func eval(_ text: String) throws -> String {
        
        trace("📘 eval text '\(text)'")
        
        let tokens = Lexer.tokens(input: text)
        // print_trace("📘 tokens => " + tokens.map { $0.description }.joined(separator: " "))
        
        let nodes = try Parser.gen(tokens: tokens)
        // print_trace("nodes", "=>", nodes)
        
        let result = try eval(nodes)
        
        trace("📘 \(text) ==> \(result)")
        
        return result
    }
    
    private func eval(_ nodes: [ParserNode]) throws -> String {
        var result = ""
        for node in nodes {
            result.append(try eval(node))
        }
        return result
    }
    
    private func eval(_ node: ParserNode) throws -> String {
        
        try incrementStackDepth(); defer { decrementStackDepth() }
        
        let result: String
        switch node {
            
        case let .text(text):
            trace("📘 text (\(text))")
            result = text
            
        case let .rule(name: name, mods: mods):
            // if the rule name is an empty string
            // see if we need to run any generators
            if name.isEmpty {
                result = try apply(mods: mods, to: "")
                break
            }
            
            // check if we have an entry in the symbol table
            // if present, apply the mods and return
            if let symbol = getSymbolMapping(tag: name) {
                result = try apply(mods: mods,to: symbol)
                trace("📗 tag[\(name)] = \(result)")
                break
            }
            
            trace("📘 eval \(node)")
            if let mapping = getRuleMapping(rule: name) {
                trace("📙 rule #\(name)# = \(mapping.text)")
                let choice = try eval(mapping.nodes)
                result = try apply(mods: mods, to: choice)
            }
            else {
                warn("rule #\(name)# cannot be expanded")
                result = "#\(name)#"
            }
            
        case let .tag(name: name, values: values):
            let candidates = try values.map { try eval($0.nodes) }
            tags[name] = TagMapping(
                candidates: candidates,
                selector: candidates.count < 2 ? PickFirstContentSelector.shared : DefaultContentSelector(candidates.count)
            )
            result = ""
            trace("📗 create tag '\(name)' with \(tags[name]!.candidates.joined(separator: ", "))")
            
        }
        
        return result
    }
    
    private func getSymbolMapping(tag: String) -> String? {
        guard let mapping = tags[tag] else { return nil }
        let i = mapping.selector.pick(count: mapping.candidates.count)
        return mapping.candidates[i]
    }
    
    private func getRuleMapping(rule: String) -> RuleCandidate? {
        guard let mapping = ruleSet[rule] else { return nil }
        let i = mapping.selector.pick(count: mapping.candidates.count)
        guard i < mapping.candidates.count, i >= 0 else { return nil }
        return mapping.candidates[i]
    }
    
    private func apply(mods: [Modifier], to input: String) throws -> String {
        if mods.count == 0 {
            return input
        }
        var accum = input
        for mod in mods {
            guard let invoke = self.mods[mod.name] else {
                warn("modifier '\(mod.name)' not defined")
                continue
            }
            let params = try mod.parameters.map { param -> String in
                if param.rawText.range(of: "#") != nil {
                    return try eval(param.nodes)
                }
                return param.rawText
            }
            trace("🔰 run mod \(mod.name)(\(accum) params: \(params.joined(separator: ",")))")
            accum = invoke(accum, params)
        }
        return accum
    }
    
}




