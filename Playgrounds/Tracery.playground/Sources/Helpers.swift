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
    
    // required for RuleCandidatesProvider
    public let candidates: [String]
    
    let runningWeights: [(total:Int, target:Int)]
    let totalWeights: UInt32
    
    public init(_ distribution:[String:Int]) {
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
    
    // required for RuleCandidateSelector
    public func pick(count: Int) -> Int {
        let choice = Int(arc4random_uniform(totalWeights) + 1) // since running weight start at 1
        for weight in runningWeights {
            if choice <= weight.total {
                return weight.target
            }
        }
        // we will never reach here
        fatalError()
    }
    
}
