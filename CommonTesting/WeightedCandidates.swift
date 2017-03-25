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
        var target = -1
        print("iterations", count)
        for i in 1...count {
            // let output = t.expand("#b(0#b#:4,1#b#:4,0,1)##b#"); target = 10
            // let output = t.expand("#b#"); target = 22
            // let output = t.expand("#b(0,1)##n(b#n#:21,b)##n#"); target = 22
            let output = t.expand("#b(0,1)##n(#b##n#:21,#b#)##n#"); target = 22
            print(i, "-", output, "(\(output.characters.count))")
            total += output.characters.count
            XCTAssertFalse(output.contains("stack overflow"))
        }
        let average = Double(total)/Double(count)
        print("AVG", average, "should be close to \(target)")
    }
    
}
