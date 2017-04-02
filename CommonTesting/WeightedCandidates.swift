//
//  WeightedCandidates.swift
//  Tracery
//
//  Created by Benzi on 24/03/17.
//  Copyright © 2017 Benzi Ahamed. All rights reserved.
//

import XCTest
import Tracery

class WeightedCandidates: XCTestCase {
    
    func testWeightedCandidatesAllowZero1() {
        
        // create a binary number
        // generator, that only outputs
        // 1's
        
        let t = Tracery.init(lines: [
            "[binary]",
            "1:2",
            "0:0",
            "##",
            "",
            "[origin]",
            "[while [b:#binary#]#b# != ## do #b#]",
        ])
        
        for _ in 0..<100 {
            let output = t.expand("#origin#")
            XCTAssertEqual(output, String(repeating: "1", count: output.characters.count))
        }
        
    }
    
    
    func testWeightedCandidatesIgnoreLeadingSpaces() {
        
        // create a binary number
        // generator, that only outputs
        // 1's
        
        let t = Tracery.init(lines: [
            "[binary]",
            "1#binary#:2",
            "0#binary#:0",
            "##",
            ])
        
        for _ in 0..<100 {
            let output = t.expand("#binary#")
            XCTAssertEqual(output, String(repeating: "1", count: output.characters.count))
        }
        
    }
    
    
    func testWeightedBinaryNumberGenerator() {
        
        let t = Tracery.init(lines: [
            "[binary]",
            "A",
            "B",
            "",
            "[number]",
            "#binary##number#:10",
            "#binary#:1",
            ])
        
        
        let count = 20
        var total = 0
        print("iterations", count)
        for i in 1...count {
            let output = t.expand("#number#")
            print(i, "-", output, "(\(output.characters.count))")
            total += output.characters.count
            XCTAssertFalse(output.contains("stack overflow"))
        }
        
        let average = Double(total)/Double(count)
        print("AVG", average, "should be close to 11")
        // XCTAssertTrue(abs(average - 11.0) < 0.5, "\(average) is not close to 11.0")
    }
    
    
    func testNewRulesCanBeWeighted() {
        
        let t = Tracery {[
            "b" : ["a#b#:10","b#b#:10","a","b"]
        ]}
        let count = 20
        var total = 0
        let target = 10
        print("iterations", count)
        for i in 1...count {
            let output = t.expand("#b(0,1)##n(#b##n#:\(target-1),#b#)##n#")
            print(i, "-", output, "(\(output.characters.count))")
            total += output.characters.count
            XCTAssertTrue(!output.contains("stack overflow"))
            if output.contains("stack overflow") {
                return
            }
        }
        let average = Double(total)/Double(count)
        print("AVG", average, "should be close to \(target)")
    }
    
    
    func testInlineRulesCanBeWeighted() {
        
        // binary number generator
        
        let t = Tracery()
        let count = 1
        var total = 0
        let target = 10
        print("iterations", count)
        for i in 1...count {
            // define inline rule b
            // choices
            // 0
            // 1
            // any(0,1) and then b  : weighted to target-1
            // then trigger b
            let output = t.expand("#b(0,1,#(0,1)##b#:\(target-1))##b#")
            print(i, "-", output, "(\(output.characters.count))")
            total += output.characters.count
            XCTAssertTrue(!output.contains("stack overflow"))
            if output.contains("stack overflow") {
                return
            }
        }
        let average = Double(total)/Double(count)
        print("AVG", average, " after \(count) iterations, should be close to \(target)")
    }
    
    
    func testInlineRulesCanCallExistingRulesWithWeights() {
        
        // prints hi 'x' times more than bye
        // x = 9 means of 0.9 probability of gtting hi
        let x = 9
        
        let t = Tracery.init(lines:[
            "[say_hi]",
            "hi",
            "",
            "[say_bye]",
            "bye",
            "",
            "[msg]",
            "#(#say_hi#:\(x),#say_bye#)#"
        ])
        
        let iterations = 100
        
        var hiCount = 0, byeCount = 0
        for _ in 1...iterations {
            let output = t.expand("#msg#")
            XCTAssertItemInArray(item: output, array: ["hi","bye"])
            hiCount += output == "hi" ? 1 : 0
            byeCount += output == "bye" ? 1 : 0
        }
        
        let moreness = Double(hiCount)/Double(hiCount + byeCount)
        print("after \(iterations) iterations, hi=\(hiCount) bye=\(byeCount) [by: \(moreness) expected: \(Double(x)/10.0)]")
    }
}
