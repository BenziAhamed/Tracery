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
            return try eval(input)
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
    
    struct ExecutionContext {
        
        // Identifies what should happen
        // when this context is removed from
        // the execution stack
        enum PopAction {
            case appendToResult
            case addArg
            case nothing
        }
        
        // The accumulated result of
        // this context, if any
        var result: String
        
        // The args that were created
        // during context evaluation
        var args: [String]
        
        // The nodes stack that represent
        // what needs to be evaluated in this
        // context
        var nodes: [ParserNode]
        
        // what happens after evaluation
        // is complete
        let popAction: PopAction
        
        // does this context affect the 
        // stack depth? - required for setting tags
        // using hierarchical storage
        let affectsStackDepth: Bool
        
        init(_ nodes: [ParserNode], _ popAction: PopAction, _ affectsStackDepth: Bool) {
            // store in reversed order 
            // to allow stack operation
            self.nodes = nodes.reversed()
            self.result = ""
            self.args = []
            self.popAction = popAction
            self.affectsStackDepth = affectsStackDepth
        }
        
        // are there more nodes to process
        var isEmpty: Bool { return nodes.isEmpty }
        
        mutating func pop() -> ParserNode {
            return nodes.removeLast()
        }
        
        mutating func push(token: ParserNode) {
            nodes.append(token)
        }
        
    }

    func eval(_ text: String) throws -> String {
        trace("📘 input \(text)")
        let nodes = try Parser.gen(tokens: Lexer.tokens(input: text))
        let output = try eval(nodes)
        trace("📘 ouptut \(text) ==> \(output)")
        return output
    }
    
    func eval(_ nodes: [ParserNode]) throws -> String {
        
        // the execution stack
        var stack = [ExecutionContext]()
        
        // push a new execution context
        // onto the stack
        func pushContext(_ tokens: [ParserNode], _ popAction: ExecutionContext.PopAction, affectsStackDepth: Bool = true) throws {
            if affectsStackDepth {
                try incrementStackDepth()
            }
            stack.append(ExecutionContext(tokens, popAction, affectsStackDepth))
        }
        
        // pop an evaluated context 
        // from the stack
        @discardableResult
        func popContext() -> ExecutionContext {
            
            let context = stack.removeLast()
            if context.affectsStackDepth {
                decrementStackDepth()
            }
            
            // check if this is the last context
            guard stack.count > 0 else { return context }
            
            switch context.popAction {
            case .appendToResult:
                stack[stack.count-1].result.append(context.result)
            case .addArg:
                stack[stack.count-1].args.append(context.result)
            case .nothing:
                break
            }
            
            return context
        }
        
        // push initial context which is the
        // set of nodes that are parsed from the input
        try pushContext(nodes, .appendToResult)
        
        while true {
            
            let depth = stack.count - 1
            

//            trace("stack-depth: \(stackDepth)")
//            trace("contexts:")

            trace("----------")
            stack.enumerated().forEach { i, context in
                trace("\(i) = \(context.nodes) pop: \(context.popAction) result: \(context.result) args: \(context.args)")
            }
            
            
            // have we have finished processing
            // the stack?
            if depth == 0 && stack[depth].isEmpty {
                break
            }
            
            // if we are at the end of evaluating a context
            // pop it and continue
            if stack[depth].isEmpty {
                popContext()
                continue
            }
            
            // execute the current node
            let node = stack[depth].pop()
            
            switch node {
                
            case let .text(text):
                trace("📘 text (\(text))")
                // commit result to context
                stack[depth].result.append(text)
                
            case let .evaluateArg(nodes):
                // special node that evaluates
                // child nodes and adds result
                // in parent context's args list
                try pushContext(nodes, .addArg)
                
            case .clearArgs:
                stack[depth].args.removeAll()
                

            case let .tag(name, values):
                
                // push a context with
                // [value1, value2, .... valuen, createTag ]
                // in turn, value1 will push another context
                // to expand it's nodes, but the pop
                // action will be to accumulate results in args
                // once all valuex nodes are processed
                // create tag will access the args and create
                // a tag mapping
                
                var nodes = values.map { ParserNode.evaluateArg(nodes: $0.nodes) }
                nodes.append(.createTag(name: name))
                
                // creating a tag should not 
                // affect the stack depth, since hierarchical tags
                // must be created at the same rule context level
                try pushContext(nodes, .nothing, affectsStackDepth: false)
                
                
            case let .createTag(name):
                
                let context = stack[depth]
                
                // context.args will have the accumulated
                // values if the current context
                let mapping = TagMapping(
                    candidates: context.args,
                    selector: context.args.count < 2 ? PickFirstContentSelector.shared : DefaultContentSelector(context.args.count)
                )
                
                if let existing = tagStorage.get(name: name) {
                    trace("📗 ⚠️ overwriting tag[\(name) \(existing.description)]")
                }
                tagStorage.store(name: name, tag: mapping)
                trace("📗 set tag[\(name)] <-- \(mapping.description)")
                
                
                
            case let .ifBlock(condition, thenBlock, elseBlock):
                trace("✂️ \(node)")
                let nodes:[ParserNode] = [
                    .evaluateArg(nodes: [condition.lhs]),
                    .evaluateArg(nodes: [condition.rhs]),
                    .branch(check: condition.op, thenBlock: thenBlock, elseBlock: elseBlock),
                ]
                try pushContext(nodes, .appendToResult, affectsStackDepth: false)
                
            case let .branch(check, thenBlock, elseBlock):
                guard stack[depth].args.count == 2 else {
                    error("branching must be called after evaluating exactly two args")
                    break
                }
                let conditionMet: Bool
                switch check {
                case .equalTo:
                    conditionMet = (stack[depth].args[0] == stack[depth].args[1])
                case .notEqualTo:
                    conditionMet = (stack[depth].args[0] != stack[depth].args[1])
                }
                if conditionMet {
                    trace("✂️ ✅")
                    try pushContext(thenBlock, .appendToResult, affectsStackDepth: false)
                }
                else {
                    trace("✂️ 🅾️")
                    if let elseBlock = elseBlock {
                        try pushContext(elseBlock, .appendToResult, affectsStackDepth: false)
                    }
                }
                
                
                
            case let .runMod(name):
                guard let mod = mods[name] else { break }
                let context = stack[depth]
                trace("🔰 run mod \(name)(\(context.result) params: \(context.args.joined(separator: ",")))")
                stack[depth].result = mod(context.result, context.args)
                
            
            case let .rule(name, mods):
                
                func applyMods(nodes: [ParserNode]) throws {
                    
                    var nodes = nodes
                    
                    for mod in mods {
                        guard self.mods[mod.name] != nil else {
                            warn("modifier '\(mod.name)' not defined")
                            continue
                        }
                        for param in mod.parameters {
                            nodes.append(.evaluateArg(nodes: param.nodes))
                        }
                        nodes.append(.runMod(name: mod.name))
                        nodes.append(.clearArgs)
                    }
                    
                    // at this stage nodes will be
                    // [rule_expansion_nodes, (evalArg_1, ... evalArg_N, runMod, clearArgs)* ]
                    
                    // rule_expansion_nodes evaluate as normal, and updates context.result
                    // evalArgs will update the args list, and runMod will use the args list to run a mod,
                    // replacing the context.result with its computed value
                    // clearArgs empties args list for consequent processing by any chained modifier nodes
                    
                    try pushContext(nodes, .appendToResult)
                }
                
                if name.isEmpty {
                    try applyMods(nodes: [.text("")])
                    break
                }
                if let mapping = tagStorage.get(name: name) {
                    let i = mapping.selector.pick(count: mapping.candidates.count)
                    let value = mapping.candidates[i]
                    trace("📗 get tag[\(name)] --> \(value)")
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
        
        // finally pop the last
        // context and
        return popContext().result
        
    }
}




