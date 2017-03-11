//
//  TraceryioSamples.swift
//  Tracery
//
//  Created by Benzi on 11/03/17.
//  Copyright © 2017 Benzi Ahamed. All rights reserved.
//

import XCTest
@testable import Tracery

class TraceryioSamples: XCTestCase {
    
    func testDefaultAnimalExpansions() {
        let animals = ["unicorn","raven","sparrow","scorpion","coyote","eagle","owl","lizard","zebra","duck","kitten"]
        let t = Tracery {
            [ "animal" : animals]
        }
        for _ in 0..<animals.count {
            XCTAssertItemInArray(item: t.expand("#animal#"), array: animals)
        }
    }
    
    func testDefaultRulesWithinRules() {
        let colors = ["orange","blue","white","black","grey","purple","indigo","turquoise"]
        let animals = ["unicorn","raven","sparrow","scorpion","coyote","eagle","owl","lizard","zebra","duck","kitten"]
        let natureNouns = ["ocean","mountain","forest","cloud","river","tree","sky","sea","desert"]
        let names = ["Arjun","Yuuma","Darcy","Mia","Chiaki","Izzi","Azra","Lina"]
        
        let t = Tracery{[
            "sentence": ["The #color# #animal# of the #natureNoun# is called #name#"],
            "color": colors,
            "animal": animals,
            "natureNoun": natureNouns,
            "name": names
            ]}
        
        let pattern = "^The \(colors.regexGenerateMatchesAnyItemPattern()) \(animals.regexGenerateMatchesAnyItemPattern()) of the \(natureNouns.regexGenerateMatchesAnyItemPattern()) is called \(names.regexGenerateMatchesAnyItemPattern())$"
        let regex = try? NSRegularExpression(pattern: pattern, options: .useUnixLineSeparators)
        let output = t.expand("#sentence#")
        let match = regex?.firstMatch(in: output, options: NSRegularExpression.MatchingOptions.anchored, range: .init(location: 0, length: output.characters.count))
        
        XCTAssertNotNil(match?.numberOfRanges)
        XCTAssertEqual(match!.numberOfRanges, 5)
    }
    
}
