//
//  TagStorage.swift
//  Tracery
//
//  Created by Benzi on 12/03/17.
//  Copyright © 2017 Benzi Ahamed. All rights reserved.
//

import Foundation

struct TagMapping {
    let candidates: [String]
    let selector: RuleCandidateSelector
}

extension TagMapping : CustomStringConvertible {
    var description: String {
        return candidates.joined(separator: ",")
    }
}

protocol TagStorage {
    var tracery:Tracery? { get set }
    mutating func store(name: String, tag: TagMapping)
    func get(name: String) -> TagMapping?
    mutating func removeAll()
}

public enum TaggingPolicy {
    case unilevel
    case heirarchical
    
    func storage() -> TagStorage {
        switch self {
        case .unilevel:  return UnilevelTagStorage()
        case .heirarchical: return HierarchicalTagStorage()
        }
    }
}


// simple tag storage - entries are 
// stored in a plain list
struct UnilevelTagStorage : TagStorage {
    private var storage:[String: TagMapping]
    weak var tracery:Tracery? = nil
    init() {
        self.storage = [String: TagMapping]()
    }
    mutating func store(name: String, tag: TagMapping) {
        storage[name] = tag
    }
    func get(name: String) -> TagMapping? {
        guard let mapping = storage[name] else { return nil }
        return mapping
    }
    mutating func removeAll() {
        storage.removeAll()
    }
}

// tags are scoped by stack depth level
// new tags are stored at the current level
// existing tags are retrieved from current level
// if present, else levels are decremented
// until a tag is found
struct HierarchicalTagStorage : TagStorage {
    weak var tracery: Tracery? = nil
    var storage = [Int : UnilevelTagStorage]()
    mutating func store(name: String, tag: TagMapping) {
        guard let t = tracery else { return }
        if storage[t.ruleEvaluationLevel] == nil {
            var levelStorage = UnilevelTagStorage()
            levelStorage.tracery = tracery
            storage[t.ruleEvaluationLevel] = levelStorage
        }
        storage[t.ruleEvaluationLevel]!.store(name: name, tag: tag)
    }
    func get(name: String) -> TagMapping? {
        guard let t = tracery else { return nil }
        var level = t.ruleEvaluationLevel
        while level >= 0 {
            if let tag = storage[level]?.get(name: name) {
                return tag
            }
            level -= 1
        }
        return nil
    }
    mutating func removeAll() {
        storage.removeAll()
    }
}
