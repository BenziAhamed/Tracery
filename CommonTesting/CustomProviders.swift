//
//  CustomProviders.swift
//  Tracery
//
//  Created by Benzi on 11/03/17.
//  Copyright © 2017 Benzi Ahamed. All rights reserved.
//

import Foundation
import Tracery


class WeightedCandidateSet : RuleCandidatesProvider, RuleCandidateSelector {
    
    let candidates: [String]
    let runningWeights: [(total:Int, target:Int)]
    let totalWeights: UInt32
    
    init(_ distribution:[String:Int]) {
        distribution.values.map { $0 }.forEach {
            assert($0 > 0, "weights must be positive")
        }
        let weightedCandidates = distribution
            .map { ($0, $1) }
        candidates = weightedCandidates
            .map { $0.0 }
        runningWeights = weightedCandidates
            .map { $0.1 }
            .scan(0, +)
            .enumerated()
            .map { ($0.element, $0.offset) }
        totalWeights = distribution
            .values
            .map { $0 }
            .reduce(0) { $0.0 + UInt32($0.1) }
    }
    
    func pick(count: Int) -> Int {
        let choice = Int(arc4random_uniform(totalWeights) + 1) // since running weight start at 1
        for weight in runningWeights {
            if choice <= weight.total {
                return weight.target
            }
        }
        fatalError("unable to select target for choice:\(choice) weights:\(runningWeights) candidates:\(candidates)")
    }
    
}
