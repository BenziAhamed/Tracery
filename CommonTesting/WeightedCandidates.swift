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
        
        
        let count = 100
        var total = 0
        
        for i in 0..<count {
            let output = t.expand("#number#")
            // print(i, output)
            total += output.characters.count
            XCTAssertFalse(output.contains("stack overflow"))
        }
        
        let average = Double(total)/Double(count)
        print("AVG", average, "should be close to 11")
        // XCTAssertTrue(abs(average - 11.0) < 0.5, "\(average) is not close to 11.0")
    }
    
    
    func testTagValuesCanBeWeighted() {
        
        Tracery().expandVerbose("[b:0#b#:4,1#b#:4,0,1]#b#")
        
    }
    
}
