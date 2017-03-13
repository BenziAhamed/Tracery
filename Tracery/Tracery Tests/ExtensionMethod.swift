//
//  ExtensionMethod.swift
//  Tracery
//
//  Created by Benzi on 11/03/17.
//  Copyright © 2017 Benzi Ahamed. All rights reserved.
//

import XCTest
@testable import Tracery

class ExtensionMethod: XCTestCase {
    
    func testNoMethod() {
        let t = Tracery {
            [ "msg" : "hello world" ]
        }
        XCTAssertEqual(t.expand("#msg.call()#"), "hello world")
        XCTAssertEqual(t.expand("#msg.me()#"), "hello world")
        XCTAssertEqual(t.expand("#msg.maybe()#"), "hello world")
        XCTAssertEqual(t.expand("#msg.you().know()#"), "hello world")
    }
    
    func testMethodCanReceiveComplexParameters() {
        let t = Tracery {[
            "msg" : "hello"
        ]}
        t.add(method: "combine") { input, args in
            return args.joined(separator: "-")
        }
        XCTAssertEqual(t.expand("#.combine(#msg#)#"), "hello")
        XCTAssertEqual(t.expand("#.combine(#msg# world)#"), "hello world")
        XCTAssertEqual(t.expand("#.combine(#msg# world,!)#"), "hello world-!")
        XCTAssertEqual(t.expand("#.combine(why,#msg# world)#"), "why-hello world")
        XCTAssertEqual(t.expand("#.combine(why,#msg# world,!)#"), "why-hello world-!")
    }
    
    func testMethod() {
        let t = Tracery {
            [ "msg" : "hello world" ]
        }
        t.add(method: "call") { input, args in
            XCTAssertEqual(input, "hello world")
            return input
        }
        XCTAssertEqual(t.expand("#msg.call()#"), "hello world")
    }
    
    func testMethodReceivesInputArguments() {
        let t = Tracery {
            [ "msg" : "hello world" ]
        }
        t.add(method: "call") { input, args in
            XCTAssertEqual(input, "hello world")
            XCTAssertEqual(args.count, 1)
            XCTAssertEqual(args[0], "me")
            return input
        }
        XCTAssertEqual(t.expand("#msg.call(me)#"), "hello world")
    }
    
    func testMethodReceivesInputArgumentsWithRulesExpanded() {
        let t = Tracery {[
            "msg" : "hello world",
            "arg1": "this is cool",
            "arg2": "this is also cool",
            "arg3": "#arg4#",
            "arg4": "yes i am arg4",
            ]}
        t.add(method: "call") { input, args in
            XCTAssertEqual(input, "hello world")
            XCTAssertEqual(args.count, 4)
            XCTAssertEqual(args[0], "this is cool")
            XCTAssertEqual(args[1], "this is also cool")
            XCTAssertEqual(args[2], "yes i am arg4")
            XCTAssertEqual(args[3], "arg4")
            return input
        }
        XCTAssertEqual(t.expand("#msg.call(#arg1#,#arg2#,#arg3#,arg4)#"), "hello world")
    }
    
    func testMethodGetsCalledAlways() {
        let t = Tracery {
            [ "msg" : "hello world" ]
        }
        
        var callCount = 0
        t.add(method: "call") { input, args in
            XCTAssertEqual(input, "hello world")
            callCount += 1
            return input
        }
        
        let target = 10
        for _ in 0..<target {
            XCTAssertEqual(t.expand("#msg.call()#"), "hello world")
        }
        
        XCTAssertEqual(callCount, target)
    }
    
    func testChainedMethodGetsCalledAlways() {
        let t = Tracery {
            [ "msg" : "hello world" ]
        }
        
        var callCount = 0
        t.add(method: "call") { input, args in
            XCTAssertEqual(input, "hello world")
            callCount += 1
            return input
        }
        
        let target = 7
        let input = "#msg\(String(repeating: ".call()", count: target))#"
        XCTAssertEqual(t.expand(input), "hello world")
        XCTAssertEqual(callCount, target)
    }
    
}

