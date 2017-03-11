//
//  Tags.swift
//  Tracery
//
//  Created by Benzi on 11/03/17.
//  Copyright © 2017 Benzi Ahamed. All rights reserved.
//

import XCTest
@testable import Tracery

class Tags: XCTestCase {
    
    func testTagIsSetWithSingleValue() {
        let t = Tracery {[
            "name": "benzi",
            "msg": "#[tag:#name#]#hello world"
            ]}
        XCTAssertEqual(t.expand("#msg#"), "hello world")
        XCTAssertNotNil(t.tags["tag"])
        XCTAssertTrue(
            t.tags["tag"]?.candidates.count == 1 &&
                t.tags["tag"]?.candidates[0] == "benzi"
        )
    }
    
    func testAllowTagsToOverrideRules() {
        let t = Tracery {[
            "name": "benzi",
            "msg": "#[name:override name]name#"
            ]}
        XCTAssertEqual(t.expand("#msg#"), "override name")
    }
    
    func testAllowTagsToOverrideTags() {
        let t = Tracery {[
            "name": "benzi",
            "msg": "#[name:first time][name:second time]name#"
            ]}
        XCTAssertEqual(t.expand("#msg#"), "second time")
    }
    
    func testAllowTagNesting() {
        let t = Tracery()
        XCTAssertItemInArray(item: t.expand("[[tag1:jack][tag2:jill]tag:#tag1#,#tag2#]#tag#"), array: ["jack", "jill"])
    }
    
    func testTagIsSetWithMultipleValues() {
        let t = Tracery {[
            "name": "benzi",
            "msg": "#[tag:#name#,jack]#hello world"
            ]}
        XCTAssertEqual(t.expand("#msg#"), "hello world")
        XCTAssertNotNil(t.tags["tag"])
        XCTAssertTrue(
            t.tags["tag"]?.candidates.count == 2 &&
                t.tags["tag"]?.candidates[0] == "benzi" &&
                t.tags["tag"]?.candidates[1] == "jack"
        )
    }
    
    func testCreatingTagAndUsingItImmediately() {
        let t = Tracery {[
            "msg": "#[tag:hello world]tag#"
            ]}
        XCTAssertEqual(t.expand("#msg#"), "hello world")
    }
    
    func testTagValueIsAlwaysPickedFromChoicesSpecified() {
        let choices = "jack,jill,jacob,jenny,jeremy,janet,jason,john"
        let t = Tracery {[
            "msg": "#[tag:\(choices)]tag#"
            ]}
        
        let choicesArray = choices.components(separatedBy: ",")
        for _ in 0..<choicesArray.count {
            XCTAssertItemInArray(item: t.expand("#msg#"), array: choicesArray)
        }
    }
    
    func testTagCanBeCreatedFromOtherTagValues() {
        let t = Tracery {[
            "name" : "jack",
            "createTag1" : "[tag1:#name#]#tag1#", // create tag1 and output value
            "createTag2" : "[tag2:#createTag1#]", // trigger tag1 creation
            "msg": "[#createTag2#]#tag2#" // trigger tag2 creation and output tag2
            ]}
        XCTAssertEqual(t.expand("#msg#"), "jack")
    }
    
}

