//: [Previous](@previous)

/*:
 
 ### Recursion
 
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
 
 */

//: [Conclusion](@next)
