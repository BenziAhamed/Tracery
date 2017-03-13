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


public class TraceryOptions {
    public var tagStorageType = TaggingPolicy.unilevel
    public var isRuleAnalysisEnabled = true
    
    public init() { }
}

extension TraceryOptions {
    static let defaultSet = TraceryOptions()
}

public class Tracery {
    
    private(set) var ruleSet: [String: RuleMapping]
    private(set) var mods: [String: (String,[String])->String]
    private(set) var tagStorage: TagStorage
    
    public var ruleNames: [String] { return ruleSet.keys.map { $0 } }
    
    convenience public init() {
        self.init {[:]}
    }
    
    let options: TraceryOptions
    
    public init(_ options: TraceryOptions = TraceryOptions.defaultSet, rules: () -> [String: Any]) {
        self.options = options
        mods = [:]
        ruleSet = [:]
        tagStorage = options.tagStorageType.storage()
        tagStorage.tracery = self
        
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
            warn("rule '\(rule)' does not have any definitions, will be ignored")
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
                tagStorage.removeAll()
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
        trace("⚙️ depth: \(stackDepth)")
        if stackDepth > Tracery.maxStackDepth {
            error("stack overflow")
            throw ParserError.error("stack overflow")
        }
    }
    
    private func decrementStackDepth() {
        stackDepth = max(stackDepth - 1, 0)
        trace("⚙️ depth: \(stackDepth)")
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
        
        trace("⚙️ eval \(node)")
        
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
            if let symbol = getTagMapping(tag: name) {
                result = try apply(mods: mods,to: symbol)
                traceTag("📗 get tag[\(name)] = \(result)")
                break
            }
            
            // we need to increment stack depth
            // only when evaluating a rule
            // and after this point
            // getting a tag should be at the same
            // level as storing it
            //
            // we do not want a "[tag:value]#tag#"
            // to increase the level to n+1 when setting the tag
            // and then decreasing it after its done;
            // this will prevent #tag# evaluation at level n
            // to fail because a tag will not be present
            // at level n
            //
            try incrementStackDepth(); defer { decrementStackDepth() }

            
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
            
        case let .tag(name, values):
            
            // evaluate individual candidates
            let candidates = try values.map { try eval($0.nodes) }
            // create a tag mapping
            let mapping = TagMapping(
                candidates: candidates,
                selector: candidates.count < 2 ? PickFirstContentSelector.shared : DefaultContentSelector(candidates.count)
            )
            if let existing = tagStorage.get(name: name) {
                traceTag("📗 ⚠️ overwriting tag[\(name)] = \(existing.description)")
            }
            tagStorage.store(name: name, tag: mapping)
            traceTag("📗 set tag[\(name)] = \(mapping.description)")
            result = ""
            
        }
        
        return result
    }
    
    
    
    private func getTagMapping(tag: String) -> String? {
        guard let mapping = tagStorage.get(name: tag) else {
            return nil
        }
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


extension Tracery {
    
    func traceTag(_ message: @autoclosure ()->String) {
        switch options.tagStorageType {
        case .unilevel: trace(message)
        case .heirarchical: trace("\(message()) depth:\(stackDepth)")
        }
    }
    
}




