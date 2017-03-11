//: [Previous](@previous)


/*:
 ## Modifiers
 
 When expanding a rule, sometimes we may need to capitalize its output, or transform it in some way. The Tracery engine allows for defining rule extensions.
 
 One kind of rule extension is known as a modifier.
 
 */

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

/*:
 The power of modifiers lies in the fact that they can be chained.
 */

t.expand("#city.reverse.caps#")

// output: KROY WREN

t.expand("There once was a man named #city.reverse.title#, who came from the city of #city.title#.")
// output: There once was a man named Kroy Wen, who came from the city of New York.


/*:
 
 > The original implementation at Tracery.io has some modifiers built-in, however this library does not do the same. Add required modifiers is left to the end users. (e.g. there are many solid implementations of pluralize methods out there, and it should be easy to plug in one to Tracery - this allows Tracery to be lean and focused as a library)
 
 The next rule expansion option is the ability to add custom rule methods.
 
 */


//: [Methods](@next)
