//
//  Helpers.swift
//  Tracery
//
//  Created by Benzi on 11/03/17.
//  Copyright © 2017 Benzi Ahamed. All rights reserved.
//

import Foundation
import XCTest
@testable import Tracery

func XCTAssertItemInArray<T: Comparable>(item: T, array: [T]) {
    XCTAssert(array.contains(item), "\(item) was not found in \(array)")
}

extension Array {
    
    func regexGenerateMatchesAnyItemPattern() -> String {
        return "(" + self.map { "\($0)" }.joined(separator: "|") + ")"
    }
    
}

extension Sequence {
    
    func mapDict<Key: Hashable,Value>(_ transform:(Iterator.Element)->(Key, Value)) -> Dictionary<Key, Value> {
        var d = Dictionary<Key, Value>()
        forEach {
            let (k,v) = transform($0)
            d[k] = v
        }
        return d
    }
    
    @discardableResult
    func scan<T>(_ initial: T, _ combine: (T, Iterator.Element) throws -> T) rethrows -> [T] {
        var accu = initial
        return try map { e in
            accu = try combine(accu, e)
            return accu
        }
    }
}



extension Tracery {
    
    class func hierarchical(rules: ()->[String:Any]) -> Tracery {
        let options = TraceryOptions()
        options.tagStorageType = .heirarchical
        return Tracery.init(options, rules: rules)
    }
    
    class func hierarchical() -> Tracery {
        return hierarchical {[:]}
    }
    
    func expandVerbose(_ text: String) -> String {
        Tracery.logLevel = .verbose
        defer {
            Tracery.logLevel = .errors
        }
        return self.expand(text)
    }
    
}
