//  Created by Jesse Vorisek on 9/27/21.
import Foundation

// IntList = Int (Space Int)*
func parseIntList(_ text: String, label: String, zeroOK: Bool = false, emptyOK: Bool = false) -> Either<String, [Int]> {
    var values: [Int] = []
    let scanner = Scanner(string: text)
    while !scanner.isAtEnd {
        if let value = scanner.scanUInt64() {
            if !zeroOK && value == 0 {
                return .left("\(label.capitalized) must be greater than zero")
            } else if value > Int.max {
                return .left("\(label.capitalized) is too large")
            }
            values.append(Int(value))
        } else {
            return .left("Expected space separated integers for \(label)")
        }
    }
    
    if !scanner.isAtEnd {
        return .left("Expected space separated integers for \(label)")
    }

    if values.isEmpty && !emptyOK {
        return .left("\(label.capitalized) needs at least one number")
    }
    
    return .right(values)
}
