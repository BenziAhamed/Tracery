//: Playground - noun: a place where people can play

import UIKit

import Tracery

extension String {
    func padLeft(_ toLength: Int, withPad character: Character = " ") -> String {
        let newLength = self.characters.count
        if newLength < toLength {
            return String(repeatElement(character, count: toLength - newLength)) + self
        } else {
            return self.substring(from: index(self.startIndex, offsetBy: newLength - toLength))
        }
    }
    func padRight(_ toLength: Int, withPad character: Character = " ") -> String {
        let newLength = self.characters.count
        if newLength < toLength {
            return self + String(repeatElement(character, count: toLength - newLength))
        } else {
            return self.substring(from: index(self.startIndex, offsetBy: newLength - toLength))
        }
    }
    func repeating(_ count: Int) -> String {
        return .init(repeating: self, count: count)
    }
    func padToCenter(_ toLength: Int, withPad character: Character = " ") -> String {
        let extra = toLength - self.characters.count
        var (left, right) = (extra/2, extra - extra/2)
        if left + right != extra {
            right += 1
        }
        if extra < 0 {
            let start = index(startIndex, offsetBy: -left)
            let end = index(endIndex, offsetBy: -right)
            return self.substring(with: start..<end)
        }
        
        return String(repeating: "\(character)", count: left)
            .appending(self)
            .appending(String(repeating: "\(character)", count: right))
    }
}

Tracery.logLevel = .errors

var tracker = [String: Int]()
let numbers = [1,2,3,4,5]
numbers.forEach { tracker["\($0)"] = 0 }

var s = Tracery {[
    "number": numbers,
    ]}

s.add(modifier: "record") {
    let count = tracker[$0] ?? 0
    tracker[$0] = count + 1
    return $0
}

s.setCandidateSelector(rule: "number", selector: {
    
    class PickFirst : RuleCandidateSelector {
        func pick(count: Int) -> Int {
            return 0
        }
    }
    return PickFirst()
    
    //    class Arc4Selector : RuleCandidateSelector {
    //        func pick(count: Int) -> Int {
    //            return Int(arc4random_uniform(UInt32(count)))
    //        }
    //    }
    //    return Arc4Selector()
    
}())

for i in 0..<100 {
    s.expand("#number.record#")
}

print("-".repeating(40))
print("distribution table")
print("item".padRight(10),"count".padLeft(10),"%".padToCenter(10))
print("-".repeating(40))
var total = tracker.values.reduce(0, +)
tracker.keys.sorted().forEach { key in
    let value = tracker[key]!
    print(key.padRight(10), "\(value)".padLeft(10), "\(100 * Double(value)/Double(total))".padLeft(10))
}
print("-".repeating(40))
print("total".padRight(10), "\(total)".padLeft(10))
print("-".repeating(40))








