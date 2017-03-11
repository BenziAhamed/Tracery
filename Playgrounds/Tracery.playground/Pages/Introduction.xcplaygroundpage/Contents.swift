//: [Previous](@previous)

import Foundation

var str = "Hello, playground"

//: [Next](@next)



//stripLeadingSpacesForHeaders(text: "        s   ## ## lemon ##asd #")
//
//let lines = ["# le", "## asd", " ## ## asd", "asd #"]


extension String {
    
    func strippingLeadingSpacesForHeaders() -> String {
        guard let regex = try? NSRegularExpression.init(pattern: "^(\\s*)(#+)", options: .caseInsensitive) else { return self }
        if let match = regex.firstMatch(in: self, options: .withoutAnchoringBounds, range: .init(location: 0, length: characters.count)) {
            guard match.numberOfRanges == 3 else { return self }
            let whitespaceCount = match.rangeAt(1).length
            return substring(from: index(startIndex, offsetBy: whitespaceCount))
        }
        return self
    }
    
    func strippingLeadingPattern(_ pattern: String) -> String {
        guard let regex = try? NSRegularExpression.init(pattern: pattern, options: .caseInsensitive) else { return self }
        if let match = regex.firstMatch(in: self, options: .withoutAnchoringBounds, range: .init(location: 0, length: characters.count)) {
            guard match.numberOfRanges >= 2 else { return self }
            let count = match.rangeAt(1).length
            return substring(from: index(startIndex, offsetBy: count))
        }
        return self
    }

}

"//:  ## asddsa ".strippingLeadingSpacesForHeaders().strippingLeadingPattern("(/[*]:|//:)")

["",""].joined(separator: <#T##String#>)