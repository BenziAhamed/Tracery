//
//  CustomSelectors.swift
//  Tracery
//
//  Created by Benzi on 11/03/17.
//  Copyright © 2017 Benzi Ahamed. All rights reserved.
//

import Foundation
@testable import Tracery

class AlwaysPickFirst : RuleCandidateSelector {
    func pick(count: Int) -> Int {
        return 0
    }
}

class BogusSelector : RuleCandidateSelector {
    func pick(count: Int) -> Int {
        return -1
    }
}

class PickSpecificItem : RuleCandidateSelector {
    
    enum Offset {
        case fromStart(Int)
        case fromEnd(Int)
    }
    
    let offset: Offset
    
    init(offset: Offset) {
        self.offset = offset
    }
    
    func pick(count: Int) -> Int {
        switch offset {
        case let .fromStart(offset):
            return offset
        case let .fromEnd(offset):
            return count - 1 - offset
        }
    }
}



class SequentialSelector : RuleCandidateSelector {
    var i = 0
    func pick(count: Int) -> Int {
        defer {
            i += 1
            if i == count {
                i = 0
            }
        }
        return i
    }
}

class Arc4RandomSelector : RuleCandidateSelector {
    func pick(count: Int) -> Int {
        return Int(arc4random_uniform(UInt32(count)))
    }
}
