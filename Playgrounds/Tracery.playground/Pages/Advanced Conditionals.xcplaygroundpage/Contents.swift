//: [Previous](@previous)


/*:
 
 ## Control Flow
 
 ### if block
 
 If blocks are supported. You can use if blocks to check if a rule matches a condition, and based on that, output different content. The format is `[if condition then rule (else rule)]`. The `else` part is optional.
 
 A condition is expressed as: `rule condition_operator rule`. Both the left hand side and right hand side `rule`s are expanded, and their ouput is checked based on the `condition operator` specified.
 
 The following conditional operators are permitted:
 
 - `==` check if LHS equals RHS after expansion
 - `!=` check if LHS does not equal RHS after expansion
 - `in` check if LHS expanded is contained in RHS's expansion candidates
 - `not in` check if LHS expanded is not contained in RHS's expansion candidates
 
 
 */

import Foundation
import Tracery


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

/*:
 ### while block
 
 While blocks can be used to create loops. It takes the form `[while condition do rule]`. As long as the `condition` evaluates to true, the `rule` specified in the `do` section gets expanded.
 
 */


// print out a number that does not contain digits 0 or 1
t.expand("[while #[d:#digit#]d# not in #binary# do #d#]")


/*:
 
 ## Text Format
 
 Tracery can recognize rules defined in plain text files as well. The file must contain a set of rule definitions, with the rule specified inside square brackets, and its expansion candidates defined one per line. Here is a sample file:
 
```
[binary]
0#binary#
1#binary#
#empty#
 
[empty]
```
 The above file is a basic binary number generator.
 Here's another one for fable names.
 
```
[fable]
#the# #adjective# #noun#
#the# #noun#
#the# #noun# Who #verb# The #adjective# #noun#
 
[the]
The
The Strange Story of The
The Tale of The
A
The Origin of The
 
[adjective]
Lonely
Missing
Greedy
Valiant
Blind
 
[noun]
Hare
Hound
Beggar
Lion
Frog
 
[verb]
Finds
Meets
Tricks
Outwits
```
 
 This input file will generate output like:
 
```
 A Greedy Frog
 The Beggar
 The Origin of The Hare Who Finds The Missing Lion
 The Strange Story of The Hound
 The Tale of The Blind Frog
```
 
 You use the `Tracery.init(path:)` constructor to consume rules from a plain text file.
 
 */

//: [Conclusion](@next)
