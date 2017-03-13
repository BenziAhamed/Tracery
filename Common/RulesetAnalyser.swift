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
        
        guard options.isRuleAnalysisEnabled else { return }
        
        info("analying rules")
        
        var analyzers = [RulesetAnalyser]()
        
        analyzers.append(CyclicReferenceIdentifier())
        analyzers.append(RuleSelfReferenceIdentifer())
        if options.tagStorageType == .unilevel {
            analyzers.append(UnilevelStorageTagOverrideRuleIndentifer())
        }
        analyzers.append(EmptyRulesetDetector())
        
        ruleSet.forEach { rule, mapping in
            analyzers.forEach { analyzer in
                analyzer.visit(rule: rule, mapping: mapping)
            }
        }
        analyzers.forEach { $0.end() }
    }
    
}
