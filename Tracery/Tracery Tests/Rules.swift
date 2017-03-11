//
//  Tracery_Tests.swift
//  Tracery Tests
//
//  Created by Benzi on 11/03/17.
//  Copyright © 2017 Benzi Ahamed. All rights reserved.
//

import XCTest
@testable import Tracery

class Rules : XCTestCase {
    
    func testExpandSimpleRule() {
        let t = Tracery {[
            "msg" : "hello world"
            ]}
        XCTAssert(t.expand("#msg#") == "hello world")
    }
    
    func testInputWithNoRulesProvidesTheSameAsOutput() {
        let t = Tracery()
        XCTAssert(t.expand("hello world") == "hello world")
    }

    func testRulesNotExpandedIfMatchNotFound() {
        let t = Tracery {[:]}
        let inputs = [
            "hello world",
            "#rule#",
            "no validation",
            "#what# #can# you #say#"
        ]
        for input in inputs {
            XCTAssertEqual(input, t.expand(input))
        }
    }
    
    func testEscapseSequences() {
        let t = Tracery{[:]}
        XCTAssertEqual(t.expand("#"), "#") // trailing hash treated as character
        XCTAssertEqual(t.expand("##"), "") // treated as empty rule
        XCTAssertEqual(t.expand("\\#"), "#")
        XCTAssertEqual(t.expand("\\##"), "##") // trailing hash treated as character
        XCTAssertEqual(t.expand("\\#hello#"), "#hello#") // trailing hash treated as character
        XCTAssertEqual(t.expand("\\["), "[")
        XCTAssertEqual(t.expand("\\[]"), "[]")
        XCTAssertEqual(t.expand("\\[hello]"), "[hello]")
        
        t.add(rule: "rule", definition: "replaced!")
        XCTAssertEqual(t.expand("a \\#rule\\# it escapes"), "a #rule# it escapes")
    }
    
    func testRulesNamesAreAvailable() {
        let rules = "q w e r t y u i o p a s d f g h j k l z x c v b n m".components(separatedBy: " ")
        let t = Tracery { rules.mapDict { return ($0,$0) } }
        let processedRules = t.ruleNames
        for rule in rules {
            XCTAssertTrue(processedRules.contains(rule))
        }
    }
    
}

