//  Created by Jesse Vorisek on 9/9/21.
import Foundation

struct FixedReps: CustomStringConvertible, Equatable {
    let reps: Int
    
    init(_ reps: Int) {
        self.reps = reps
    }
    
    var label: String { // TODO: should we add a protocol for label and editable? if nothing else would help document what they are for
        get {
            return "\(reps) reps"
        }
    }
    
    var editable: String {
        get {
            return "\(reps)"
        }
    }

    var description: String {
        return self.label
    }
}

struct RepRange: CustomStringConvertible, Equatable {
    let min: Int
    let max: Int?   // missing means min+
    
    init(min: Int, max: Int?) {
        self.min = min
        self.max = max
    }
    
    var label: String {
        get {
            if let max = self.max {
                if min < max {
                    return "\(min)-\(max) reps"
                } else {
                    if min == 1 {
                        return "1 rep"
                    } else {
                        return "\(min) reps"
                    }
                }
            } else {
                return "\(min)+ reps"
            }
        }
    }
    
    var editable: String {
        get {
            if let max = self.max {
                if min < max {
                    return "\(min)-\(max)"
                } else {
                    return "\(min)"
                }
            } else {
                return "\(min)+"
            }
        }
    }

    var description: String {
        return self.label
    }
}

struct WeightPercent: CustomStringConvertible, Equatable {
    let value: Double

    init(_ value: Double) {
        self.value = value
    }

    static func * (lhs: Double, rhs: WeightPercent) -> Double {
        return lhs * rhs.value
    }

    var editable: String {
        get {
            let i = Int(self.value*100)
            if abs(self.value - Double(i)) < 1.0 {
                return "0"
            } else {
                return "\(i)"
            }
        }
    }
    
    var label: String {
        get {
            let e = self.editable;
            return e == "0" ? "" : e+"%";
        }
    }

    var description: String {
        return String(format: "%.1f%%", 100.0*self.value)
    }
}

struct FixedRepsSet: CustomStringConvertible, Equatable {
    let reps: FixedReps
    let restSecs: Int
    
    init(reps: FixedReps, restSecs: Int = 0) {
        self.reps = reps
        self.restSecs = restSecs
    }

    var description: String {
        return self.reps.label
    }
}

struct RepsSet: CustomStringConvertible, Equatable {
    let reps: RepRange
    let percent: WeightPercent
    let restSecs: Int
    
    init(reps: RepRange, percent: WeightPercent = WeightPercent(1.0), restSecs: Int = 0) {
        self.reps = reps
        self.percent = percent
        self.restSecs = restSecs
    }

    var description: String {
        let display = self.percent.value >= 0.01 && self.percent.value <= 0.99
        let suffix = display ? " @ \(self.percent.label)" : ""

        return "\(self.reps.label)\(suffix)"
    }
}

struct DurationSet: CustomStringConvertible, Equatable {
    let secs: Int
    let restSecs: Int
    
    init(secs: Int, restSecs: Int = 0) {
        self.secs = secs
        self.restSecs = restSecs
    }

    var description: String {
        return "\(self.secs)s"
    }
}

enum Sets: CustomStringConvertible, Equatable {
    /// Used for stuff like 3x60s planks.
    case durations([DurationSet], targetSecs: [Int] = [])
    
    /// Does not allow variable reps or percents, useful for things like stretches.
    case fixedReps([FixedRepsSet])

    /// Used for stuff like curls to exhaustion. targetReps is the reps across all sets.
    case maxReps(restSecs: [Int], targetReps: Int? = nil)
    
    /// Used for stuff like 3x5 squat or 3x8-12 lat pulldown.
    case repRanges(warmups: [RepsSet], worksets: [RepsSet], backoffs: [RepsSet])
    
    /// Do total reps spread across as many sets as neccesary.
    case repTotal(total: Int, rest: Int)

//    case untimed(restSecs: [Int])
    
    // TODO: Will need some sort of reps target case (for stuff like pullups).

    var description: String {
        var sets: [String] = []
        
        switch self {
        case .durations(let durations, _):
            sets = durations.map({$0.description})

        case .fixedReps(let worksets):
            sets = worksets.map({$0.description})

        case .maxReps(let restSecs, _):
            sets = ["\(restSecs.count) sets"]

        case .repRanges(warmups: _, worksets: let worksets, backoffs: _):
            sets = worksets.map({$0.description})

        case .repTotal(total: let total, rest: _):
            sets = ["\(total) reps"]

//            case .untimed(restSecs: let secs):
//                sets = Array(repeating: "untimed", count: secs.count)
        }
        
        if sets.count == 1 {
            return sets[0]

        } else if sets.all({$0 == sets[0]}) {      // init/validate should ensure that we always have at least one set
            return "\(sets.count)x\(sets[0])"

        } else {
            return sets.joined(separator: ", ")
        }
    }
}

extension Sets {
    func caseIndex() -> Int {
        switch self {
        case .durations(secs: _):
            return 0
        case .fixedReps(reps: _):
            return 1
        case .maxReps(totalReps: _):
            return 2
        case .repRanges(warmups: _, worksets: _, backoffs: _):
            return 3
        case .repTotal(reps: _):
            return 4
        }
    }
}
