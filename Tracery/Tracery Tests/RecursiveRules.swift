//
//  RecursiveRules.swift
//  Tracery
//
//  Created by Benzi on 11/03/17.
//  Copyright © 2017 Benzi Ahamed. All rights reserved.
//

import XCTest
@testable import Tracery

class RecursiveRules: XCTestCase {
    
    func testStackOverflow() {
        let t = Tracery {[
            "a": "#b#",
            "b": "#a#",
            ]}
        XCTAssertTrue(t.expand("#a#").contains("stack overflow"))
    }
    
    func testRecursiveRulesBoundedByStackDepthLimit() {
        
        func run(length: Int) -> String {
            // create some candidates that recurse
            var candidates = [String]()
            for i in 0..<length-1 {
                candidates.append("\(i) #rule#")
            }
            // add a candidate that will escape out
            // of the recursion
            candidates.append("\(length-1)")
            
            // rule : 0 #rule#, 1 #rule#, ... , n-1 #rule#, n
            // where n = stack limit
            let t = Tracery {[
                "rule" : candidates
                ]}

            // force sequential selection
            // to allow maximum expansion of rules
            t.setCandidateSelector(rule: "rule", selector: SequentialSelector())
            
            return t.expand("#rule#")
        }

        // the default content selector is guaranteed to choose
        // all options before repeating a sequence
        // if we have 3 choices and worst case is
        // rule -> 0 1 2(end)
        // any other sequence will break off
        // rule -> 0 2(end) skipped 1
        // rule -> 2(end) skipped 0, 1
        
        XCTAssertTrue(!run(length: Tracery.maxStackDepth-1).contains("stack overflow"))
        
        XCTAssertTrue(run(length: Tracery.maxStackDepth).contains("stack overflow"))
        
    }
    
}
