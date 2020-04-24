//
//  InlineRules.swift
//  Tracery Tests iOS
//
//  Created by Benzi Ahamed on 23/04/20.
//  Copyright © 2020 Benzi Ahamed. All rights reserved.
//

import XCTest
@testable import Tracery

class InlineRules: XCTestCase {

    func testAnonymousInlineRulesAreWorkWithHash() {
        XCTAssertEqual(Tracery().expand("#(1)#"), "1")
    }
    
    func testAnonymousInlineRulesAreWorkWithCurlies() {
        XCTAssertEqual(Tracery().expand("{(1)}"), "1")
    }
    
    
    func testAnonymousInlineRulesAreWorkWithChoice() {
        XCTAssertItemInArray(item: Tracery().expand("{(1,2,3,4)}"), array: ["1","2","3","4"])
    }
    
    func testNamedInlineRulesAreWork1() {
        XCTAssertEqual(Tracery().expand("{item(1)}{item}"), "1")
    }
    
    func testNamedInlineRulesAreWork2() {
        XCTAssertEqual(Tracery().expand("#item(1)#{item}"), "1")
    }
    
    func testNamedInlineRulesAreWork3() {
        XCTAssertEqual(Tracery().expand("{item(1)}#item#"), "1")
    }

    func testInlineRulesCanBeCleared() {
        XCTAssertEqual(Tracery().expand("{b(0)}{b}{b()}{b}"), "0")
    }
    
    func testInlineRulesAllowDynamicTags() {
        XCTAssertEqual(Tracery().expandVerbose("{([tag:0]{tag})}"), "0")
    }

}
