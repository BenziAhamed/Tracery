//
//  Conditionals.swift
//  Tracery
//
//  Created by Benzi on 14/03/17.
//  Copyright © 2017 Benzi Ahamed. All rights reserved.
//

import Foundation
import XCTest
@testable import Tracery

class Conditionals: XCTestCase {
    
    func testBasicIfBlockWorks() {
        
        let t = Tracery {[
            "name": ["benzi"]
        ]}
        
        XCTAssertEqual(t.expand("[if #name#==benzi     then ok]"), "")
        
        XCTAssertEqual(t.expand("[if #name# == benzi then ok]"), "ok")
        XCTAssertEqual(t.expand("[if #name#== benzi then ok]"), "ok")
        XCTAssertEqual(t.expand("[if #name#==benzi then ok]"), "ok")
        XCTAssertNotEqual(t.expand("[if #name#==benzithen ok]"), "ok")
        
        XCTAssertEqual(t.expand("[if #name# == benzi then ok else not-ok]"), "ok")
        XCTAssertEqual(t.expand("[if #name# != danny then ok else not-ok]"), "ok")

    }
    
    func testIfBlockWorksWithTags() {
        
        let t = Tracery {[
            "name": ["benzi"]
            ]}
        
        XCTAssertEqual(t.expand("[tag:#name#][if #tag# == benzi then ok]"), "ok")
        XCTAssertEqual(t.expand("[tag:#name#][if #tag# != benzi then not-ok else ok]"), "ok")
        
    }
    
    
    func testIfBlockWithListConditionCheck() {
        let t = Tracery {[
            "num": [0,1],
            "msg": "[if #value# in #num# then binary else not a binary]",
            "msg_then_2word": "[if #value# in #num# then binary digit else no]"
        ]}
        
        XCTAssertEqual(t.expand("[value:0]#msg#"), "binary")
        XCTAssertEqual(t.expand("[value:1]#msg#"), "binary")
        
        XCTAssertEqual(t.expand("[value:in]#msg#"), "not a binary")
        XCTAssertEqual(t.expand("[value:while]#msg#"), "not a binary")
        XCTAssertEqual(t.expand("[value:for]#msg#"), "not a binary")
        XCTAssertEqual(t.expand("[value:10001]#msg#"), "not a binary")
        
        XCTAssertEqual(t.expand("[value:0]#msg_then_2word#"), "binary digit")
        XCTAssertEqual(t.expand("[value:1]#msg_then_2word#"), "binary digit")
        
        
        XCTAssertEqual(t.expand("[tag:2,3][if #num# not in #tag# then ok]"), "ok")
    }
    
    
    func testIfBlockWorksWithHierarchicalTagStorageModel() {
        
        let t = Tracery.hierarchical {[
            
            // create tag and check value
            "level1if_A" : "[tag:name][if #tag# == name then valid else invalid]",
            "call_A" : "#level1if_A#",
            
            // create tag, check value, use value
            "level1if_B" : "[tag:name][if #tag# == name then valid #tag# else invalid #tag#]",
            "call_B" : "#level1if_B#",
            
            // create tag at level n+1, not visible at n
            "create": "[tag:level2]",
            "level2_create" : "#create#", // if we set tag here, level is not incremented
            "level2_if":  "[#level2_create#][if #tag# != level2 then valid]",
            "call_L2": "#level2_if#",
            
            "level2B_create" : "[tag:level2B]", // if we set tag here, it should be visible in if
            "level2B_if":  "[#level2B_create#][if #tag# == level2B then valid]",
            "call_L2B": "#level2B_if#",
        ]}
        
        
        XCTAssertEqual(t.expand("#call_A#"), "valid")
        XCTAssertEqual(t.expand("#call_B#"), "valid name")
        XCTAssertEqual(t.expand("#call_L2#"), "valid")
        XCTAssertEqual(t.expand("#call_L2B#"), "valid")
    }
    
    
    func testIfBlockAllowsComplexConditionals() {
        let t = Tracery {[
            "tag2": ["name1","name2","name3","#name4#"],
            "name4": "name"
        ]}
        XCTAssertEqual(t.expandVerbose("[if #[tag1:name]tag1# in #tag2# then ok else nope]"), "ok")
    }
    
    
    func testBasicWhileBlockWorks() {
        
        let t = Tracery {[
            "binary": WeightedCandidateSet([
                        "0": 10,
                        "1": 10,
                        "": 1,
                      ]),
        ]}
        
        var generated = -1 // start from -1 because the last generated binary will be empty
        t.add(call: "track") {
            generated += 1
        }
        
        let output = t.expand("[while #[digit:#binary.track#]digit# in #[options:0,1]options# do b]")
        
        XCTAssertFalse(output.contains("stack overflow"))
        XCTAssertEqual(output, String(repeating: "b", count: generated))
        
    }
    
    func testWhileLoopGenerateNumberNotContainingZeroOrOne() {
        let t = Tracery {[
            "digit" : [0,1,2,3,4,5,6,7,8,9],
            "binary": [0,1],
        ]}
        let output = t.expand("[while #[d:#digit#]d# not in #binary# do #d#]")
        XCTAssertNil(output.range(of: "0"))
        XCTAssertNil(output.range(of: "1"))
    }
        
    
}
