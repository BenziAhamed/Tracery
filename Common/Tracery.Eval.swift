//
//  Tracery.Eval.swift
//  Tracery
//
//  Created by Benzi on 14/03/17.
//  Copyright © 2017 Benzi Ahamed. All rights reserved.
//

import Foundation


extension Tracery {
    
    // transforms input text to expanded text
    // based on the rule set, run time tags, and modifiers
    func eval(_ text: String) throws -> String {
        trace("📘 input \(text)")
        
        // let nodes = try Parser.gen(Lexer.tokens(text))
        let nodes = try Parser.gen2(Lexer.tokens(text))
        
        let output = try eval(nodes)
        
        trace("📘 output \(text) ==> \(output)")
        return output
    }
    
    func eval(_ nodes: [ParserNode]) throws -> String {
        
        // the execution stack
        // var stack = [ExecutionContext]()
        contextStack.reset()
        
        // push a new execution context
        // onto the stack
        func pushContext(_ nodes: [ParserNode], _ popAction: ExecutionContext.PopAction = .appendToResult, affectsEvaluationLevel: Bool = true) throws {
            if affectsEvaluationLevel {
                try incrementEvaluationLevel()
            }
            // if we are logically increasing the stack size
            if contextStack.top > Tracery.maxStackDepth {
                throw ParserError.error("stack overflow")
            }

            contextStack.push(nodes, popAction, affectsEvaluationLevel)
        }
        
        // pop an evaluated context
        // from the stack
        @discardableResult
        func popContext() -> ExecutionContext {
            let context = contextStack.pop()
            if context.affectsEvaluationLevel {
                decrementEvaluationLevel()
            }
            return context
        }
        
        // push initial context which is the
        // set of nodes that are parsed from the input
        try pushContext(nodes, .appendToResult)
        
        while true {
            
            let top = contextStack.top - 1
            
            trace("----------")
            contextStack.contexts.enumerated().forEach { i, context in
                if i <= top {
                    trace("\(i) \(context)")
                }
            }
            
//            do {
//                let i = depth
//                let context = stack[i]
//                trace("\(i) \(context)")
//            }
            
            
            // have we have finished processing
            // the stack?
            if contextStack.executionComplete {
                break
            }
            
            // if we are at the end of evaluating a context
            // pop it and continue
            if contextStack.contexts[top].isEmpty {
                popContext()
                continue
            }
            
            // execute the current node
            let node = contextStack.contexts[top].pop()
            
            switch node {
                
            case .weight:
                break
                
            case let .text(text):
                trace("📘 text (\(text))")
                // commit result to context
                contextStack.contexts[top].result.append(text)
                
            case let .evaluateArg(nodes):
                // special node that evaluates
                // child nodes and adds result
                // in parent context's args list
                try pushContext(nodes, .addArg)
                
            case .clearArgs:
                contextStack.contexts[top].args.removeAll()
                
            case let .any(values, selector):
                let choice = values[selector.pick(count: values.count)]
                try pushContext(choice.nodes, affectsEvaluationLevel: false)
                
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
                nodes.append(.createTag(name: name, selector: values.selector()))
                
                // creating a tag should not
                // affect the stack depth, since hierarchical tags
                // must be created at the same rule context level
                try pushContext(nodes, .nothing, affectsEvaluationLevel: false)
                
                
            case let .createTag(name, selector):
                
                let context = contextStack.contexts[top]
                
                // context.args will have the accumulated
                // values if the current context
                let mapping = TagMapping(candidates: context.args, selector: selector)
                
                if let existing = tagStorage.get(name: name) {
                    trace("📗 ⚠️ overwriting tag[\(name) \(existing.description)]")
                }
                tagStorage.store(name: name, tag: mapping)
                trace("📗 set tag[\(name)] <-- \(mapping.description)")
                
            case let .ifBlock(condition, thenBlock, elseBlock):
                trace("🕎 ⤵️ \(node)")
                var nodes = expandCondition(condition)
                nodes.append(.branch(check: condition.op, thenBlock: thenBlock, elseBlock: elseBlock))
                try pushContext(nodes, affectsEvaluationLevel: false)
                
                
            case let .whileBlock(condition, doBlock):
                trace("🕎 🔁 \(node)")
                var nodes = expandCondition(condition)
                nodes.append(
                    .branch(
                        check: condition.op,
                        thenBlock: doBlock + [node], // the while block again
                        elseBlock: nil
                    )
                )
                try pushContext(nodes, affectsEvaluationLevel: false)
                
                
            case let .branch(check, thenBlock, elseBlock):
                let conditionMet: Bool
                
                checking: switch check {
                case .equalTo:
                    conditionMet = (contextStack.contexts[top].args[0] == contextStack.contexts[top].args[1])
                case .notEqualTo:
                    conditionMet = (contextStack.contexts[top].args[0] != contextStack.contexts[top].args[1])
                case .valueIn:
                    for i in 1..<contextStack.contexts[top].args.count {
                        let toCheckIfContained = contextStack.contexts[top].args[0]
                        if toCheckIfContained == contextStack.contexts[top].args[i] {
                            conditionMet = true
                            break checking
                        }
                    }
                    conditionMet = false
                case .valueNotIn:
                    for i in 1..<contextStack.contexts[top].args.count {
                        let toCheckIfContained = contextStack.contexts[top].args[0]
                        if toCheckIfContained == contextStack.contexts[top].args[i] {
                            conditionMet = false
                            break checking
                        }
                    }
                    conditionMet = true
                }
                
                if conditionMet {
                    trace("🕎 ✅ branch to then")
                    try pushContext(thenBlock, affectsEvaluationLevel: false)
                }
                else {
                    trace("🕎 🅾️ condition failed")
                    if let elseBlock = elseBlock {
                        trace("🕎 ✅ branch to else")
                        try pushContext(elseBlock, affectsEvaluationLevel: false)
                    }
                }
                
                
                
            case let .runMod(name):
                guard let mod = mods[name] else { break }
                let context = contextStack.contexts[top]
                trace("🔰 run mod \(name)(\(context.result) params: \(context.args.joined(separator: ",")))")
                contextStack.contexts[top].result = mod(context.result, context.args)
                
              
            case let .createRule(name, values):
                let mapping = RuleMapping(
                    candidates: values.map { RuleCandidate.init(text: "", value: $0) },
                    selector: values.selector()
                )
                if runTimeRuleSet[name] != nil {
                    warn("overwriting rule '\(name)'")
                }
                else {
                    trace("⚙️ added rule '\(name)'")
                }
                runTimeRuleSet[name] = mapping
                
                
                
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
                
                enum ExpansionState {
                    case apply([ParserNode])
                    case noExpansion(reason: String)
                }

                var state: ExpansionState = .noExpansion(reason: "not defined")
                
                func selectCandidate(_ mapping: RuleMapping, runTime: Bool) {
                    guard let candidate = mapping.select() else {
                        state = .noExpansion(reason: "no candidates found")
                        return
                    }
                    state = .apply(candidate.value.nodes)
                    trace("📙 eval \(runTime ? "runtime" : "") \(node)")
                }
                
                if name.isEmpty {
                    state = .apply([.text("")])
                }
                else if let mapping = tagStorage.get(name: name) {
                    let i = mapping.selector.pick(count: mapping.candidates.count)
                    let value = mapping.candidates[i]
                    trace("📗 get tag[\(name)] --> \(value)")
                    state = .apply([.text(value)])
                }
                else if let object = objects[name] {
                    let value = "\(object)"
                    trace("📘 eval object \(value)")
                    state = .apply([.text(value)])
                }
                else if let mapping = runTimeRuleSet[name] {
                    selectCandidate(mapping, runTime: true)
                }
                else if let mapping = ruleSet[name] {
                    selectCandidate(mapping, runTime: false)
                }
                
                switch state {
                case .apply(let nodes):
                    try applyMods(nodes: nodes)
                case .noExpansion(let reason):
                    warn("rule #\(name)# expansion failed - \(reason)")
                    contextStack.contexts[top].result.append("#\(name)#")
                }
            }
        }
        
        // finally pop the last
        // context and
        return popContext().result
        
    }
    
    
    // a condition is of the form 
    // lhs op rhs
    // of op is 'in' keyword, the rhs needs to be evaluated by expanding *all* its candidates
    // else rhs will be evaluated as a rule
    func expandCondition(_ condition: ParserCondition) -> [ParserNode] {
        var nodes = [ParserNode]()
        nodes.append(.evaluateArg(nodes: condition.lhs))
        
        // support 'in'/'not in' keyword in condition mapping
        // if we have an rhs of a rule form #rule#
        // we will add in *all* candidates of that rule to args list
        // if rule maps to a tag, then all candidate tag values are added to the rule
        // list
        if condition.op == .valueIn || condition.op == .valueNotIn,
            condition.rhs.count == 1,
            case let .rule(name, _) = condition.rhs[0] {
            if let tag = tagStorage.get(name: name) {
                for value in tag.candidates {
                    nodes.append(.evaluateArg(nodes: [.text(value)]))
                }
                return nodes
            }
            if let mapping = ruleSet[name] {
                for candidate in mapping.candidates {
                    nodes.append(.evaluateArg(nodes: candidate.value.nodes))
                }
                return nodes
            }
        }
        
        
        nodes.append(.evaluateArg(nodes: condition.rhs))
        return nodes
    }
}


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
    var popAction: PopAction
    
    // does this context affect the
    // stack depth? - required for setting tags
    // using hierarchical storage
    var affectsEvaluationLevel: Bool
    
    init(_ nodes: [ParserNode], _ popAction: PopAction, _ affectsEvaluationLevel: Bool) {
        // store in reversed order
        // to allow stack operation
        self.nodes = nodes.reversed()
        self.result = ""
        self.args = []
        self.popAction = popAction
        self.affectsEvaluationLevel = affectsEvaluationLevel
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


extension ExecutionContext : CustomStringConvertible {
    var description: String {
        return "\(nodes) \(popAction) args\(args) result:\(result)"
    }
}



// object pool like context stack
// that can be reused as often as needed
struct ContextStack {
    
    var contexts: [ExecutionContext]
    var top: Int

    init() {
        contexts = [ExecutionContext].init(repeating: ExecutionContext.init([], .nothing, false), count: 32)
        top = 0
    }
    
    mutating func reset() {
        top = 0
    }
    
    var executionComplete: Bool {
        return top == 0 && contexts[0].isEmpty
    }
    
    mutating func push(_ nodes: [ParserNode], _ popAction: ExecutionContext.PopAction = .appendToResult, _ affectsEvaluationLevel: Bool = false) {
        
        if top == contexts.count {
            trace("⚙️ context stack size increased to \(contexts.count * 2)")
            contexts = contexts + [ExecutionContext].init(repeating: ExecutionContext.init([], .nothing, false), count: contexts.count)
        }
        
        contexts[top].nodes = nodes.reversed()
        if !contexts[top].args.isEmpty {
            contexts[top].args.removeAll()
        }
        contexts[top].affectsEvaluationLevel = affectsEvaluationLevel
        contexts[top].popAction = popAction
        contexts[top].result = ""
        
        top += 1
    }
    
    mutating func pop() -> ExecutionContext {
        
        if top == 0 {
            return contexts[0]
        }
        
        let context = contexts[top-1]
        top -= 1
        
        guard top > 0 else { return context }
        
        switch context.popAction {
        case .appendToResult:
            contexts[top-1].result.append(context.result)
        case .addArg:
            contexts[top-1].args.append(context.result)
        case .nothing:
            break
        }
        
        return context
    }
    
    
    
}



