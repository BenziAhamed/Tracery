//: [Previous](@previous)

/*:
 # Calls
 
 There is one more type of rule extension, which is a `call`. Unlike modifiers and methods that work with arguments, parameters and are expected to return some string value, calls do not need to do these.
 
 Calls have the same syntax as that of a modifier `#rule.call_something#`, except that they do not modify any results.
 
 Just to show how calls work, we will create one to track a rule expansion.
 
 */

import Tracery

var t = Tracery {[
    "f": "f"
    "letter" : ["a", "b", "c", "d", "e", "#f.track#"]
]}

t.add(call: "track") {
    print("rule 'f' was expanded")
}

t.expand("#letter#")

/*:
 
 In the code snippet above, the rule letter has 5 candidates, 4 of which are basically string values, but the fifth one is a rule. Yes, rules can be mixed in freely and can appear anywhere at all. So in this case, rule `f` can be expanded to the basic string `f`. Notice we also have added the track call.
 
 Now, whenever `letter` choose the rule `f` as a candidate for expansion, `.track` will be called.
 
 
 > Rule extensions can be place on their own inside a pair `#`. For example, if we created a modifier that always adds 'yo' to its input, called it `yo`, and have a rule candidate like `#.yo#`, this evaluates to the string "yo"; the modifier is passed in the empty string as an input parameter since there were no rules to expand.
 
 At this point, we have pretty much covered the basics. The following sections cover more advanced topics that involved getting more control over the candidate selection process.
 
 */

//: [Advanced](@next)
