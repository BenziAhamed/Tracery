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
    fileprivate(set) var tagStorage: TagStorage
    
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
            // return try eval(input)
            return try evalNonRecursive(input)
        }
        catch {
            return "error: \(error)"
        }
    }
    
    public static var maxStackDepth = 256
    
    fileprivate(set) var stackDepth: Int = 0
    
    fileprivate func incrementStackDepth() throws {
        stackDepth += 1
        trace("⚙️ depth: \(stackDepth)")
        if stackDepth > Tracery.maxStackDepth {
            error("stack overflow")
            throw ParserError.error("stack overflow")
        }
    }
    
    fileprivate func decrementStackDepth() {
        stackDepth = max(stackDepth - 1, 0)
        trace("⚙️ depth: \(stackDepth)")
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


extension Tracery {
    
    struct ExecutionContext {
        var result: String
        var nodes: [ParserNode]
        init(_ nodes: [ParserNode]) {
            self.nodes = nodes.reversed()
            self.result = ""
        }
        var isEmpty: Bool { return nodes.isEmpty }
        mutating func pop() -> ParserNode {
            return nodes.removeLast()
        }
        mutating func push(token: ParserNode) {
            nodes.append(token)
        }
    }

    func evalNonRecursive(_ text: String) throws -> String {
        trace("📘 input \(text)")
        let nodes = try Parser.gen(tokens: Lexer.tokens(input: text))
        let output = try evalNonRecursive(nodes)
        trace("📘 ouptut \(text)")
        return output
    }
    
    func evalNonRecursive(_ nodes: [ParserNode]) throws -> String {
        
        var stack = [ExecutionContext]()
        
        func pushContext(_ tokens: [ParserNode]) throws {
            try incrementStackDepth()
            stack.append(ExecutionContext(tokens))
        }
        
        func popContext() {
            decrementStackDepth()
            let context = stack.removeLast()
            if stack.count > 0 {
                stack[stack.count-1].result.append(context.result)
            }
        }
        
        // push initial context which is the
        // set of nodes that are parsed from the input
        try pushContext(nodes)
        
        while true {
            
            let depth = stack.count - 1
            
            trace("----------")
            trace("stack-depth: \(stackDepth)")
            trace("contexts:")
            stack.enumerated().forEach { i, context in
                trace("\(i)-\(context.nodes) result:\(context.result)")
            }
            
            
            // we have finished all processing
            if depth == 0 && stack[depth].isEmpty {
                break
            }
            
            // if we are at the end of evaluating a context
            // pop it and continue
            if stack[depth].isEmpty {
                popContext()
                continue
            }
            
            let node = stack[depth].pop()
            
            
            
            switch node {
                
            case let .text(text):
                trace("📘 text (\(text))")
                stack[depth].result.append(text)
                
            case let .tag(name, values):
                
                // evaluate individual candidates
                let candidates = try values.map { try evalNonRecursive($0.nodes) }
                // create a tag mapping
                let mapping = TagMapping(
                    candidates: candidates,
                    selector: candidates.count < 2 ? PickFirstContentSelector.shared : DefaultContentSelector(candidates.count)
                )
                if let existing = tagStorage.get(name: name) {
                    traceTag("📗 ⚠️ overwriting tag[\(name) \(existing.description)]")
                }
                tagStorage.store(name: name, tag: mapping)
                traceTag("📗 set tag[\(name)] = \(mapping.description)")
                
                
            case let .mod(modifier):
                
                if let mod = mods[modifier.name] {
                    var args = [String]()
                    for param in modifier.parameters {
                        if param.rawText.range(of: "#") != nil {
                            args.append(try evalNonRecursive(param.nodes))
                        }
                        else {
                            args.append(param.rawText)
                        }
                    }
                    
                    trace("🔰 run mod \(modifier.name)(\(stack[depth].result) params: \(args.joined(separator: ",")))")
                    // update context result
                    stack[depth].result = mod(stack[depth].result, args)
                }
                else {
                    warn("modifier '\(modifier.name)' not defined")
                }
                
                
            case let .rule(name, mods):
                
                func applyMods(nodes: [ParserNode]) throws {
                    var nodes = nodes
                    for mod in mods {
                        nodes.append(.mod(mod))
                    }
                    try pushContext(nodes)
                }
                
                if name.isEmpty {
                    try applyMods(nodes: [.text("")])
                    break
                }
                if let mapping = tagStorage.get(name: name) {
                    let i = mapping.selector.pick(count: mapping.candidates.count)
                    let value = mapping.candidates[i]
                    traceTag("📗 get tag[\(name)] = \(value)")
                    try applyMods(nodes: [.text(value)])
                    break
                }
                if let expansion = ruleSet[name] {
                    let index = expansion.selector.pick(count: expansion.candidates.count)
                    if index >= 0 && index < expansion.candidates.count {
                        trace("📙 eval \(node)")
                        try applyMods(nodes: expansion.candidates[index].nodes)
                    }
                    else {
                        warn("no candidate found for rule #\(name)#")
                        stack[depth].result.append("#\(name)#")
                    }
                }
                else {
                    warn("rule #\(name)# cannot be expanded")
                    stack[depth].result.append("#\(name)#")
                }
            }
        }
        
        let result = stack[0].result
        popContext()
        
        return result
    }
}




