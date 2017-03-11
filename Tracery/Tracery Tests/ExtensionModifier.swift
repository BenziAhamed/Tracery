//
//  ExtensionModifier.swift
//  Tracery
//
//  Created by Benzi on 11/03/17.
//  Copyright © 2017 Benzi Ahamed. All rights reserved.
//

import XCTest
@testable import Tracery

class ExtensionModifier: XCTestCase {
    
    func testNoModifier() {
        let t = Tracery {
            [ "msg" : "hello world" ]
        }
        XCTAssertEqual(t.expand("#msg.no.mods.are.added#"), "hello world")
    }
    
    func testAddingModifier() {
        let t = Tracery {
            [ "msg" : "hello world" ]
        }
        t.add(modifier: "caps") { return $0.uppercased() }
        XCTAssertEqual(t.expand("#msg.caps#"), "hello world".uppercased())
    }
    
    func testAddingModifierAndChainingInvalidModifiersRetainsIntermediateResults() {
        let t = Tracery {
            [ "msg" : "hello world" ]
        }
        t.add(modifier: "caps") { return $0.uppercased() }
        XCTAssertEqual(t.expand("#msg.caps#"), "hello world".uppercased())
        XCTAssertEqual(t.expand("#msg.no.caps#"), "hello world".uppercased())
        XCTAssertEqual(t.expand("#msg.still.caps.goes.here#"), "hello world".uppercased())
    }
    
}

