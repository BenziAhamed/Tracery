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
    
    
    func testModifiersGetCalledInCorrectOrder() {
        let t = Tracery {
            [ "msg" : "new york" ]
        }
        t.add(modifier: "caps") { return $0.uppercased() }
        t.add(modifier: "reversed") { return .init($0.characters.reversed()) }
        t.add(modifier: "kebabed") { return $0.replacingOccurrences(of: " ", with: "-") }
        t.add(modifier: "prefix") { return "!" + $0 }
        
        XCTAssertEqual(t.expand("#msg.caps.reversed.kebabed.prefix#"), "!KROY-WEN")
        XCTAssertEqual(t.expand("#msg.caps.kebabed.reversed.prefix#"), "!KROY-WEN")
        XCTAssertEqual(t.expand("#msg.reversed.prefix.reversed#"), "new york!")
        XCTAssertEqual(t.expand("#msg.prefix.reversed.prefix#"), "!kroy wen!")
        XCTAssertEqual(t.expand("#msg.prefix.reversed.prefix.reversed#"), "!new york!")
    }
    
}

