//
//  Keywords.swift
//  Tracery
//
//  Created by Benzi on 14/03/17.
//  Copyright © 2017 Benzi Ahamed. All rights reserved.
//

import XCTest
@testable import Tracery

class Keywords: XCTestCase {
    
    let keywords = ["if","then","else","do","while","not in","in"]
    
    func testKeywordCanBeAcceptedAsStandaloneText() {
        let t = Tracery()
        for keyword in keywords {
            XCTAssertEqual(t.expand(keyword), keyword)
        }
    }
    
    func testKeywordCanBeAcceptedAsRuleCandidate() {
        let t = Tracery {[
            "word": keywords
        ]}
        for _ in 0..<keywords.count {
            XCTAssertItemInArray(item: t.expand("#word#"), array: keywords)
        }
    }
    
    
    func testKeywordsCanAppearInRawText() {
        let inputs = [
            "if you know me else now",
            "then we can",
            "if then else",
            "then (me) said if you"
        ]
        let t = Tracery()
        for i in inputs {
            XCTAssertEqual(t.expand(i), i)
        }
    }
    
    func testKeywordsMustBePrecededAndSucceededBySpaces() {
        keywords.forEach {
            XCTAssertEqual(Lexer.tokens(" \($0) "), [Token.SPACE, Token.keyword($0), Token.SPACE])
        }
    }
    
    func testKeywordsOnlyIfAndThenCanBePrecededByLeftSquareBracket() {
        
        XCTAssertEqual(Lexer.tokens("[if "), [Token.LEFT_SQUARE_BRACKET, Token.keyword("if"), Token.SPACE])
        XCTAssertEqual(Lexer.tokens("[while "), [Token.LEFT_SQUARE_BRACKET, Token.keyword("while"), Token.SPACE])
        
        keywords.filter{ !["if","while","not in"].contains($0) }.forEach {
            XCTAssertEqual(Lexer.tokens("[\($0) "), [Token.LEFT_SQUARE_BRACKET,Token.text("\($0) ")])
        }
    }
    
}
