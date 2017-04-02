//
//  CyclicReferenceIdentifier.swift
//  Tracery
//
//  Created by Benzi on 10/03/17.
//  Copyright © 2017 Benzi Ahamed. All rights reserved.
//

import Foundation

class CyclicReferenceIdentifier : RulesetAnalyser {
    
    class Vertex: GraphIndexAddressable {
        var graphIndex: Int = -1
        var rule: String
        init(_ rule: String) {
            self.rule = rule
        }
    }
    
    var vLookup = [String: Vertex]()
    fileprivate let g = Graph<Vertex>()
    
    func getVertex(_ name: String) -> Vertex {
        func createVertex(name: String) -> Vertex {
            let v = Vertex(name)
            vLookup[v.rule] = v
            g.addVertex(v)
            return v
        }
        return vLookup[name] ?? createVertex(name: name)
    }
    
    func addEdge(_ v: Vertex, _ w: Vertex) {
        // add unique edges only
        if g.edges.contains(where: { $0.0 == v.graphIndex && $0.1 == w.graphIndex }) {
            return
        }
        g.addEdge(v, w)
    }
    
    
    func addRuleDependency(from vertex: Vertex, to condition: ParserCondition) {
        condition.lhs.forEach {
            addRuleDependency(from: vertex, to: $0)
        }
        condition.rhs.forEach {
            addRuleDependency(from: vertex, to: $0)
        }
    }
    
    func addRuleDependency(from vertex: Vertex, to parserNode: ParserNode) {
        switch parserNode {
        case let .rule(name, mods):
            // rule may just contain mods
            if !name.isEmpty {
                addEdge(vertex, getVertex(name))
            }
            // analyse mods further since
            // it may contain parameters
            // that are rules
            mods.forEach { mod in
                mod.parameters.forEach { param in
                    param.nodes.forEach { node in
                        addRuleDependency(from: vertex, to: node)
                    }
                }
            }
            
        case let .tag(_, values):
            // process all values that a tag
            // can expand to
            values.forEach { value in
                value.nodes.forEach { node in
                    addRuleDependency(from: vertex, to: node)
                }
            }
            
        case let .ifBlock(condition, thenBlock, elseBlock):
            addRuleDependency(from: vertex, to: condition)
            thenBlock.forEach { addRuleDependency(from: vertex, to: $0) }
            elseBlock?.forEach { addRuleDependency(from: vertex, to: $0) }
            
        case let .whileBlock(condition, doBlock):
            addRuleDependency(from: vertex, to: condition)
            doBlock.forEach { addRuleDependency(from: vertex, to: $0) }
            
        default:
            break
        }
    }
    
    func visit(rule: String, mapping: RuleMapping) {
        let v = getVertex(rule)
        for candidate in mapping.candidates {
            for node in candidate.value.nodes {
                addRuleDependency(from: v, to: node)
            }
        }
    }
    
    func end() {
        
        // cycles of length 2 is possible only for a loop with 1 vertex
        // this means that a rule references itself, since we are analysing
        // those separately, we exclude such cycles
        
        let cycles = g.findCycles().filter{ $0.count > 2 }
        guard cycles.count > 0 else { return }
        
        warn("cyclic references were detected in the following rules:")
        cycles.forEach { cycle in
            let layout = cycle.flatMap { $0.rule }.joined(separator: " -> ")
            warn("      \(layout)")
        }
        
        
    }
    
}




// MARK:- Graph Theory

fileprivate protocol GraphIndexAddressable : class {
    var graphIndex: Int { get set }
}

fileprivate class Graph<Vertex> where Vertex: GraphIndexAddressable {
    var vertices = [Vertex]()
    var edges = [(u:Int, v:Int)]()
}

// MARK: vertices
extension Graph {
    func addVertex(_ v: Vertex) {
        v.graphIndex = vertices.count
        vertices.append(v)
    }
    func addVertices(_ vertices: Vertex...) {
        for v in vertices {
            addVertex(v)
        }
    }
    func getVertex(index: Int) -> Vertex? {
        return vertices.first(where: { $0.graphIndex == index })
    }
}

// MARK: edges
extension Graph {
    func addEdge(_ v: Vertex, _ w: Vertex) {
        assert(v.graphIndex < vertices.count)
        assert(w.graphIndex < vertices.count)
        edges.append((v.graphIndex, w.graphIndex))
    }
    func successors(of vertex: Vertex) -> [Int] {
        return edges.filter { $0.u == vertex.graphIndex }.map { $0.v }
    }
}

// MARK: functional
extension Graph {
    func map<T: GraphIndexAddressable>(_ transform: (Vertex) -> T) -> Graph<T> {
        let g = Graph<T>()
        g.vertices = self.vertices.map {
            let v = transform($0)
            v.graphIndex = $0.graphIndex
            return v
        }
        g.edges = self.edges
        return g
    }
    func filter(_ isIncluded: (Vertex)->Bool) -> Graph<Vertex> {
        let g = Graph()
        g.vertices = self.vertices.filter(isIncluded)
        let allowedIndices = g.vertices.map { $0.graphIndex }
        g.edges = self.edges.filter { edge in
            return allowedIndices.contains(edge.u) && allowedIndices.contains(edge.v)
        }
        return g
    }
}

