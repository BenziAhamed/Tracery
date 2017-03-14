//
//  Conditionals.swift
//  Tracery
//
//  Created by Benzi on 14/03/17.
//  Copyright © 2017 Benzi Ahamed. All rights reserved.
//

import XCTest
@testable import Tracery

class Conditionals: XCTestCase {
    
    func testBasicIfBlockWorks() {
        
//        Tracery.logLevel = .verbose
        
        let t = Tracery {[
            "name": ["benzi"]
        ]}
        
        XCTAssertEqual(t.expand("[if #name#==benzi     then ok]"), "")
        
        XCTAssertEqual(t.expand("[if #name# == benzi then ok]"), "ok")
        XCTAssertEqual(t.expand("[if #name#== benzi then ok]"), "ok")
        XCTAssertEqual(t.expand("[if #name#==benzi then ok]"), "ok")
        XCTAssertEqual(t.expand("[if #name#==benzithen ok]"), "ok")
        
        XCTAssertEqual(t.expand("[if #name# == benzi then ok else not-ok]"), "ok")
        XCTAssertEqual(t.expand("[if #name# != danny then ok else not-ok]"), "ok")

    }
    
    func testIfBlockWorksWithTags() {
        
        Tracery.logLevel = .verbose
        
        let t = Tracery {[
            "name": ["benzi"]
            ]}
        
        XCTAssertEqual(t.expand("[tag:#name#][if #tag# == benzi then ok]"), "ok")
        XCTAssertEqual(t.expand("[tag:#name#][if #tag# != benzi then not-ok else ok]"), "ok")
        
    }
    
}
