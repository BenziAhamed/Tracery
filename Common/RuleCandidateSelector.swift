//
//  RuleCandidateSelector.swift
//  Tracery
//
//  Created by Benzi on 10/03/17.
//  Copyright © 2017 Benzi Ahamed. All rights reserved.
//

import Foundation

public protocol RuleCandidateSelector {
    func pick(count: Int) -> Int
}


class PickFirstContentSelector : RuleCandidateSelector {
    private init() { }
    static let shared = PickFirstContentSelector()
    func pick(count: Int) -> Int {
        return 0
    }
}


private extension MutableCollection {
    /// Shuffles the contents of this collection.
    mutating func shuffle() {
        let c = count
        guard c > 1 else { return }
        
        for (firstUnshuffled , unshuffledCount) in zip(indices, stride(from: c, to: 1, by: -1)) {
            let d: IndexDistance = numericCast(arc4random_uniform(numericCast(unshuffledCount)))
            guard d != 0 else { continue }
            let i = index(firstUnshuffled, offsetBy: d)
			self.swapAt(firstUnshuffled, i)
        }
    }
}

class DefaultContentSelector : RuleCandidateSelector {
    
    var indices:[Int]
    var index: Int = 0
    
    init(_ count: Int) {
        indices = [Int]()
        for i in 0..<count {
            indices.append(i)
        }
        indices.shuffle()
    }
    
    func pick(count: Int) -> Int {
        assert(indices.count == count)
        if index >= count {
            indices.shuffle()
            index = 0
        }
        defer { index += 1 }
        return indices[index]
    }
    
}




class WeightedSelector :  RuleCandidateSelector {
    
//    static var nextId = 0
//    let id:Int = {
//        defer { WeightedSelector.nextId+=1 }
//        return WeightedSelector.nextId
//    }()
    
    let weights: [Int]
    let sum: UInt32
    
    init(_ distribution:[Int]) {
        weights = distribution
        sum = UInt32(weights.reduce(0, +))
    }
    
    func pick(count: Int) -> Int {
        let choice = Int(arc4random_uniform(sum))
        let i = index(choice: choice)
        // print("id: ", id, "weights: ", weights, "sum: ", sum, "choice: ", choice, "index: ", i)
        return i
    }
    
    func index(choice: Int) -> Int {
        var choice = choice
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
