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
        
        let nodes = try Parser.gen(Lexer.tokens(text))
        let output = try eval(nodes)
        
        trace("📘 ouptut \(text) ==> \(output)")
        return output
    }
    
    func eval(_ nodes: [ParserNode]) throws -> String {
        
        // the execution stack
        var stack = [ExecutionContext]()
        
        // push a new execution context
        // onto the stack
        func pushContext(_ nodes: [ParserNode], _ popAction: ExecutionContext.PopAction = .appendToResult, affectsEvaluationLevel: Bool = true) throws {
            if affectsEvaluationLevel {
                try incrementEvaluationLevel()
            }
            // if we are logically increasing the stack size
            if stack.count > Tracery.maxStackDepth {
                throw ParserError.error("stack overflow")
            }
            stack.append(ExecutionContext(nodes, popAction, affectsEvaluationLevel))
        }
        
        // pop an evaluated context
        // from the stack
        @discardableResult
        func popContext() -> ExecutionContext {
            
            let context = stack.removeLast()
            if context.affectsEvaluationLevel {
                decrementEvaluationLevel()
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
            
//            trace("----------")
//            stack.enumerated().forEach { i, context in
//                trace("\(i) \(context)")
//            }
            
//            do {
//                let i = depth
//                let context = stack[i]
//                trace("\(i) \(context)")
//            }
            
            
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
                try pushContext(nodes, .nothing, affectsEvaluationLevel: false)
                
                
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
                        thenBlock: doBlock + [.whileBlock(condition: condition, doBlock: doBlock)],
                        elseBlock: nil
                    )
                )
                try pushContext(nodes, affectsEvaluationLevel: false)
                
                
            case let .branch(check, thenBlock, elseBlock):
                let conditionMet: Bool
                
                checking: switch check {
                case .equalTo:
                    conditionMet = (stack[depth].args[0] == stack[depth].args[1])
                case .notEqualTo:
                    conditionMet = (stack[depth].args[0] != stack[depth].args[1])
                case .valueIn:
                    for i in 1..<stack[depth].args.count {
                        let toCheckIfContained = stack[depth].args[0]
                        if toCheckIfContained == stack[depth].args[i] {
                            conditionMet = true
                            break checking
                        }
                    }
                    conditionMet = false
                case .valueNotIn:
                    for i in 1..<stack[depth].args.count {
                        let toCheckIfContained = stack[depth].args[0]
                        if toCheckIfContained == stack[depth].args[i] {
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
                if let mapping = ruleSet[name] {
                    if let candidate = mapping.select() {
                        trace("📙 eval \(node)")
                        try applyMods(nodes: candidate.nodes)
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
                    nodes.append(.evaluateArg(nodes: candidate.nodes))
                }
                return nodes
            }
        }
        
        
        nodes.append(.evaluateArg(nodes: condition.rhs))
        return nodes
    }
}


fileprivate struct ExecutionContext {
    
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
    let affectsEvaluationLevel: Bool
    
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
