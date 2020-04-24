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
    
    func testDefaultStorageIsUnilevel() {
        let t = Tracery()
        XCTAssertEqual(t.options.tagStorageType, .unilevel)
    }
    
    func testTagsWork() {
        let t = Tracery()
        XCTAssertEqual(t.expandVerbose("[tag:value]#tag#"), "value")
        XCTAssertEqual(t.expandVerbose("{[tag:value]tag}"), "value")
    }
    
    func testUnilevelTagsCanBeSet() {
        let t = Tracery {[
            "outside_rule" : "[tag:value]#tag#",
            "inside_rule" : "#[tag:value]tag#",
            ]}
        t.ruleNames.forEach { rule in
            XCTAssertEqual(t.expand("#\(rule)#"), "value")
        }
    }
    
    func testTagIsSetWithSingleValue() {
        let t = Tracery {[
            "name": "benzi",
            "msg": "#[tag:#name#]#hello world #tag#"
            ]}
        XCTAssertEqual(t.expand("#msg#"), "hello world benzi")
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
            "msg": "[tag:#name#,jack]#tag#"
            ]}

        // Tracery.logLevel = .verbose
        
        let value1 = t.expand("#msg#")
        let value2 = t.expand("#msg#")
        
        XCTAssertItemInArray(item: value1, array: ["benzi", "jack"])
        XCTAssertItemInArray(item: value2, array: ["benzi", "jack"])
        
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
    
    
    func testTagValuesCanBeRuleCandidates() {
        
        let t = Tracery {[
            "msg1": "hello",
            "msg2": "world",
            "msg": "[tag1:#msg1# #msg2#][tag:#tag1.surprised#]#tag.caps#"
        ]}
        
        t.add(modifier: "surprised") { return $0 + "!" }
        t.add(modifier: "caps") { return $0.uppercased() }
        
        XCTAssertEqual(t.expand("#msg#"), "HELLO WORLD!")
        
    }

    func testTagsCanBeSetInsideAnonymousRules() {
        XCTAssertEqual("hello", Tracery().expand("{([tag:hello]{tag})}"))
    }
    
    
    func testTagsCanBeSetInsideNamedRules() {
        XCTAssertEqual("hello", Tracery().expand("{rule([tag:hello]{tag})}{rule}"))
    }

    
}


// MARK:- Hierarchical tag storage tests

extension Tags {
    
    private func hierarchicalTracery(rules: ()->[String: Any]) -> Tracery {
        let options = TraceryOptions()
        options.tagStorageType = .heirarchical
        let t = Tracery(options, rules: rules)
        return t
    }
    
    func testHierarchicalTagsDoNotOverrideAtDifferentLevels() {
        let t = hierarchicalTracery {[
            "origin" : "[tag:level-0][#level1#]#tag#",
            "level1" : "[tag:level-1]#tag# [#level2#]",
            "level2" : "[tag:level-2]#tag# ",
            ]}
        XCTAssertEqual(t.expand("#origin#"), "level-1 level-2 level-0")
    }
    
    func testHierarchicalTagsOverrideAtSameLevels() {
        let t = hierarchicalTracery {[
            "origin" : "[tag:level-0][#level-1A#][#level-1B#]#tag#",
            "level-1A" : "[tag:level-1A]#tag# ",
            "level-1B" : "[tag:level-1B]#tag# ",
        ]}
        XCTAssertEqual(t.expand("#origin#"), "level-1A level-1B level-0")
    }
    
    func testHierarchicalTagsStoredAndReadAtSameLevel() {
        let t = hierarchicalTracery {[
            "origin" : "[tag:level-0]#tag#",
            ]}
        XCTAssertEqual(t.expand("#origin#"), "level-0")
    }
    
    func testHierarchicalTagsCanRetrieveTagValuesFromLowerLevels() {
        let t = hierarchicalTracery {[
            "origin" : "[tag:root]#level-1#",
            "level-1" : "L1=#tag#, #level-2#",
            "level-2" : "L2=#tag#",
        ]}
        XCTAssertEqual(t.expand("#origin#"), "L1=root, L2=root")
    }
    
    func testHierarchicalTagsCannotRetrieveTagValuesFromUpperLevels() {
        let t = hierarchicalTracery {[
            "origin" : "[tag:root]#level-1#",
            "level-1" : "L1=#tag#, #level-2#",
            "level-2" : "[#level-3#]L2=#tag#, #L3#",
            "level-3" : "[L3:do_not_print]"
            ]}
        XCTAssertEqual(t.expand("#origin#"), "L1=root, L2=root, {L3}")
    }
    
    func testHierarchicalTagsCanBeSet() {
        let t = hierarchicalTracery {[
            "outside_rule" : "[tag:value]#tag#",
            "inside_rule" : "#[tag:value]tag#",
            "override_in_same_rule1": "[tag:value-out ]#[tag:value-in ]tag##tag#",
            "override_in_same_rule2": "[tag:value-out ]#tag##[tag:value-in ]tag#",
            "sub_tag_not_visible" : "[#sub_tag#]#tag2#",
            "sub_tag" : "[tag2:sub tag]"
        ]}

        XCTAssertEqual(t.expand("#outside_rule#"), "value")
        XCTAssertEqual(t.expand("#inside_rule#"), "value")
        XCTAssertEqual(t.expand("#override_in_same_rule1#"), "value-in value-in ")
        XCTAssertEqual(t.expand("#override_in_same_rule2#"), "value-out value-in ")
        XCTAssertEqual(t.expand("#sub_tag_not_visible#"), "{tag2}")
    }

    
}
