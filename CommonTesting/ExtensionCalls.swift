//
//  ExtensionCalls.swift
//  Tracery
//
//  Created by Benzi on 11/03/17.
//  Copyright © 2017 Benzi Ahamed. All rights reserved.
//

import XCTest
@testable import Tracery

class ExtensionCalls: XCTestCase {

    func testCallWithoutBrackets() {
        let t = Tracery()
        
        var invoked = false
        t.add(call: "msg") {
            invoked = true
        }
        
        _ = t.expand("#.msg#")
        XCTAssertTrue(invoked)
    }
    
    func testCallWithBrackets() {
        let t = Tracery()
        
        var invoked = false
        t.add(call: "msg") {
            invoked = true
        }
        
        _ = t.expand("#.msg()#")
        XCTAssertTrue(invoked)
    }

}
