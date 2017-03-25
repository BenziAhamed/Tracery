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
        
        checkRule("#.#",         "error: expected modifier name after . in rule ''")
        checkRule("#rule",       "error: closing # not found for rule 'rule'")
        checkRule("#.(#",        "error: expected modifier name after . in rule ''")
        checkRule("#.call(#",    "error: expected ) to close modifier call")
        checkRule("#.call(a,#",  "error: expected ) to close modifier call")
        checkRule("#.call(a,)#", "error: expected parameter after ,")
        checkRule("#[]#",        "")
        checkRule("#[tag]#",     "error: expected : after tag 'tag'")
        checkRule("#[tag:]#",    "error: expected a tag value")
        checkRule("#[tag:#.(]#", "error: expected modifier name after . in rule ''")
        checkRule("[:number]",   "error: expected tag name")
        checkRule("#rule(a,)#",  "error: expected rule candidate after ,")
        checkRule("[tag:a,]",  "error: expected tag value after ,")
    }

    func checkRule(_ target: String, _ prefix: String) {
        let output = Tracery().expand(target)
        print("expanding: \(target)")
        print("\(output)\n")
        XCTAssertTrue(output.hasPrefix(prefix))
    }
}