fileprivate class TarjanVertex<Vertex> : GraphIndexAddressable {
    var graphIndex: Int = -1
    let vertex: Vertex
    var index = -1
    var lowlink = -1
    var onStack = false
    init(vertex: Vertex) {
        self.vertex = vertex
    }
}

fileprivate class StronglyConnectedComponent<Vertex> where Vertex: GraphIndexAddressable {
    var vertices = [Vertex]()
    var leastGraphIndex: Int {
        return vertices.flatMap{ $0.graphIndex }.min()!
    }
}

// https://en.wikipedia.org/wiki/Tarjan's_strongly_connected_components_algorithm
fileprivate struct TarjanAlgorithm {
    
    static func findStronglyConnectedComponents<Vertex: GraphIndexAddressable>(graph: Graph<Vertex>) -> [StronglyConnectedComponent<Vertex>] {
        
        var index = 0
        var g = graph.map(TarjanVertex.init)
        var s = [TarjanVertex<Vertex>]()
        var components = [StronglyConnectedComponent<Vertex>]()
        
        func strongConnect(_ v: TarjanVertex<Vertex>) {
            
            // Set the depth index for v to the smallest unused index
            v.index = index
            v.lowlink = index
            index += 1
            
            s.append(v)
            v.onStack = true
            
            // Consider successors of v
            for w in g.successors(of: v).flatMap({ g.getVertex(index: $0) }) {
                
                if w.index == -1 {
                    // Successor w has not yet been visited; recurse on it
                    strongConnect(w)
                    v.lowlink = min(v.lowlink, w.lowlink)
                }
                else if w.onStack {
                    // Successor w is in stack S and hence in the current SCC
                    v.lowlink = min(v.lowlink, w.lowlink)
                }
            }
            
            // If v is a root node, pop the stack and generate an SCC
            if (v.lowlink == v.index) {
                // start a new strongly connected component
                let scc = StronglyConnectedComponent<Vertex>()
                while true {
                    let w = s.removeLast()
                    w.onStack = false
                    scc.vertices.append(w.vertex)
                    if w.graphIndex == v.graphIndex {
                        break
                    }
                }
                // output the current strongly connected component
                components.append(scc)
            }
        }
        
        for v in g.vertices {
            if v.index == -1 {
                strongConnect(v)
            }
        }
        
        return components
        
    }
}

extension Graph {
    func findStronglyConnectedComponents() -> [StronglyConnectedComponent<Vertex>] {
        return TarjanAlgorithm.findStronglyConnectedComponents(graph: self)
    }
}


// http://www.cs.tufts.edu/comp/150GA/homeworks/hw1/Johnson%2075.PDF
fileprivate struct JohnsonCircuitFindingAlgorithm {
    
    struct Blist {
        var items = [Int]()
        init() { }
        mutating func add(item: Int) {
            items.append(item)
        }
        mutating func remove(item: Int) {
            if let i = items.index(where: {$0 == item}) {
                items.remove(at: i)
            }
        }
    }
    
    static func findCycles<Vertex>(graph: Graph<Vertex>) -> [[Vertex]] {
        var cycles = [[Vertex]]()
        var B = [Blist](repeating: Blist(), count: graph.vertices.count)
        var blocked = [Bool](repeatElement(false, count: graph.vertices.count))
        var s = 0
        var stack = [Int]()
        func circuit(_ v: Int) -> Bool {
            func unblock(_ u: Int) {
                blocked[u] = false
                for w in B[u].items {
                    B[u].remove(item: w)
                    if blocked[w] {
                        unblock(w)
                    }
                }
            }
            var f = false
            stack.append(v)
            blocked[v] = true
            for w in graph.successors(of: graph.getVertex(index: v)!) {
                if w == s {
                    let first = graph.getVertex(index: stack[0])!
                    cycles.append(stack.flatMap { graph.getVertex(index: $0) } + [first])
                    f = true
                }
                else if blocked[w] {
                    f = circuit(w)
                }
            }
            if f {
                unblock(v)
            }
            else {
                for w in graph.successors(of: graph.getVertex(index: v)!) {
                    if !B[w].items.contains(v) {
                        B[w].add(item: v)
                    }
                }
            }
            let unstacked = stack.removeLast()
            assert(unstacked == v)
            return f
        }
        
        s = 0
        while s < graph.vertices.count {
            // adjacency structure of strong component K with least
            // vertex in subgraph of G induced by {s, s+ 1, n};
            let sccs = graph.filter({ $0.graphIndex >= s }).findStronglyConnectedComponents()
            guard let K = sccs.min(by: { $0.0.leastGraphIndex <  $0.1.leastGraphIndex }) else {
                break
            }
            s = K.leastGraphIndex
            for v in K.vertices {
                let i = v.graphIndex
                blocked[i] = false
                B[i].items.removeAll()
            }
            _ = circuit(s)
            s = s + 1
        }
        
        return cycles
    }
}

extension Graph {
    func findCycles() -> [[Vertex]] {
        return JohnsonCircuitFindingAlgorithm.findCycles(graph: self)
    }
}




