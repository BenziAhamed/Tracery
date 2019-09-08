//
//  CandidateProvider.swift
//  Tracery
//
//  Created by Benzi on 11/03/17.
//  Copyright © 2017 Benzi Ahamed. All rights reserved.
//

import XCTest
@testable import Tracery

class CandidateProvider: XCTestCase {
    
    
    func testRuleCandidateProvidedCandidatesAreUsed() {
        class AnimalsProvider : RuleCandidatesProvider {
            let candidates = ["unicorn","raven","sparrow","scorpion","coyote","eagle","owl","lizard","zebra","duck","kitten"]
        }
        let provider = AnimalsProvider()
        let t = Tracery { ["animal": provider] }
        for _ in 0..<provider.candidates.count {
            XCTAssertItemInArray(item: t.expand("#animal#"), array: provider.candidates)
        }
    }
    
    
    func testProviderThatIsAlsoASelector() {
        class Provider : RuleCandidatesProvider, RuleCandidateSelector {
            var invokeCount = 0
            let candidates = ["jack","jill"]
            func pick(count: Int) -> Int {
                invokeCount += 1
                return Int.random(in: 0..<2)
            }
        }
        
        let nameProvider = Provider()
        let t = Tracery {[
            "name": nameProvider
        ]}
        
        
        let callLimit = 10
        
        for _ in 0..<callLimit {
            XCTAssertItemInArray(item: t.expand("#name#"), array: nameProvider.candidates)
        }
        
        XCTAssertEqual(nameProvider.invokeCount, callLimit)
        
    }
    
    func testWeightedCandidateProvider() {
        
        let t = Tracery {[
            "binary": WeightedCandidateSet([
                "0#binary#": 10,
                "1#binary#": 10,
                "":  1
                ])
            ]}
        
        XCTAssertTrue(!t.expand("#binary#").contains("stack overflow"))
    }
}
