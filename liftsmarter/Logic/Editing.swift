//  Created by Jesse Vorisek on 9/12/21.
import Foundation

// Returns something like ("60s x3", "0s x3", "90s x3").
func renderDurations(_ sets: Sets) -> (String, String, String) {
    switch sets {
    case .durations(let durations, targetSecs: let target):
        let d = durations.map({restToStr($0.secs)})
        let r = durations.map({restToStr($0.restSecs)})
        let t = target.map({restToStr($0)})
        return (joinedX(d), joinedX(r), joinedX(t))
    default:
        ASSERT(false, "expected durations")
        return ("", "", "")
    }
}

func parseDurations(durations: String, rest: String, target: String) -> Either<String, Sets> {
    // Note that we don't use comma separated lists because that's more visual noise and
    // because some locales use commas for the decimal points.
    switch coalesce(parseTimes(durations, label: "durations"), parseTimes(target, label: "target"), parseTimes(rest, label: "rest", zeroOK: true)) {
    case .right((let d, let t, let r)):
        let count1 = d.count
        let count2 = r.count
        let count3 = t.count
        let match = count1 == count2 && (count3 == 0 || count1 == count3)

        if !match {
            return .left("Durations, target, and rest must have the same number of sets (although target can be empty)")
        } else if count1 == 0 {
            return .left("Durations and rest need at least one set")
        } else {
            let z = zip(d, r)
            let s = z.map({DurationSet(secs: $0.0, restSecs: $0.1)})
            return .right(.durations(s, targetSecs: t))
        }
    case .left(let err):
        return .left(err)
    }
}

fileprivate func joinedX(_ values: [String]) -> String {
    if values.count > 1 && values.all({$0 == values[0]}) {
        return values[0] + " x\(values.count)"
    } else {
        return values.joined(separator: " ")
    }
}

fileprivate func restToStr(_ secs: Int) -> String {
    if secs <= 0 {
        return "0s"

    } else if secs <= 60 {
        return "\(secs)s"
    
    } else {
        let s = friendlyFloat(String.init(format: "%.1f", Double(secs)/60.0))
        return s + "m"
    }
}


// Times = Time+ ('x' Int)?
// Time = Int ('s' | 'm' | 'h')?    if units are missing seconds are assumed
// Int = [0-9]+
fileprivate func parseTimes(_ text: String, label: String, zeroOK: Bool = false) -> Either<String, [Int]> {
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
