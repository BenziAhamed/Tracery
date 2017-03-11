/*:
 
 ![Tracery - powerful content generation](logo.png)
 
 {{GEN:TOC}}
 
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
 

*/

import Tracery

// create a new Tracery engine

var t = Tracery {[
    "msg" : "hello world"
]}

t.expand("well #msg#")

// output: well hello world

/*:

 We create an instance of the Tracery engine passing along a dictionary of rules. The keys to this dictionary are the rule names, and the value for each key represents the expansion of the rule.
 
 The we use Tracery to expand instances of specified rules

 Notice we provide as input a template string, which contains `#msg#`, that is the rule we wish to expand inside `#` marks. Tracery evaluates the template, recognizes a rule, and replaces it with its expansion.
 
 We can have multiple rules:
 */

t = Tracery {[
    "name": "jack",
    "age": "10",
    "msg": "#name# is #age# years old",
]}

t.expand("#msg#") // jack is 10 years old

/*:
 Notice how we specify to expand `#msg#`, which then triggers the expansion of `#name#` and `#age#` rules? Tracery can recursively expand rules until no further expansion is possible.
 
 A rule can have multiple candidates expansions.
 */

t = Tracery {[
    "name": ["jack", "john", "jacob"], // we can specify multiple values here
    "age": "10",
    "msg": "#name# is #age# years old",
    ]}

t.expand("#msg#")

// jacob is 10 years old

t.expand("#msg#")

// jack is 10 years old

t.expand("#name# #name#")

// will print out two different names

/*:
 In the snippet above, whenever Tracery sees the rule `#name#`, it will pick out one of the candidate values; in this example, name could be "jack" "john" or "jacob"
 
 This is what allows content generation. By specifying various candidates for each rule, every time `expand` is invoked yields a different result.
 
 Let us try to build a sentence based on a popular nursery rhyme.
 */

t = Tracery {[
    "boy" : ["jack", "john"],
    "girl" : ["jill", "jenny"],
    "sentence": "#boy# and #girl# went up the hill."
]}

t.expand("#sentence#")

// output: john and jenny went up the hill

/*:
 So we get the first part of the sentence, what if we wanted to add in a second line so that our final output becomes:
 
 "john and jenny went up the hill, john fell down, and so did jenny too"
 */

// the following will fail
// to produce the correct output
t.expand("#boy# and #girl# went up the hill, #boy# fell down, and so did #girl#")

// sample output:
// jack and jenny went up the hill, john fell down, and so did jill

/*:
 The problem is that any occurence of a `#rule#` will be replaced by one of its candidate values. So when we write `#boy#` twice, it may get replaced with entirely different names.
 
 In order to remember values, we can use tags.
 
 ## Tags
 
 Tags allow to persist the result of a rule expansion to a temporary variable.
 
 */

t = Tracery {[
    "boy" : ["jack", "john"],
    "girl" : ["jill", "jenny"],
    "sentence": "[b:#boy#][g:#girl#] #b# and #g# went up the hill, #b# fell down, and so did #g#"
]}

t.expand("#sentence#")

// output: jack and jill went up the hill, jack fell down, and so did jill

/*:
 Tags are created using the format `[tagName:tagValue]`. In the above snippet we first create two tags, `b` and `g` to hold values of `boy` and `girl` names respectively. Later on we can use `#b#` and `#g#` as if they were new rules and we Tracery will recall their stored values as required for substitution.
 
 Tags can also simply contain a value, or a group of values. Tags can also appear inside `#rules#`. Tags are variable, they can be set any number of times.
 
 
 ### Simple story
 
 Here is a more complex example that generates a _short_ story.
 
 */

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

/*:
 
 ### Random numbers
 
 Here's another example to generate a random number:
 
 */

t.expand("[d:0,1,2,3,4,5,6,7,8,9] random 5-digit number: #d##d##d##d##d#")

// sample output:
// random 5-digit number: 68233

/*:
 
 In
 
 > If a tag name matches a rule, the tag will take precedence and will always be evaluated.
 
 Now that we have the hang of things, we will look at rule modifiers.
 
 [Modifiers](@next)
 
 */

