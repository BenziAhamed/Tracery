//: [Previous](@previous)

/*:
 
 ## Methods
 
 While modifiers would receive as input the current candidate value of a rule, methods can be used to define modifiers that can accept parameters.
 
 
 Methods are written and called in the same way as modifiers.
 
 */

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

/*:
 And like modifiers, they can be chained. In fact, any type of rule extension can be chained.
 */

t.expand("#name.prefix(Mr. ).suffix( woke up tired.)#") // Mr. Rihan Khan woke up tired.


/*:
 The power of methods come from the fact that arguments to the method can themselves be rules (or tags). Tracery will expand these and  pass in the correct value to the method.
 */

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

/*:
 
 > Notice how we create a tag called `name` which overrides the rule `name`. Tags always take precedence over rules.
 
 */

//: [Calls](@next)
