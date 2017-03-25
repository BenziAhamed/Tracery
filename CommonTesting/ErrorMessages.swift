//
//  ErrorMessages.swift
//  Tracery
//
//  Created by Benzi on 11/03/17.
//  Copyright © 2017 Benzi Ahamed. All rights reserved.
//

import XCTest
@testable import Tracery

class ErrorMessages: XCTestCase {
    
    func testErrorMessages() {
        
        let t = Tracery{[:]}
        
        XCTAssertEqual(t.expand("#rule"),       "error: closing # not found for rule 'rule'")
        XCTAssertEqual(t.expand("#.#"),         "error: expected modifier name after . in rule ''")
        XCTAssertEqual(t.expand("#.(#"),        "error: expected modifier name after . in rule ''")
        XCTAssertEqual(t.expand("#.call(#"),    "error: expected ) to close modifier call")
        XCTAssertEqual(t.expand("#.call(a,#"),  "error: expected ) to close modifier call")
        XCTAssertEqual(t.expand("#.call(a,)#"), "error: expected value after ,")
        XCTAssertEqual(t.expand("#[]#"),        "")
        XCTAssertEqual(t.expand("#[tag]#"),     "error: expected : after tag 'tag'")
        XCTAssertEqual(t.expand("#[tag:]#"),    "error: expected some value")
        XCTAssertEqual(t.expand("#[tag:#.(]#"), "error: expected modifier name after . in rule ''")
        XCTAssertEqual(t.expand("[:number]"),   "error: expected tag name")
    }

    
}
