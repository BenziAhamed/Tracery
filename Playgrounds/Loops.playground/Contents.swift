//: Loops
//: Powered by [Tracery](https://github.com/BenziAhamed/Tracery)

import Tracery

let t = Tracery {[
    "init" : [10,5,6],
    "item" : "apple",
    "line" : [
        "I had #count# #item.plural(#count#)#. I ate one. #next_line#",
        "Then I had none."
    ],
    "next_line": "\n[#.decrement#]#line#",
    "story": "[count:#init#]#line#"
]}

t.add(method: "plural") { input, args in
    let count = Int(args[0]) ?? 1
    return count == 1 ? input : input + "s"
}

t.add(call: "decrement") {
    let count = Int(t.expand("#count#", resetTags: false)) ?? 1
    t.expand("[count:\(count-1)]", resetTags: false)
}

t.setCandidateSelector(rule: "line", selector: {
    class LineSelector : RuleCandidateSelector {
        func pick(count: Int) -> Int {
            let count = t.expand("#count#", resetTags: false)
            return count == "0" ? 1 : 0
        }
    }
    return LineSelector()
}())

print(t.expand("#story#"))
