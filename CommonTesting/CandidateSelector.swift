//
//  CandidateSelector.swift
//  Tracery
//
//  Created by Benzi on 11/03/17.
//  Copyright © 2017 Benzi Ahamed. All rights reserved.
//

import XCTest
@testable import Tracery

class CandidateSelector : XCTestCase {
    
    func testRuleCandidateSelectorIsInvoked() {
        let t = Tracery {[
            "msg" : ["hello", "world"]
            ]}
        

        let selector = AlwaysPickFirst()
        
        t.setCandidateSelector(rule: "msg", selector: selector)
        
        XCTAssertEqual(t.expand("#msg#"), "hello")
    }
    
    
    func testRuleCandidateSelectorBogusSelectionsAreIgnored() {
        let t = Tracery {[
            "msg" : ["hello", "world"]
            ]}
        

        let selector = BogusSelector()
        
        t.setCandidateSelector(rule: "msg", selector: selector)
        
        XCTAssertEqual(t.expand("#msg#"), "{msg}")
    }
    
    func testRuleCandidateSelectorReturnValueIsAlwaysHonoured() {
        
        let t = Tracery {[
            "msg" : ["hello", "world"]
            ]}
        

        let selector = PickSpecificItem(offset: .fromEnd(0))
        t.setCandidateSelector(rule: "msg", selector: selector)
        
        var tracker = [
            "hello": 0,
            "world": 0,
            ]
        
        t.add(modifier: "track") {
            let count = tracker[$0] ?? 0
            tracker[$0] = count + 1
            return $0
        }
        
        let target = 10
        for _ in 0..<target {
            XCTAssertEqual(t.expand("#msg.track#"), "world")
        }
        
        XCTAssertEqual(tracker["hello"], 0)
        XCTAssertEqual(tracker["world"], target)
        
    }
    
    func testDefaultRuleCandidateSelectorIsUniformlyDistributed() {
        let animals = ["unicorn","raven","sparrow","scorpion","coyote","eagle","owl","lizard","zebra","duck","kitten"]
        var tracker = [String: Int]()
        animals.forEach { tracker[$0] = 0 }
        
        let t = Tracery { ["animal" : animals] }
        t.add(modifier: "track") {
            let count = tracker[$0] ?? 0
            tracker[$0] = count + 1
            return $0
        }
        
        let invokesPerItem = 10
        for _ in 0..<(invokesPerItem * animals.count) {
            XCTAssertItemInArray(item: t.expand("#animal.track#"), array: animals)
        }
        
        for key in tracker.keys {
            XCTAssertEqual(tracker[key], invokesPerItem)
        }
    }
    

    func testSettingSelectorForNonExistentRuleHasNoEffectAndGeneratesAWarning() {
        let t = Tracery()
        t.setCandidateSelector(rule: "where", selector: SequentialSelector())
    }
    
}


