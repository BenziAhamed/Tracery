//: [Previous](@previous)

/*:
 ## Advanced Usage
 
 ### Custom Content Selectors
 
 We know that a rule can have multiple candidates. By default, Tracery chooses a candidate option randomly, but the selection process is guaranteed to be strictly uniform. 
 
 
 That is to say, if there was a rule with 5 options, and that rule was evaluated 100 times, each of those 5 options would have been selected exactly 20 times.
 
 This is easy to demonstrate:
 
 */


import Tracery

var t = Tracery {[
    "option": [ "a", "b", "c", "d", "e" ]
]}

var tracker = [String: Int]()

t.add(modifier: "track") { input in
    let count = tracker[input] ?? 0
    tracker[input] = count + 1
    return input
}

func runOptionRule(times: Int, header: String) {
    tracker.removeAll()
    for _ in 0..<times {
        _ = t.expand("#option.track#")
    }
    let sep = String(repeating: "-", count: header.characters.count)
    print(sep)
    print(header)
    print(sep)
    tracker.forEach {
        print($0.key, $0.value)
    }
}

runOptionRule(times: 100, header: "default")
    

// output will be

// b 20
// e 20
// a 20
// d 20
// c 20


/*:
 This is all well and good, and the default implementation might be enough for most cases. However, you may come across the requirement to support deterministic selection of candidates for a rule. For e.g. you may wish to select candidates in sequence, or always pick the first available candidate, or use some pseudo-random generator to pick values for repeatability.
 
 To support these cases and more, Tracery provides the option to specify custom content selectors for each rule.
 
 
 #### Pick First Item Selector
 
 Let us look at a simple example.
 
 */


// create a selector that always picks the first
// item from the available items
class AlwaysPickFirst : RuleCandidateSelector {
    func pick(count: Int) -> Int {
        return 0
    }
}

// attach this new selector to rule: option
t.setCandidateSelector(rule: "option", selector: AlwaysPickFirst())

runOptionRule(times: 100, header: "pick first")

// output will be:
// a 100

/*:
 
 As you can see, only `a` was selected. 
 
 #### Custom Random Item Selector
 
 For another example, let's create a custom random selector.
 
 */

class Arc4RandomSelector : RuleCandidateSelector {
    func pick(count: Int) -> Int {
        return Int(arc4random_uniform(UInt32(count)))
    }
}

t.setCandidateSelector(rule: "option", selector: Arc4RandomSelector())

// do a new dry run
runOptionRule(times: 100, header: "arc4 random")

// sample output, will vary when you try
// b 18
// e 25
// a 20
// d 15
// c 22

/*:

 Notice how the distribution of value selection changes when using `arc4random_uniform`. As the number of runs increases over time, `arc4random_uniform` will tend towards a uniform distribution, unlike the default implementation in Tracery, which even with 5 runs guarantees all 5 options are picked once.
 
 */

t = Tracery {[
    "option": [ "a", "b", "c", "d", "e" ]
]}

t.add(modifier: "track") { input in
    let count = tracker[input] ?? 0
    tracker[input] = count + 1
    return input
}

runOptionRule(times: 5, header: "default")

// output will be
// b 1
// e 1
// a 1
// d 1
// c 1

/*:
 
 Now that we know fairly well how content selection works for a given rule, let us tackle the problem of weighted distributions.
 
 Say we need a particular candidate to be chosen 5 times more often than another candidate.
 
 One way of specifying this would be as follows:
 
 */

t = Tracery {[
    "option": [ "a", "a", "a", "a", "a", "b" ]
    ]}

t.add(modifier: "track") { input in
    let count = tracker[input] ?? 0
    tracker[input] = count + 1
    return input
}

runOptionRule(times: 100, header: "default - weighted")

// sample output, will vary over runs
// b 17 ~> 20% of 100
// a 83 ~> 80% of 100, i.e. 5 times 20

/*:
 
 This may work out for simple cases, but if you have more candidates, and more complex weight distribution rules, things can get messy quite quick.
 
 In order to provide more flexibility over candidate representation, Tracery allows custom candidate providers.
 
 ### Custom Candidate Provider
 
 #### Weighted Distributions
 
 */



// This class implements two protocols
// RuleCandidateSelector - which as we have seen before is used to
//                         to select content in a custom way
// RuleCandidatesProvider - the protocol which needs to be
//                          adhered to to provide customised content
class ExampleWeightedCandidateSet : RuleCandidatesProvider, RuleCandidateSelector {
    
    // required for RuleCandidatesProvider
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
    
    // required for RuleCandidateSelector
    func pick(count: Int) -> Int {
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

t = Tracery {[
    "option": ExampleWeightedCandidateSet(["a": 5, "b": 1])
]}

t.add(modifier: "track") { input in
    let count = tracker[input] ?? 0
    tracker[input] = count + 1
    return input
}

runOptionRule(times: 100, header: "custom weighted")

// sample output, will vary by run
// b 13
// a 87
// as before, option b is 5 times
// more likely to chosen over a

/*:
 By providing a custom cadidate provider as the expansion to a rule, we can get total control over listing candidates. In this implementation, instead of repeating `a` 5 times as before, we just need to specify `a` once, along with its intended weight for the overall distribution.
 
 This provides a very powerful mechanism to control what candidates are available for a rule to expand on. For example, you could write a custom cadidate provider that presents 50 candidates based on whether an external condition is met, or 100 otherwise. The possibilities are endless.
 
 In summary
 
 * Use _modifiers_ and _methods_ to modify the expanded rule
 * Custom *candidate selectors* can be specified at a rule level to control how rules get expanded
 * Using a custom *candidates provider* can give you more control over the expansion possibilities of a rule
 
 */


//: [Advanced contd.](@next)
