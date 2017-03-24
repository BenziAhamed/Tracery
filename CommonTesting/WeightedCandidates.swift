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
    
    
    func testWeightedCandidatesAllowZero2() {
        
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
    
}
