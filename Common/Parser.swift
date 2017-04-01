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
    var parameters: [ValueCandidate]
    
    var description: String {
        return ".\(name)(\(parameters.map { $0.description }.joined(separator: ", ")))"
    }
}

protocol ValueCandidateProtocol {
    var nodes: [ParserNode] { get }
    var hasWeight: Bool { get }
    var weight: Int { get }
}

struct ValueCandidate: ValueCandidateProtocol, CustomStringConvertible {
    var nodes: [ParserNode]
    var hasWeight: Bool {
        if let last = nodes.last, case .weight = last { return true }
        return false
    }
    var weight: Int {
        if let last = nodes.last, case let .weight(value) = last { return value }
        return 1
    }
    var description: String {
        return "<" + nodes.map { "\($0)" }.joined(separator: ",") + ">"
    }
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
    case any(values:[ValueCandidate], selector:RuleCandidateSelector, mods:[Modifier])
    case tag(name:String, values:[ValueCandidate])
    case weight(value: Int)
    case createRule(name:String, values:[ValueCandidate])
    
    // control flow
    
    indirect case ifBlock(condition:ParserCondition, thenBlock:[ParserNode], elseBlock:[ParserNode]?)
    indirect case whileBlock(condition:ParserCondition, doBlock:[ParserNode])

    // procedures
    
    case runMod(name: String)
    case createTag(name: String, selector: RuleCandidateSelector)
    
    // args handling
    
    indirect case evaluateArg(nodes: [ParserNode])
    case clearArgs
    
    // low level flow control
    
    indirect case branch(check:ParserConditionOperator, thenBlock:[ParserNode], elseBlock:[ParserNode]?)
    
    public var description: String {
        switch self {
            
        case let .rule(name, mods):
            if mods.count > 0 {
                let mods = mods.reduce("") { $0.0 + $0.1.description }
                return "RULE_\(name)_\(mods))"
            }
            return "RULE_\(name)"

        case let .createRule(name, values):
            if values.count == 1 { return "NEW_RULE(\(name)=\(values[0]))" }
            return "+RULE_\(name)=\(values)"
            
        case let .tag(name, values):
            if values.count == 1 { return "TAG(\(name)=\(values[0]))" }
            return "TAG_\(name)=\(values)"
            
        case let .text(text):
            return "TXT_\(text)"
            
        case let .any(values, _, mods):
            if mods.count > 0 {
                return "ANY\(values)+\(mods)"
            }
            return "ANY\(values)"
            
        case let .weight(value):
            return "WEIGHT_\(value)"
            
        case let .runMod(name):
            return "RUN_MOD_\(name)"
            
        case let .createTag(name, _):
            return "+TAG_\(name)"
            
        case let .evaluateArg(nodes):
            return "EVAL_ARG<\(nodes)>"
            
        case .clearArgs:
            return "CLR_ARGS"
            
        case let .ifBlock(condition, thenBlock, elseBlock):
            if let elseBlock = elseBlock {
                return "IF(\(condition) THEN \(thenBlock) ELSE \(elseBlock))"
            }
            return "IF(\(condition) THEN \(thenBlock))"
            
            
        case let .branch(check, thenBlock, elseBlock):
            if let elseBlock = elseBlock {
                return "JUMP(args \(check) THEN \(thenBlock) ELSE \(elseBlock))"
            }
            return "JUMP(args \(check) THEN \(thenBlock))"
            
        case let .whileBlock(condition, doBlock):
            return "WHILE(\(condition) THEN \(doBlock))"

        }
    }
}



enum ParserError : Error, CustomStringConvertible {
    case error(String)
    var description: String {
        switch self {
        case let .error(msg): return msg
        }
    }
}



struct Parser { }

extension Array where Element: ValueCandidateProtocol {
    func selector() -> RuleCandidateSelector {
        if count < 2 {
            return PickFirstContentSelector.shared
        }
        func hasWeights() -> Bool {
            for i in self {
                if i.hasWeight { return true }
            }
            return false
        }
        if hasWeights() {
            var weights = [Int]()
            for i in self {
                weights.append(i.weight)
            }
            return WeightedSelector(weights)
        }
        return DefaultContentSelector(count)
    }
}
