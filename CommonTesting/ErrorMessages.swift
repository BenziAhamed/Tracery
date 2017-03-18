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
        XCTAssertEqual(t.expand("#.#"),         "error: expected modifier name after . for rule '', but got: '#' near '#.'")
        XCTAssertEqual(t.expand("#.(#"),        "error: expected modifier name after . for rule '', but got: '(' near '#.'")
        XCTAssertEqual(t.expand("#.call(#"),    "error: expected ) to close modifier call")
        XCTAssertEqual(t.expand("#.call(a,#"),  "error: expected ) to close modifier call")
        XCTAssertEqual(t.expand("#.call(a,)#"), "error: parameter expected, but not found in modifier 'call'")
        XCTAssertEqual(t.expand("#[]#"),        "error: empty [] not allowed")
        XCTAssertEqual(t.expand("#[tag]#"),     "error: tag 'tag' must be followed by a :")
        XCTAssertEqual(t.expand("#[tag:]#"),    "error: value expected for tag 'tag', but none found")
        XCTAssertEqual(t.expand("#[tag:#.(]#"), "error: unable to parse value '#.(' for tag 'tag' reason - expected modifier name after . for rule '', but got: '(' near '#.'")
        XCTAssertEqual(t.expand("[:number]"),   "error: expected a tag name, but got: ':' near '['")
        XCTAssertEqual(t.expand("["),           "error: expected a tag name")

    }

    
}
