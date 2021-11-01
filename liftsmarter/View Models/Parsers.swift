//  Created by Jesse Vorisek on 9/27/21.
import Foundation

// Int = [0-9]+
func parseInt(_ text: String, label: String, zeroOK: Bool = false) -> Either<String, Int> {
    var value: Int? = nil
    let scanner = Scanner(string: text)
    while !scanner.isAtEnd {
        if let candidate = scanner.scanUInt64() {
            if !zeroOK && candidate == 0 {
                return .left("\(label.capitalized) must be greater than zero")
            } else if candidate > Int.max {
                return .left("\(label.capitalized) is too large")
            }
            value = Int(candidate)
        } else {
            return .left("Expected integer for \(label)")
        }
    }
    
    if value == nil && !zeroOK {
        return .left("Expected an integer for \(label)")
    }
    
    if !scanner.isAtEnd {
        return .left("Expected integer for \(label)")
    }

    return .right(value ?? 0)
}

// Int = [0-9]*
func parseOptionalInt(_ text: String, label: String, zeroOK: Bool = false) -> Either<String, Int?> {
    var value: Int? = nil
    let scanner = Scanner(string: text)
    while !scanner.isAtEnd {
        if let candidate = scanner.scanUInt64() {
            if !zeroOK && candidate == 0 {
                return .left("\(label.capitalized) must be greater than zero")
            } else if candidate > Int.max {
                return .left("\(label.capitalized) is too large")
            }
            value = Int(candidate)
        } else {
            return .left("Expected integer for \(label)")
        }
    }
    
    if value == nil {
        return .right(nil)
    }
    
    if !scanner.isAtEnd {
        return .left("Expected integer for \(label)")
    }

    return .right(value!)
}

// IntList = Int (Space Int)* ('x' Int)?
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
            
            if scanner.scanString("x") != nil {
                if let n = scanner.scanUInt64(), n > 0 {
                    if n < 1000 {
                        values = values.duplicate(x: Int(n))
                        break
                    } else {
                        return .left("repeat count is too large")
                    }
                } else {
                    return .left("x should be followed by the number of times to duplicate")
                }
            }
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

// RepRanges = RepRange+ ('x' Int)?
// RepRange = UnboundedReps | BoundedReps
// UnboundedReps = Int '+'
// BoundedReps = Int ('-' Int)?
func parseRepRanges(_ text: String, label: String, emptyOK: Bool) -> Either<String, [RepRange]> {
    func parseRepRange(_ scanner: Scanner) -> Either<String, RepRange> {
        let min = scanner.scanUInt64()
        if min == nil {
            return .left("Expected a number for \(label) followed by optional '+' or '-INT'")
        }
        if min! == 0 {
            return .left("\(label.capitalized) must be greater than zero")
        } else if min! > Int.max {
            return .left("\(label.capitalized) is too large")
        }

        if scanner.scanString("+") != nil {
            return .right(RepRange(min: Int(min!), max: nil))
        }

        if scanner.scanString("-") != nil {
            let max = scanner.scanUInt64()
            if max == nil {
                return .left("Expected a number for \(label) followed by optional '-max'")
            }
            if min! > max! {
                return .left("\(label.capitalized) min reps cannot be greater than max reps")
            } else if max! > Int.max {
                return .left("\(label.capitalized) is too large")
            }
            return .right(RepRange(min: Int(min!), max: Int(max!)))
        }

        return .right(RepRange(min: Int(min!), max: Int(min!)))
    }
    
    if text.isBlankOrEmpty() {
        if emptyOK {
            return .right([])
        } else {
            return .left("Expected reps of the form 5, 4-8, or 5+")
        }
    }
    
    var reps: [RepRange] = []
    let scanner = Scanner(string: text)
    while !scanner.isAtEnd {
        switch parseRepRange(scanner) {
        case .right(let rep): reps.append(rep)
        case .left(let err): return .left(err)
        }
        
        if scanner.scanString("x") != nil {
            if let n = scanner.scanUInt64(), n > 0 {
                if n < 1000 {
                    reps = reps.duplicate(x: Int(n))
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
        return .left("\(label.capitalized) should be rep ranges followed by an optional xN to repeat")
    }

    if reps.isEmpty {
        return .left("\(label.capitalized) needs at least one rep")
    }
    
    return .right(reps)
}

// Times = Time+ ('x' Int)?
// Time = Int ('s' | 'm' | 'h')?    if units are missing seconds are assumed
// Int = [0-9]+
func parseTimes(_ text: String, label: String, zeroOK: Bool = false, emptyOK: Bool = false, multipleOK: Bool = true) -> Either<String, [Int]> {
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
    
    if text.isBlankOrEmpty() {
        if emptyOK {
            return .right([])
        } else {
            return .left("\(label.capitalized) cannot be empty")
        }
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
    
    if times.count > 1 && !multipleOK {
        return .left("\(label.capitalized) should be a single time")
    }
    
    return .right(times)
}
