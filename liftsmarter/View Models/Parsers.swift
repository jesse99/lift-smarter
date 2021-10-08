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

// Times = Time+ ('x' Int)?
// Time = Int ('s' | 'm' | 'h')?    if units are missing seconds are assumed
// Int = [0-9]+
func parseTimes(_ text: String, label: String, zeroOK: Bool = false) -> Either<String, [Int]> {
    func parseTime(_ scanner: Scanner) -> Either<String, Int> {
        let time = scanner.scanDouble()
        if time == nil {
            return .left("Expected a number for \(label) followed by optional s, m, or h")
        }
        
        var secs = time!
        if scanner.scanString("s") != nil {
            // nothing to do
        } else if scanner.scanString("m") != nil {
            secs *=  60.0
        } else if scanner.scanString("h") != nil {
            secs *=  60.0*60.0
        }

        if secs < 0.0 {
            return .left("\(label.capitalized) time cannot be negative")
        }
        if secs.isInfinite {
            return .left("\(label.capitalized) time must be finite")
        }
        if secs.isNaN {
            return .left("\(label.capitalized) time must be a number")
        }
        if !zeroOK && secs == 0.0 {
            return .left("\(label.capitalized) time cannot be zero")
        }

        return .right(Int(secs))
    }
    
    var times: [Int] = []
    let scanner = Scanner(string: text)
    while !scanner.isAtEnd {
        switch parseTime(scanner) {
        case .right(let time): times.append(time)
        case .left(let err): return .left(err)
        }
        
        if scanner.scanString("x") != nil {
            if let n = scanner.scanUInt64(), n > 0 {
                if n < 1000 {
                    times = times.duplicate(x: Int(n))
                    break
                } else {
                    return .left("repeat count is too large")
                }
            } else {
                return .left("x should be followed by the number of times to duplicate")
            }
        }
    }
    
    if !scanner.isAtEnd {
        return .left("\(label.capitalized) should be times followed by an optional xN to repeat")
    }
    
    return .right(times)
}
