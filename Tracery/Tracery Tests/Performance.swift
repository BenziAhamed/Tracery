//
//  Performance.swift
//  Tracery
//
//  Created by Benzi on 11/03/17.
//  Copyright © 2017 Benzi Ahamed. All rights reserved.
//

import XCTest
@testable import Tracery

class Performance: XCTestCase {

//    func testPerformanceOfStoryGrammarFromTraceryIO() {
//        self.measure {
//            let t = Tracery {[
//                "name": ["Arjun","Yuuma","Darcy","Mia","Chiaki","Izzi","Azra","Lina"]
//                ,	"animal": ["unicorn","raven","sparrow","scorpion","coyote","eagle","owl","lizard","zebra","duck","kitten"]
//                ,	"occupationBase": ["wizard","witch","detective","ballerina","criminal","pirate","lumberjack","spy","doctor","scientist","captain","priest"]
//                ,	"occupationMod": ["occult ","space ","professional ","gentleman ","erotic ","time ","cyber","paleo","techno","super"]
//                ,	"strange": ["mysterious","portentous","enchanting","strange","eerie"]
//                ,	"tale": ["story","saga","tale","legend"]
//                ,	"occupation": ["#occupationMod##occupationBase#"]
//                ,	"mood": ["vexed","indignant","impassioned","wistful","astute","courteous"]
//                ,	"setPronouns": ["[heroThey:they][heroThem:them][heroTheir:their][heroTheirs:theirs]","[heroThey:she][heroThem:her][heroTheir:her][heroTheirs:hers]","[heroThey:he][heroThem:him][heroTheir:his][heroTheirs:his]"]
//                ,	"setSailForAdventure": ["set sail for adventure","left #heroTheir# home","set out for adventure","went to seek #heroTheir# forture"]
//                ,	"setCharacter": ["[#setPronouns#][hero:#name#][heroJob:#occupation#]"]
//                ,	"openBook": ["An old #occupation# told #hero# a story. 'Listen well' she said to #hero#, 'to this #strange# #tale#. ' #origin#'","#hero# went home.","#hero# found an ancient book and opened it.  As #hero# read, the book told #strange.a# #tale#: #origin#"]
//                ,	"story": ["#hero# the #heroJob# #setSailForAdventure#. #openBook#"]
//                ,	"origin": ["Once upon a time, #[#setCharacter#]story#"]
//                ]}
//            _ = t.expand("#origin")
//        }
//    }
//    
//    
//    func testPerformanceOfMaxDepthCall() {
//        func create(length: Int) -> Tracery {
//            // create some candidates that recurse
//            var candidates = [String]()
//            for i in 0..<length-1 {
//                candidates.append("\(i) #rule#")
//            }
//            // add a candidate that will escape out
//            // of the recursion
//            candidates.append("\(length-1)")
//            
//            // rule : 0 #rule#, 1 #rule#, ... , n-1 #rule#, n
//            // where n = stack limit
//            let t = Tracery {[
//                "rule" : candidates
//                ]}
//            
//            // force sequential selection
//            // to allow maximum expansion of rules
//            t.setCandidateSelector(rule: "rule", selector: SequentialSelector())
//            
//            return t
//        }
//        
//        self.measure {
//            let t = create(length: Tracery.maxStackDepth-1)
//            _ = t.expand("#rule")
//        }
//    }

}
