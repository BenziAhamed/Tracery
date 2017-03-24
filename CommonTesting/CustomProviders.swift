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
    let weights: [Int]
    let sum: UInt32
    
    init(_ distribution:[String:Int]) {
        distribution.map { $0.value }.forEach {
            assert($0 > 0, "weights must be positive")
        }
        candidates = distribution.map { $0.key }
        weights = distribution.map { $0.value }
        sum = UInt32(weights.reduce(0, +))
    }
    
    func pick(count: Int) -> Int {
        var choice = Int(arc4random_uniform(sum))
        var index = 0
        for weight in weights {
            choice = choice - weight
            if choice < 0 {
                return index
            }
            index += 1
        }
        fatalError()
    }
}
