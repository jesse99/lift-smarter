//  Created by Jesse Vorisek on 9/9/21.
import Foundation

struct FixedReps: Equatable {
    let reps: Int
    
    init(_ reps: Int) {
        self.reps = reps
    }
}

struct RepRange: Equatable {
    let min: Int
    let max: Int?   // missing means min+
    
    init(min: Int, max: Int?) {
        self.min = min
        self.max = max
    }
}

struct WeightPercent: Equatable {
    let value: Double

    init(_ value: Double) {
        self.value = value
    }

    static func * (lhs: Double, rhs: WeightPercent) -> Double {
        return lhs * rhs.value
    }
}

struct FixedRepsSet: Equatable {
    let reps: FixedReps
    let restSecs: Int
    
    init(reps: FixedReps, restSecs: Int = 0) {
        self.reps = reps
        self.restSecs = restSecs
    }
}

struct RepsSet: Equatable {
    let reps: RepRange
    let percent: WeightPercent
    let restSecs: Int
    
    init(reps: RepRange, percent: WeightPercent = WeightPercent(1.0), restSecs: Int = 0) {
        self.reps = reps
        self.percent = percent
        self.restSecs = restSecs
    }
}

struct DurationSet: Equatable {
    let secs: Int
    let restSecs: Int
    
    init(secs: Int, restSecs: Int = 0) {
        self.secs = secs
        self.restSecs = restSecs
    }
}

enum Sets: Equatable {
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
