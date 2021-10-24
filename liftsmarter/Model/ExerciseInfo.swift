//  Created by Jesse Vorisek on 10/19/21.
import Foundation

/// Where the user is now with respect to a timed exercise. This will be reset if it's been
/// too long since the user has done the exercise.
final class Current {
    var startDate: Date       // date exercise was started
    var weight: Double        // may be 0.0, this is from expected.weight
    var setIndex: Int         // if this is sets.count then the user has finished those sets
    
    init() {
        self.startDate = Date.distantPast
        self.weight = 0.0
        self.setIndex = 0
    }
    
    init(weight: Double) {
        self.startDate = Date()
        self.weight = weight
        self.setIndex = 0
    }
    
    func clone() -> Current {
        let copy = Current()
        copy.startDate = self.startDate
        copy.weight = self.weight
        copy.setIndex = self.setIndex
        return copy
    }
    
    fileprivate func reset(weight: Double) {
        self.startDate = Date()
        self.weight = weight
        self.setIndex = 0
    }
}

/// Used for stuff like 3x60s planks. Target is used to signal the user to increase difficulty
/// (typically by switching to a harder variant of the exercise or adding weight).
final class DurationsInfo: Equatable {
    var sets: [DurationSet]
    var targetSecs: [Int]

    var expectedWeight = 0.0
    
    var current = Current()
    var currentSecs: [Int] = []           // what the user has done so far

    init(sets: [DurationSet], targetSecs: [Int] = []) {
        ASSERT(!sets.isEmpty, "should not have zero sets")
        ASSERT(targetSecs.isEmpty || targetSecs.count == sets.count, "targetSecs must match sets")
        self.sets = sets
        self.targetSecs = targetSecs
    }
    
    func clone() -> DurationsInfo {
        let copy = DurationsInfo(sets: self.sets, targetSecs: self.targetSecs)
        copy.expectedWeight = self.expectedWeight
        copy.current = self.current.clone()
        copy.currentSecs = self.currentSecs
        return copy
    }
    
    func resetCurrent(weight: Double) {
        self.current.reset(weight: weight)
        self.currentSecs = []
    }
    
    func resetExpected() {
        // nothing to do
    }

    static func == (lhs: DurationsInfo, rhs: DurationsInfo) -> Bool {
        return lhs.sets == rhs.sets && lhs.targetSecs == rhs.targetSecs && abs(lhs.expectedWeight - rhs.expectedWeight) < 0.01
    }
}

/// Number of sets and reps are both fixed. Useful for things like 3x10 quad stretch.
final class FixedRepsInfo: Equatable {
    var sets: [FixedRepsSet]
    
    var expectedWeight = 0.0
    
    var current = Current()
    var currentReps: [Int] = []           // what the user has done so far

    init(reps: [FixedRepsSet]) {
        ASSERT(!reps.isEmpty, "should not have zero sets")
        self.sets = reps
    }
    
    func clone() -> FixedRepsInfo {
        let copy = FixedRepsInfo(reps: self.sets)
        copy.expectedWeight = self.expectedWeight
        copy.current = self.current.clone()
        copy.currentReps = self.currentReps
        return copy
    }
    
    func resetCurrent(weight: Double) {
        self.current.reset(weight: weight)
        self.currentReps = []
    }
    
    func resetExpected() {
        // nothing to do
    }

    static func == (lhs: FixedRepsInfo, rhs: FixedRepsInfo) -> Bool {
        return lhs.sets == rhs.sets && abs(lhs.expectedWeight - rhs.expectedWeight) < 0.01
    }
}

/// Numbers of sets are fixed. Reps in each set are AMRAP. Useful for things like curls to exhaustion.
/// targetReps is used to signal the user to increase difficulty (typically by adding weight).
final class MaxRepsInfo: Equatable {
    var restSecs: [Int]
    var targetReps: Int?
    
    var expectedWeight = 0.0
    var expectedReps: [Int] = []
    
    var current = Current()
    var currentReps: [Int] = []           // what the user has done so far

    init(restSecs: [Int], targetReps: Int? = nil) {
        ASSERT(!restSecs.isEmpty, "should not have zero sets")
        self.restSecs = restSecs
        self.targetReps = targetReps
    }
    
    func clone() -> MaxRepsInfo {
        let copy = MaxRepsInfo(restSecs: self.restSecs, targetReps: self.targetReps)
        copy.expectedWeight = self.expectedWeight
        copy.expectedReps = self.expectedReps
        copy.current = self.current.clone()
        copy.currentReps = self.currentReps
        return copy
    }
    
    func resetCurrent(weight: Double) {
        self.current.reset(weight: weight)
        self.currentReps = []
    }
    
    func resetExpected() {
        self.expectedReps = []
    }

