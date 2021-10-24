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
