//: [Previous](@previous)


/*:
 # Modifiers
 
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
 
 > The original implementation at Tracery.io a couple of has modifiers that allows prefixing a/an to words, pluralization, caps etc. The library follows another approach and provides customization endopints so that one can add as many modifiers as required.
 
 The next rule expansion option is the ability to add custom rule methods.
 
 */


//: [Methods](@next)