    static func == (lhs: MaxRepsInfo, rhs: MaxRepsInfo) -> Bool {
        return lhs.restSecs == rhs.restSecs && lhs.targetReps == rhs.targetReps && abs(lhs.expectedWeight - rhs.expectedWeight) < 0.01
    }
}

struct ActualRepRange: Equatable {
    let reps: Int
    let percent: Double
}

/// Number of sets are fixed. Reps can be fixed or an inclusive range. Useful for stuff like 3x5 squat
/// or 3x8-12 lat pulldown
final class RepRangesInfo: Equatable {
    var warmups: [RepsSet]
    var worksets: [RepsSet]
    var backoffs: [RepsSet]
    
    var expectedWeight = 0.0
    var expectedReps: [ActualRepRange] = []   // includes warmup, work, and backoff sets
    
    var current = Current()
    var currentReps: [ActualRepRange] = []   // includes warmup, work, and backoff sets

    init(warmups: [RepsSet], worksets: [RepsSet], backoffs: [RepsSet]) {
        ASSERT(!worksets.isEmpty, "should not have zero worksets")
        self.warmups = warmups
        self.worksets = worksets
        self.backoffs = backoffs
        self.resetExpected()
    }
    
    func clone() -> RepRangesInfo {
        let copy = RepRangesInfo(warmups: self.warmups, worksets: self.worksets, backoffs: self.backoffs)
        copy.expectedWeight = self.expectedWeight
        copy.expectedReps = self.expectedReps
        copy.current = self.current.clone()
        copy.currentReps = self.currentReps
        return copy
    }
    
    func resetCurrent(weight: Double) {
        self.current.reset(weight: weight)
        self.currentReps = []
    }
    
    func resetExpected() {
        self.expectedReps =
            self.warmups.map({ActualRepRange(reps: $0.reps.min, percent: $0.percent.value)}) +
            self.worksets.map({ActualRepRange(reps: $0.reps.min, percent: $0.percent.value)}) +
            self.backoffs.map({ActualRepRange(reps: $0.reps.min, percent: $0.percent.value)})
    }

    static func == (lhs: RepRangesInfo, rhs: RepRangesInfo) -> Bool {
        return lhs.warmups == rhs.warmups && lhs.worksets == rhs.worksets && lhs.backoffs == rhs.backoffs && abs(lhs.expectedWeight - rhs.expectedWeight) < 0.01 && lhs.expectedReps == rhs.expectedReps
    }
}

/// Both number of sets and reps can vary. Useful for things like 30 pullups spread across as many sets
/// as neccesary.
final class RepTotalInfo: Equatable {
    var total: Int
    var rest: Int
    
    var expectedWeight = 0.0
    var expectedReps: [Int] = []
    
    var current = Current()
    var currentReps: [Int] = []           // what the user has done so far

    init(total: Int, rest: Int) {
        ASSERT(total > 0, "total reps should not be zero")
        self.total = total
        self.rest = rest
    }
    
    func clone() -> RepTotalInfo {
        let copy = RepTotalInfo(total: self.total, rest: self.rest)
        copy.expectedWeight = self.expectedWeight
        copy.expectedReps = self.expectedReps
        copy.current = self.current.clone()
        copy.currentReps = self.currentReps
        return copy
    }
    
    func resetCurrent(weight: Double) {
        self.current.reset(weight: weight)
        self.currentReps = []
    }
    
    func resetExpected() {
        self.expectedReps = []
    }

    static func == (lhs: RepTotalInfo, rhs: RepTotalInfo) -> Bool {
        return lhs.total == rhs.total && lhs.rest == rhs.rest && abs(lhs.expectedWeight - rhs.expectedWeight) < 0.01 && lhs.expectedReps == rhs.expectedReps
    }
}

/// This is used to package up all the exercise type specific data into a single type-safe package.
enum ExerciseInfo: Equatable {
    case durations(DurationsInfo)
    case fixedReps(FixedRepsInfo)
    case maxReps(MaxRepsInfo)
    case repRanges(RepRangesInfo)
    case repTotal(RepTotalInfo)
    // TODO:   case untimed(restSecs: [Int])
}

extension ExerciseInfo {
    func caseIndex() -> Int {
        switch self {
        case .durations(_):
            return 0
        case .fixedReps(_):
            return 1
        case .maxReps(_):
            return 2
        case .repRanges(_):
            return 3
        case .repTotal(_):
            return 4
        }
    }
    
    func clone() -> ExerciseInfo {
        switch self {
        case .durations(let info):
            return .durations(info.clone())
        case .fixedReps(let info):
            return .fixedReps(info.clone())
        case .maxReps(let info):
            return .maxReps(info.clone())
        case .repRanges(let info):
            return .repRanges(info.clone())
        case .repTotal(let info):
            return .repTotal(info.clone())
        }
    }
}
