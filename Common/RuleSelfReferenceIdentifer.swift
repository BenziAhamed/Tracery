//
//  RuleSelfReferenceIdentifer.swift
//  Tracery
//
//  Created by Benzi on 10/03/17.
//  Copyright © 2017 Benzi Ahamed. All rights reserved.
//

import Foundation

class RuleSelfReferenceIdentifer : RulesetAnalyser {
    
    var selfReferences = [(rule: String, definition: String)]()
    
    func visit(rule: String, mapping: RuleMapping) {
        for candidate in mapping.candidates where candidate.text.contains("#\(rule)#") {
            selfReferences.append((rule, candidate.text))
        }
    }
    
    func end() {
        let count = selfReferences.count
        guard count > 0 else { return }
        let text = count == 1 ? "rule" : "rules"
        warn("\(selfReferences.count) self referencing \(text) found")
        selfReferences.forEach {
            warn("      '\($0.rule)' - \($0.definition)")
        }
    }
    
}
