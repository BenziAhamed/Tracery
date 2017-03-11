//
//  EmptyRulesetDetector.swift
//  Tracery
//
//  Created by Benzi on 10/03/17.
//  Copyright © 2017 Benzi Ahamed. All rights reserved.
//

import Foundation

class EmptyRulesetDetector : RulesetAnalyser {
    var count = 0
    func visit(rule: String, mapping: RuleMapping) {
        count += 1
    }
    func end() {
        guard count == 0 else { return }
        warn("no expandable rules were found")
    }
}
