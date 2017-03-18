
 
 ![Tracery - powerful content generation](logo.png)
 
# Contents
- [Tracery](#tracery)
    - [Introduction](#introduction)
        - [Installation](#installation)
        - [Basic usage](#basic-usage)
    - [Tags](#tags)
        - [Simple story](#simple-story)
        - [Random numbers](#random-numbers)
    - [Modifiers](#modifiers)
    - [Methods](#methods)
    - [Calls](#calls)
    - [Advanced Usage](#advanced-usage)
        - [Custom Content Selectors](#custom-content-selectors)
            - [Pick First Item Selector](#pick-first-item-selector)
            - [Custom Random Item Selector](#custom-random-item-selector)
        - [Custom Candidate Provider](#custom-candidate-provider)
            - [Weighted Distributions](#weighted-distributions)
        - [Recursion](#recursion)
            - [Rule Expansions](#rule-expansions)
        - [Logging](#logging)
        - [Chaining Evaluations](#chaining-evaluations)
        - [Hierarchical Tag Storage](#hierarchical-tag-storage)
        - [Condition Statments](#condition-statments)
        - [`if` block](#`if`-block)
        - [`while` block](#`while`-block)
- [Tracery Grammar](#tracery-grammar)
- [Conclusion](#conclusion)
 
# Tracery
## Introduction


 Tracery is a content generation library originally created by [@GalaxyKate](http://www.galaxykate.com/); you can find more information at [Tracery.io](http://www.tracery.io)
 

 This implementation, while heavily inspired by the original, has more features added.
 
 The content generation in Tracery works based on an input set of rules. The rules determine how content should be generated.
 
### Installation
 
- Clone or download this repository
- To work with the playground, open Playgrounds/Tracery.playground
- The project builds `iOS` and `macOS` framework targets, which can be linked to your projects
 
### Basic usage
 



```swift
import Tracery

// create a new Tracery engine

var t = Tracery {[
    "msg" : "hello world"
]}

t.expand("well #msg#")

// output: well hello world
```




 We create an instance of the Tracery engine passing along a dictionary of rules. The keys to this dictionary are the rule names, and the value for each key represents the expansion of the rule.
 
 The we use Tracery to expand instances of specified rules

 Notice we provide as input a template string, which contains `#msg#`, that is the rule we wish to expand inside `#` marks. Tracery evaluates the template, recognizes a rule, and replaces it with its expansion.
 
 We can have multiple rules:


```swift
t = Tracery {[
    "name": "jack",
    "age": "10",
    "msg": "#name# is #age# years old",
]}

t.expand("#msg#") // jack is 10 years old
```



 Notice how we specify to expand `#msg#`, which then triggers the expansion of `#name#` and `#age#` rules? Tracery can recursively expand rules until no further expansion is possible.
 
 A rule can have multiple candidates expansions.


```swift
t = Tracery {[
    "name": ["jack", "john", "jacob"], // we can specify multiple values here
    "age": "10",
    "msg": "#name# is #age# years old",
    ]}

t.expand("#msg#")

// jacob is 10 years old  <- name is randomly picked

t.expand("#msg#")

// jack is 10 years old   <- name is randomly picked

t.expand("#name# #name#")

// will print out two different random names
```



 In the snippet above, whenever Tracery sees the rule `#name#`, it will pick out one of the candidate values; in this example, name could be "jack" "john" or "jacob"
 
 This is what allows content generation. By specifying various candidates for each rule, every time `expand` is invoked yields a different result.
 
 Let us try to build a sentence based on a popular nursery rhyme.


```swift
t = Tracery {[
    "boy" : ["jack", "john"],
    "girl" : ["jill", "jenny"],
    "sentence": "#boy# and #girl# went up the hill."
]}

t.expand("#sentence#")

// output: john and jenny went up the hill
```



 So we get the first part of the sentence, what if we wanted to add in a second line so that our final output becomes:
 
 "john and jenny went up the hill, john fell down, and so did jenny too"


```swift
// the following will fail
// to produce the correct output
t.expand("#boy# and #girl# went up the hill, #boy# fell down, and so did #girl#")

// sample output:
// jack and jenny went up the hill, john fell down, and so did jill
```



 The problem is that any occurence of a `#rule#` will be replaced by one of its candidate values. So when we write `#boy#` twice, it may get replaced with entirely different names.
 
 In order to remember values, we can use tags.
 

[top](#contents)
****

## Tags
 
 Tags allow to persist the result of a rule expansion to a temporary variable.
 


```swift
t = Tracery {[
    "boy" : ["jack", "john"],
    "girl" : ["jill", "jenny"],
    "sentence": "[b:#boy#][g:#girl#] #b# and #g# went up the hill, #b# fell down, and so did #g#"
]}

t.expand("#sentence#")

// output: jack and jill went up the hill, jack fell down, and so did jill
```



 Tags are created using the format `[tagName:tagValue]`. In the above snippet we first create two tags, `b` and `g` to hold values of `boy` and `girl` names respectively. Later on we can use `#b#` and `#g#` as if they were new rules and we Tracery will recall their stored values as required for substitution.
 
 Tags can also simply contain a value, or a group of values. Tags can also appear inside `#rules#`. Tags are variable, they can be set any number of times.
 
 
### Simple story
 
 Here is a more complex example that generates a _short_ story.
 


```swift
t = Tracery {[

    "name": ["Arjun","Yuuma","Darcy","Mia","Chiaki","Izzi","Azra","Lina"],
    "animal": ["unicorn","raven","sparrow","scorpion","coyote","eagle","owl","lizard","zebra","duck","kitten"],
    "mood": ["vexed","indignant","impassioned","wistful","astute","courteous"],
    "story": ["#hero# traveled with her pet #heroPet#.  #hero# was never #mood#, for the #heroPet# was always too #mood#."],
    "origin": ["#[hero:#name#][heroPet:#animal#]story#"]
]}

t.expand("#origin#")

// sample output:
// Darcy traveled with her pet unicorn. Darcy was never vexed, for the unicorn was always too indignant.
```



 
### Random numbers
 
 Here's another example to generate a random number:
 


```swift
t.expand("[d:0,1,2,3,4,5,6,7,8,9] random 5-digit number: #d##d##d##d##d#")

// sample output:
// random 5-digit number: 68233
```



 
 In
 
 > If a tag name matches a rule, the tag will take precedence and will always be evaluated.
 
 Now that we have the hang of things, we will look at rule modifiers.
 
 






[top](#contents)
****

## Modifiers
 
 When expanding a rule, sometimes we may need to capitalize its output, or transform it in some way. The Tracery engine allows for defining rule extensions.
 
 One kind of rule extension is known as a modifier.
 


```swift
import Tracery

var t = Tracery {[
    "city": "new york"
]}

// add a bunch of modifiers
t.add(modifier: "caps") { return $0.uppercased() }
t.add(modifier: "title") { return $0.capitalized }
t.add(modifier: "reverse") { return String($0.characters.reversed()) }

t.expand("#city.caps#")

// output: NEW YORK

t.expand("#city.title#")

// output: New York

t.expand("#city.reverse#")

// output: kroy wen
```



 The power of modifiers lies in the fact that they can be chained.


```swift
t.expand("#city.reverse.caps#")

// output: KROY WREN

t.expand("There once was a man named #city.reverse.title#, who came from the city of #city.title#.")
// output: There once was a man named Kroy Wen, who came from the city of New York.
```




 
 > The original implementation at Tracery.io a couple of has modifiers that allows prefixing a/an to words, pluralization, caps etc. The library follows another approach and provides customization endopints so that one can add as many modifiers as required.
 
 The next rule expansion option is the ability to add custom rule methods.
 




 

[top](#contents)
****

## Methods
 
 While modifiers would receive as input the current candidate value of a rule, methods can be used to define modifiers that can accept parameters.
 
 
 Methods are written and called in the same way as modifiers.
 


```swift
import Tracery

var t = Tracery {[
    "name": ["Jack Hamilton", "Manny D'souza", "Rihan Khan"]
]}

t.add(method: "prefix") { input, args in
    return args[0] + input
}

t.add(method: "suffix") { input, args in
    return input + args[0]
}

t.expand("#name.prefix(Mr. )#") // Mr. Jack Hamilton
```



 And like modifiers, they can be chained. In fact, any type of rule extension can be chained.


```swift
t.expand("#name.prefix(Mr. ).suffix( woke up tired.)#") // Mr. Rihan Khan woke up tired.
```




 The power of methods come from the fact that arguments to the method can themselves be rules (or tags). Tracery will expand these and  pass in the correct value to the method.


```swift
t = Tracery {[
    "count": [1,2,3,4],
    "name": ["jack", "joy", "jason"]
]}

t.add(method: "repeat") { input, args in
    let count = Int(args[0]) ?? 1
    return String(repeating: input, count: count)
}

// repeat a randomly selected name, a random number of times
t.expand("#name.repeat(#count#)")

// repeat a tag's value 3 times
t.expand("[name:benzi]#name.repeat(3)#")
```



 
 > Notice how we create a tag called `name` which overrides the rule `name`. Tags always take precedence over rules.
 





[top](#contents)
****

## Calls
 
 There is one more type of rule extension, which is a `call`. Unlike modifiers and methods that work with arguments, parameters and are expected to return some string value, calls do not need to do these.
 
 Calls have the same syntax as that of a modifier `#rule.call_something#`, except that they do not modify any results.
 
 Just to show how calls work, we will create one to track a rule expansion.
 


```swift
import Tracery

var t = Tracery {[
    "f": "f"
    "letter" : ["a", "b", "c", "d", "e", "#f.track#"]
]}

t.add(call: "track") {
    print("rule 'f' was expanded")
}

t.expand("#letter#")
```



 
 In the code snippet above, the rule letter has 5 candidates, 4 of which are basically string values, but the fifth one is a rule. Yes, rules can be mixed in freely and can appear anywhere at all. So in this case, rule `f` can be expanded to the basic string `f`. Notice we also have added the track call.
 
 Now, whenever `letter` choose the rule `f` as a candidate for expansion, `.track` will be called.
 
 
 > Rule extensions can be place on their own inside a pair `#`. For example, if we created a modifier that always adds 'yo' to its input, called it `yo`, and have a rule candidate like `#.yo#`, this evaluates to the string "yo"; the modifier is passed in the empty string as an input parameter since there were no rules to expand.
 
 At this point, we have pretty much covered the basics. The following sections cover more advanced topics that involved getting more control over the candidate selection process.
 





[top](#contents)
****

## Advanced Usage
 
### Custom Content Selectors
 
 We know that a rule can have multiple candidates. By default, Tracery chooses a candidate option randomly, but the selection process is guaranteed to be strictly uniform. 
 
 
 That is to say, if there was a rule with 5 options, and that rule was evaluated 100 times, each of those 5 options would have been selected exactly 20 times.
 
 This is easy to demonstrate:
 



```swift
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
```




 This is all well and good, and the default implementation might be enough for most cases. However, you may come across the requirement to support deterministic selection of candidates for a rule. For e.g. you may wish to select candidates in sequence, or always pick the first available candidate, or use some pseudo-random generator to pick values for repeatability.
 
 To support these cases and more, Tracery provides the option to specify custom content selectors for each rule.
 
 
#### Pick First Item Selector
 
 Let us look at a simple example.
 



```swift
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
```



 
 As you can see, only `a` was selected. 
 
#### Custom Random Item Selector
 
 For another example, let's create a custom random selector.
 


```swift
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
```




 Notice how the distribution of value selection changes when using `arc4random_uniform`. As the number of runs increases over time, `arc4random_uniform` will tend towards a uniform distribution, unlike the default implementation in Tracery, which even with 5 runs guarantees all 5 options are picked once.
 


```swift
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
```



 
 Now that we know fairly well how content selection works for a given rule, let us tackle the problem of weighted distributions.
 
 Say we need a particular candidate to be chosen 5 times more often than another candidate.
 
 One way of specifying this would be as follows:
 


```swift
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
```



 
 This may work out for simple cases, but if you have more candidates, and more complex weight distribution rules, things can get messy quite quick.
 
 In order to provide more flexibility over candidate representation, Tracery allows custom candidate providers.
 
### Custom Candidate Provider
 
#### Weighted Distributions
 




```swift
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
```



 By providing a custom cadidate provider as the expansion to a rule, we can get total control over listing candidates. In this implementation, instead of repeating `a` 5 times as before, we just need to specify `a` once, along with its intended weight for the overall distribution.
 
 This provides a very powerful mechanism to control what candidates are available for a rule to expand on. For example, you could write a custom cadidate provider that presents 50 candidates based on whether an external condition is met, or 100 otherwise. The possibilities are endless.
 
 In summary
 
 * Use _modifiers_ and _methods_ to modify the expanded rule
 * Custom *candidate selectors* can be specified at a rule level to control how rules get expanded
 * Using a custom *candidates provider* can give you more control over the expansion possibilities of a rule
 




 
### Recursion
 
#### Rule Expansions
 
 It is possible to define recursive rules. When doing so, you must provide at least one rule candidate that exits out of the recursion.
 


```swift
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
```



 
 If you wish to have a random sequence of a speicific length, you may want to create a custom `RuleCandidateSelector`, or write up/generate a non-recursive set of rules.
 
 > You can control how deep recursive rules can get expanded by changing the `Tracery.maxStackDepth` property.
 
 
### Logging
 
 You can control logging behaviour by changing the `Tracery.logLevel` property.
 


```swift
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
```




 
 The available logging options are:
 
* `none`
* `errors` - prints any parsing errors (default)
* `warnings` - prints warnings, e.g. highlights recursive rules, cylic references, possibly invalid rules, etc
* `info` - prints informational messages, e.g. what state the tracery engine is in
* `verbose` - prints trace level messages, you can get detailed notes on how the engine parses text, and evaluates rules
 
 
### Chaining Evaluations
 
 Consider the following example:
 


```swift
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
```



 
 We now have a mechanism to expand a rule based on the expansion results of another rule.
 
### Hierarchical Tag Storage
 
 By default, tags have global scope. This means that a tag can be set anywhere and its value will be accessible by any rule at any level of rule expansion. We can restrict tag access using hierarchical storage.
 
 Rules are expandede using a stack. Each rule evaluation occurs at a specific depth on the stack. If a rule at level `n` expands to two sub-rules, the two sub-rules will be evaluated at level `n+1`. A tag's level `n` will be the same as that of the rule at level `n` which created it.
 
 When a rule at level `n` tries to expand a tag, `Tracery` will check if a tag exists at level `n`, or search levels n-1,...0 until its able to find a value.
 
 
 In the example below, we use hierarchical storage to push and pop matching open and close braces, at various levels of rule expansion. The matching close brace is _remembered_ when the rule sub-expansion finishes.
 


```swift
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

```


```swift
import Foundation
import Tracery
```



### Condition Statments
### `if` block
 
 If blocks are supported. You can use if blocks to check if a rule matches a condition, and based on that, output different content. The format is `[if condition then rule (else rule)]`. The `else` part is optional.
 
 A condition is expressed as: `rule condition_operator rule`. Both the left hand side and right hand side `rule`s are expanded, and their ouput is checked based on the `condition operator` specified.
 
 The following conditional operators are permitted:
 
 - `==` check if LHS matches RHS
 - `!=` check if LHS does not match RHS
 - `in` check if LHS is contained in RHS
 - `not in` check if LHS is not contained in RHS
 
 


```swift
var t = Tracery {[
    
    "digit" : [0,1,2,3,4,5,6,7,8,9],
    "binary": [0,1],
    "is_binary": "is binary",
    "not_binary": "is not binary",
    
    // check if generated digit is binary
    "msg_if_binary" : "[d:#digit#][if #d# in #binary# then #d# #is_binary# else #d# #not_binary#]",
    
    // ouput only if generated digit is zero
    "msg_if_zero" : "[d:#digit#][if #d# == 0 then #d# zero]"
]}

t.expand("#msg_if_binary#")
t.expand("#msg_if_zero#")
```



### `while` block
 
 While blocks can be used to create loops. It takes the form `[while condition do rule]`. As long as the `condition` evaluates to true, the `rule` specified in the `do` section gets expanded.
 



```swift
// print out a number that does not contain digits 0 or 1
t.expand("[while #[d:#digit#]d# not in #binary# do #d#]")

```



 

[top](#contents)
****

# Tracery Grammar
 
 This section attempts to describe the grammar specification for Tracery.
 

```
 rule_candidate -> ( plain_text | rule | tag )*
 
 
 tag -> [ tag_name : tag_value ]
 
    tag_name -> plain_text
 
    tag_value -> tag_value_candidate (,tag_value_candidate)*
 
        tag_value_candidate -> rule_candidate
 
 
 rule -> # (tag)* | rule_name(.modifier|.call|.method)* | control_block* #
 
    rule_name -> plain_text
 
    modifier -> plain_text
 
    call -> plain_text
 
    method -> method_name ( param (,param)* )
 
        method_name -> plain_text
 
        param -> plain_text | rule
 
 
 
 control_block -> if_block | while_block
 
    condition_operator -> == | != | in | not in
 
    condition -> rule condition_operator rule
 
    if_block -> [if condition then rule (else rule)]
 
    while_block -> [while condition do rule]
 
 
 
```
 

[top](#contents)
****

# Conclusion
 
 Tracery in Swift was developed by [Benzi](https://twitter.com/benziahamed).
 
 Original library in Javascript is available at [Tracery.io](http://www.tracery.io/).
 
 


> This README was auto-generated using [playme](https://github.com/BenziAhamed/playme)
