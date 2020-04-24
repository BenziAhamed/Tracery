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
    
    func select() -> RuleCandidate? {
        let index = selector.pick(count: candidates.count)
        guard index >= 0 && index < candidates.count else { return nil }
        return candidates[index]
    }
}

struct RuleCandidate {
    let text: String
    var value: ValueCandidate
}


public class TraceryOptions {
    public var tagStorageType = TaggingPolicy.unilevel
    public var isRuleAnalysisEnabled = true
    public var logLevel = Tracery.LoggingLevel.errors
    
    public init() { }
}

extension TraceryOptions {
    public static let defaultSet = TraceryOptions()
}

public class Tracery {
    
    var objects = [String: Any]()
    var ruleSet: [String: RuleMapping]
    var runTimeRuleSet = [String: RuleMapping]()
    var mods: [String: (String,[String])->String]
    var tagStorage: TagStorage
    var contextStack: ContextStack
    
    
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
        contextStack = ContextStack()
        tagStorage.tracery = self
        
        let rules = rules()
        
        rules.forEach { rule, value in
            add(rule: rule, definition: value)
        }
        
        analyzeRuleBook()
        
        info("tracery ready")
    }
    
    func createRuleCandidate(rule:String, text: String) -> RuleCandidate? {
        let e = error
        do {
            info("checking rule '\(rule)' - \(text)")
            return RuleCandidate(
                text: text,
                value: ValueCandidate(nodes: try Parser.gen2(Lexer.tokens(text)))
            )
        }
        catch {
            e("rule '\(rule)' parse error - \(error)")
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
    
    public func expand(_ input: String, maintainContext: Bool = false) -> String {
        do {
            if !maintainContext {
                ruleEvaluationLevel = 0
                runTimeRuleSet.removeAll()
                tagStorage.removeAll()
            }
            return try eval(input)
        }
        catch {
            return "error: \(error)"
        }
    }
    
    public static var maxStackDepth = 256
    
    fileprivate(set) var ruleEvaluationLevel: Int = 0
    
    func incrementEvaluationLevel() throws {
        ruleEvaluationLevel += 1
        // trace("⚙️ depth: \(ruleEvaluationLevel)")
        if ruleEvaluationLevel > Tracery.maxStackDepth {
            error("stack overflow")
            throw ParserError.error("stack overflow")
        }
    }
    
    func decrementEvaluationLevel() {
        ruleEvaluationLevel = max(ruleEvaluationLevel - 1, 0)
        // trace("⚙️ depth: \(ruleEvaluationLevel)")
    }
}



// MARK: Rule management
extension Tracery {
    // add a rule and its definition to
    // the mapping table
    // errors if any are returned
    public func add(rule: String, definition value: Any) {
        
        // validate the rule name
        let tokens = Lexer.tokens(rule)
        guard tokens.count == 1, case .text = tokens[0] else {
            error("rule '\(rule)' ignored - names must be plaintext")
            return
        }
        if ruleSet[rule] != nil {
            warn("rule '\(rule)' will be re-written")
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
        
        let candidates = values.compactMap { createRuleCandidate(rule: rule, text: $0) }
        if candidates.count == 0 {
            warn("rule '\(rule)' ignored - no expansion candidates found")
            return
        }
        
        let selector: RuleCandidateSelector
        if let s = value as? RuleCandidateSelector {
            selector = s
        }
        else {
            selector = candidates.map { $0.value }.selector()
        }
        
        ruleSet[rule] = RuleMapping(candidates: candidates, selector: selector)
    }
    
    // Removes a rule
    public func remove(rule: String) {
        ruleSet[rule] = nil
    }
}

// MARK: object management
extension Tracery {

    public func add(object: Any, named name: String) {
        objects[name] = object
    }
    
    public func remove(object name: String) {
        objects[name] = nil
    }
    
    public func configuredObjects() -> [String: Any] {
        return objects
    }
    
}

