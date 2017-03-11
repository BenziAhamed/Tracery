//
//  RulesetAnalyser.swift
//  Tracery
//
//  Created by Benzi on 10/03/17.
//  Copyright © 2017 Benzi Ahamed. All rights reserved.
//

import Foundation

protocol RulesetAnalyser {
    func visit(rule: String, mapping: RuleMapping)
    func end()
}


extension Tracery {
    
    func analyzeRuleBook() {
        
        info("analying rules")
        
        var analyzers = [RulesetAnalyser]()
        
        analyzers.append(CyclicReferenceIdentifier())
        analyzers.append(RuleSelfReferenceIdentifer())
        analyzers.append(TagOverrideRuleIndentifer())
        analyzers.append(EmptyRulesetDetector())
        
        ruleSet.forEach { rule, mapping in
            analyzers.forEach { analyzer in
                analyzer.visit(rule: rule, mapping: mapping)
            }
        }
        analyzers.forEach { $0.end() }
    }
    
}
