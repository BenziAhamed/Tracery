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
    
    
    //
    // Hierarchical tag storage is present in Tracery
    // as a consequence of issue 31
    //
    // https://github.com/galaxykate/tracery/issues/31
    //
    func testIssue31_HierarchicalTagsAllowBracesMatchingCrossingRuleLevels() {
        let o = TraceryOptions()
        o.tagStorageType = .heirarchical
        
        let braces = ["()","{}","<>","«»","𛰫𛰬","⌜⌝","ᙅᙂ","ᙦᙣ","⁅⁆","⌈⌉","⌊⌋","⟦⟧","⦃⦄","⦗⦘","⫷⫸"]
        let braceTypes = braces
            .map { braces -> String in
                let open = braces[braces.startIndex]
                let close = braces[braces.index(after: braces.startIndex)]
                return "[open:\(open)][close:\(close)]"
            }
        
        let t = Tracery(o) {[
            "letter": ["A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P"],
            "bracetypes": braceTypes,
            "brace": [
                "#open##symbol# #origin##symbol##close# ",
                "#open##symbol##close# #origin# #open##symbol##close#",
                "#open##symbol# #origin##symbol##close# #origin#",
                "",
            ],
            "origin": ["#[symbol:#letter#][#bracetypes#]brace#"]
        ]}
        
        // Tracery.logLevel = .verbose
        let output = t.expand("#origin#")
        
        XCTAssertFalse(output.contains("stack overflow"))
        
        // track open and close
        // of each brace
        var stackOfBraces = [Character]()
        func trackBraces(_ c: Character) {
            braces
                .filter {
                    $0.range(of: "\(c)") != nil
                }
                .forEach {
                    let leftBrace = $0.characters[$0.characters.startIndex]
                    if leftBrace == c {
                        stackOfBraces.append(c)
                    }
                    else {
                        let expected = stackOfBraces.popLast()
                        XCTAssertNotNil(expected)
                        XCTAssertEqual(expected!, leftBrace)
                    }
                }
        }
        output.characters.forEach { trackBraces($0) }
        XCTAssertEqual(stackOfBraces.count, 0)
        
    }
}
