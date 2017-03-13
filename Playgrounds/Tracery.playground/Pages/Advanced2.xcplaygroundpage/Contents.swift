//: [Previous](@previous)

/*:
 
 ### Recursion
 
 #### Rule Expansions
 
 It is possible to define recursive rules. When doing so, you must provide at least one rule candidate that exits out of the recursion.
 
 */

import Tracery

// suppose we wish to generate a random binary string
// if we write the rules as

var t = Tracery {[
    "binary": [ "0 #binary#", "1 #binary#" ]
]}

t.expand("#binary#")


// will output:
// ⛔️ stack overflow

// Since there is no option to exit out of the rule expansion
// We can add one explicitly

t = Tracery {[
    "binary": [ "0#binary#", "1#binary#", "" ]
]}

print(t.expand("attempt 2: #binary#"))

// while this works, if we run this a couple of times
// you will notice that the output is as follows:

// all possible outputs:
// attempt 2: 1
// attempt 2: 0
// attempt 2: 01
// attempt 2: 10
// attempt 2:       <- empty

// all possible outputs are limited because the built-in
// candidate selector is guaranteed to quickly select the ""
// candidate to maintain a strict uniform distribution
// we can fix this

t = Tracery {[
    "binary": WeightedCandidateSet([
        "0#binary#": 10,
        "1#binary#": 10,
                 "":  1
    ])
]}

print(t.expand("attempt 3: #binary#"))

// sample outputs:
// attempt 3: 011101000010100001010
// attempt 3: 1010110
// attempt 3: 10101100101   and so on

// Now we have more control, as we are stating that we are 20 times more
// likely to continue with a binary rule than the exit

/*:
 
 If you wish to have a random sequence of a speicific length, you may want to create a custom `RuleCandidateSelector`, or write up/generate a non-recursive set of rules.
 
 > You can control how deep recursive rules can get expanded by changing the `Tracery.maxStackDepth` property.
 
 
 ### Logging
 
 You can control logging behaviour by changing the `Tracery.logLevel` property.
 
 */

Tracery.logLevel = .verbose


t = Tracery {[
    "binary": WeightedCandidateSet([
        "0#binary#": 10,
        "1#binary#": 10,
        "":  1
        ])
    ]}

print(t.expand("attempt 3: #binary#"))

// sample output:
// attempt 3: 101010100011001001011
// attempt 3: 001001011111
// attempt 3: 1110010111121111
// attempt 3: 10

// this will print the entire trace that Tracery generates, you will see detailed output regarding rule validation, parsing, rule expansion - useful to debug and understand how rules are processed.


/*:
 
 The available logging options are:
 
* `none`
* `errors` - prints any parsing errors (default)
* `warnings` - prints warnings, e.g. highlights recursive rules, cylic references, possibly invalid rules, etc
* `info` - prints informational messages, e.g. what state the tracery engine is in
* `verbose` - prints trace level messages, you can get detailed notes on how the engine parses text, and evaluates rules
 
 
 ### Chaining Evaluations
 
 Consider the following example:
 
 */

t = Tracery {[
    "b" : ["0", "1"],
    "num": "#b##b#",
    "10": "one_zero",
    "00": "zero_zero",
    "01": "zero_one",
    "11": "one_one",
]}

t.expand("#num#")

// will print either 01, 10, 11 or 10

t.add(modifier: "eval") { [unowned t] input in
    // treat input as a rule and expand it
    return t.expand("#\(input)#")
}

t.expand("#num.eval#")

// will now print one_zero, zero_zero, zero_one or one_one

/*:
 
 We now have a mechanism to expand a rule based on the expansion results of another rule.
 
 ### Hierarchical Tag Storage
 
 By default, tags have global scope. This means that a tag can be set anywhere and its value will be accessible by any rule at any level of rule expansion. We can restrict tag access using hierarchical storage.
 
 Rules are expandede using a stack. Each rule evaluation occurs at a specific depth on the stack. If a rule at level `n` expands to two sub-rules, the two sub-rules will be evaluated at level `n+1`. A tag's level `n` will be the same as that of the rule at level `n` which created it.
 
 When a rule at level `n` tries to expand a tag, `Tracery` will check if a tag exists at level `n`, or search levels n-1,...0 until its able to find a value.
 
 
 In the example below, we use hierarchical storage to push and pop matching open and close braces, at various levels of rule expansion. The matching close brace is _remembered_ when the rule sub-expansion finishes.
 
 */

let options = TraceryOptions()
options.tagStorageType = .heirarchical

let braceTypes = ["()","{}","<>","«»","𛰫𛰬","⌜⌝","ᙅᙂ","ᙦᙣ","⁅⁆","⌈⌉","⌊⌋","⟦⟧","⦃⦄","⦗⦘","⫷⫸"]
    .map { braces -> String in
        let open = braces[braces.startIndex]
        let close = braces[braces.index(after: braces.startIndex)]
        return "[open:\(open)][close:\(close)]"
}

let h = Tracery(options) {[
    "letter": ["A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P"],
    "bracetypes": braceTypes,
    "brace": [
        // open with current symbol, 
        // create new symbol, open brace pair and evaluate a sub-rule call to brace
        // finally close off with orginal symbol and matching close brace pair
        "#open##symbol# #origin##symbol##close# ",
        
        "#open##symbol# #origin##symbol##close# #origin#",

        // exits recursion
        "",
    ],
    
    // start with a symbol and bracetype
    "origin": ["#[symbol:#letter#][#bracetypes#]brace#"]
]}

h.expand("#origin#")

// sample outputs:
// {L ⌜D D⌝ (P 𛰫O O𛰬 <F ⦃C C⦄ F> P) L}
// ⁅M ᙅK Kᙂ ᙦE {O O} Eᙣ M⁆
// ⌈C C⌉
// <K K>

//: [Conclusion](@next)
