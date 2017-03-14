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
        
        let line = "[if #1#==#1# then [tag:you] else [tag:me]]#tag#"
        print(Lexer.tokens(input: line))
        
        Tracery.logLevel = .verbose
        let t = Tracery.hierarchical()
        print(t.expand(line))
        
    }
    
}
