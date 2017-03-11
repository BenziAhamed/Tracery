//
//  TagOverrideRuleIdentifier.swift
//  Tracery
//
//  Created by Benzi on 10/03/17.
//  Copyright © 2017 Benzi Ahamed. All rights reserved.
//

import Foundation

class TagOverrideRuleIndentifer : RulesetAnalyser {
    var allRules = [String]()
    var mappings = [(rule:String, mapping:RuleMapping)]()
    
    func visit(rule: String, mapping: RuleMapping) {
        allRules.append(rule)
        mappings.append((rule, mapping))
    }
    func end() {
        mappings.forEach { entry in
            entry.mapping.candidates.forEach { candidate in
                candidate.nodes.forEach { node in
                    if case let .tag(name, _) = node, allRules.contains(name) {
                        print("⚠️ tag override in rule '\(entry.rule)', creating tag '\(name)' overrides pre-defined rule '\(name)'")
                    }
                }
            }
        }
    }
}

