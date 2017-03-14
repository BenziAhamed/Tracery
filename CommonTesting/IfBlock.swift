//
//  IfBlock.swift
//  Tracery
//
//  Created by Benzi on 14/03/17.
//  Copyright © 2017 Benzi Ahamed. All rights reserved.
//

import XCTest
@testable import Tracery

class IfBlock: XCTestCase {
    
    func testIfBlock() {
        
        let line = "[if #condition# == #option# then #lemon# else [tag:me]]"
        print(Lexer.tokens(input: line))
        
        Tracery.logLevel = .verbose
        let t = Tracery()
        print(t.expand(line))
        
    }
    
}
