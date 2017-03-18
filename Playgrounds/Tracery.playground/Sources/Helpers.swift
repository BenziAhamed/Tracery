import Foundation
import Tracery


// scan is similar to reduce, but accumulates the intermediate results
public extension Sequence {
    @discardableResult
    func scan<T>(_ initial: T, _ combine: (T, Iterator.Element) throws -> T) rethrows -> [T] {
        var accu = initial
        return try map { e in
            accu = try combine(accu, e)
            return accu
        }
    }
}

// This class implements two protocols
// RuleCandidateSelector - which as we have seen before is used to
//                         to select content in a custom way
// RuleCandidatesProvider - the protocol which needs to be
//                          adhered to to provide customised content
public class WeightedCandidateSet : RuleCandidatesProvider, RuleCandidateSelector {
    
    public let candidates: [String]
    let weights: [Int]
    
    public init(_ distribution:[String:Int]) {
        distribution.values.map { $0 }.forEach {
            assert($0 > 0, "weights must be positive")
        }
        candidates = distribution.map { $0.key }
        weights = distribution.map { $0.value }
    }
    
    public func pick(count: Int) -> Int {
        let sum = UInt32(weights.reduce(0, +))
        var choice = Int(arc4random_uniform(sum))
        var index = 0
        for weight in weights {
            choice = choice - weight
            if choice <= 0 {
                return index
            }
            index += 1
        }
        fatalError()
    }
    
}

