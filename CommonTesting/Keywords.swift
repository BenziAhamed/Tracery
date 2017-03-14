//
//  Keywords.swift
//  Tracery
//
//  Created by Benzi on 14/03/17.
//  Copyright © 2017 Benzi Ahamed. All rights reserved.
//

import XCTest
import Tracery

class Keywords: XCTestCase {
    
    let keywords = ["if","then","else"]
    
    func testKeywordCanBeAcceptedAsStandaloneText() {
        let t = Tracery()
        for keyword in keywords {
            XCTAssertEqual(t.expand(keyword), keyword)
        }
    }
    
    func testKeywordCanBeAcceptedAsRuleCandidate() {
        let t = Tracery {[
            "word": keywords
        ]}
        for _ in 0..<keywords.count {
            XCTAssertItemInArray(item: t.expand("#word#"), array: keywords)
        }
    }
    
    
    func testKeywordsCanAppearInRawText() {
        let inputs = [
            "if you know me else now",
            "then we can",
            "if then else",
            "then (me) said if you"
        ]
        let t = Tracery()
        for i in inputs {
            XCTAssertEqual(t.expand(i), i)
        }
    }
    
}
