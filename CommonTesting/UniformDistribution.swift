//
//  UniformDistribution.swift
//  Tracery
//
//  Created by Benzi Ahamed on 24/04/20.
//  Copyright © 2020 Benzi Ahamed. All rights reserved.
//

import XCTest
@testable import Tracery

class UniformDistribution: XCTestCase {

    func testDefaultSelectorHasUniformDistribution() {
        let t = Tracery {[ "o" : "{(h,t)}" ]}
        var headCount = 0
        var tailCount = 0
        let target = [1, 1, 2, 3, 5, 8, 13, 21, 34].randomElement()! * 2
        for _ in 0..<target {
            t.expand("{o}") == "t" ? (tailCount += 1) : (headCount += 1)
        }
        let total = headCount + tailCount
        XCTAssertEqual(headCount, target/2)
        XCTAssertEqual(tailCount, target/2)
        XCTAssertEqual(total, target)
    }

}
