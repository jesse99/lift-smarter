//  Created by Jesse Vorisek on 10/19/21.
import Foundation

/// Where the user is now with respect to a timed exercise. This will be reset if it's been
/// too long since the user has done the exercise.
final class Current: Storable {
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
    
    required init(from store: Store) {
        self.startDate = store.getDate("startDate")
        self.weight = store.getDbl("weight")
        self.setIndex = store.getInt("setIndex")
    }

    func save(_ store: Store) {
        store.addDate("startDate", startDate)
        store.addDbl("weight", weight)
        store.addInt("setIndex", setIndex)
    }

    func clone() -> Current {
        let store = Store()
        store.addObj("self", self)
        let result: Current = store.getObj("self")
        return result
    }

    fileprivate func reset(weight: Double) {
        self.startDate = Date()
        self.weight = weight
        self.setIndex = 0
    }
}

/// Used for stuff like 3x60s planks. Target is used to signal the user to increase difficulty
/// (typically by switching to a harder variant of the exercise or adding weight).
final class DurationsInfo: Equatable, Storable {
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
    
    required init(from store: Store) {
        self.sets = store.getObjArray("sets")
        self.targetSecs = store.getIntArray("targetSecs")
        self.expectedWeight = store.getDbl("expectedWeight")
        self.current = store.getObj("current")
        self.currentSecs = store.getIntArray("currentSecs")
    }

    func save(_ store: Store) {
        store.addObjArray("sets", sets)
        store.addIntArray("targetSecs", targetSecs)
        store.addDbl("expectedWeight", expectedWeight)
        store.addObj("current", current)
        store.addIntArray("currentSecs", currentSecs)
    }

    func clone() -> DurationsInfo {
        let store = Store()
        store.addObj("self", self)
        let result: DurationsInfo = store.getObj("self")
        return result
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
final class FixedRepsInfo: Equatable, Storable {
    var sets: [FixedRepsSet]
    
    var expectedWeight = 0.0
    
    var current = Current()
    var currentReps: [Int] = []           // what the user has done so far

    init(reps: [FixedRepsSet]) {
        ASSERT(!reps.isEmpty, "should not have zero sets")
        self.sets = reps
    }
    
    required init(from store: Store) {
        self.sets = store.getObjArray("sets")
        self.expectedWeight = store.getDbl("expectedWeight")
        self.current = store.getObj("current")
        self.currentReps = store.getIntArray("currentReps")
    }

    func save(_ store: Store) {
        store.addObjArray("sets", sets)
        store.addDbl("expectedWeight", expectedWeight)
        store.addObj("current", current)
        store.addIntArray("currentReps", currentReps)
    }

    func clone() -> FixedRepsInfo {
        let store = Store()
        store.addObj("self", self)
        let result: FixedRepsInfo = store.getObj("self")
        return result
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
final class MaxRepsInfo: Equatable, Storable {
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
    
    required init(from store: Store) {
        self.restSecs = store.getIntArray("restSecs")
        if store.hasKey("targetReps") {
            self.targetReps = store.getInt("targetReps")
        } else {
            self.targetReps = nil
        }
        self.expectedWeight = store.getDbl("expectedWeight")
        self.expectedReps = store.getIntArray("expectedReps")
        self.current = store.getObj("current")
        self.currentReps = store.getIntArray("currentReps")
    }

    func save(_ store: Store) {
        store.addIntArray("restSecs", restSecs)
        if let target = self.targetReps {
            store.addInt("targetReps", target)
        }
        store.addDbl("expectedWeight", expectedWeight)
        store.addIntArray("expectedReps", expectedReps)
        store.addObj("current", current)
        store.addIntArray("currentReps", currentReps)
    }

    func clone() -> MaxRepsInfo {
        let store = Store()
        store.addObj("self", self)
        let result: MaxRepsInfo = store.getObj("self")
        return result
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

struct ActualRepRange: Equatable, Storable {
    let reps: Int
    let percent: Double
    let stage: RepRangeStage
    
    init(reps: Int, percent: Double, stage: RepRangeStage) {
        self.reps = reps
        self.percent = percent
        self.stage = stage
    }

    init(from store: Store) {
        self.reps = store.getInt("reps")
        self.percent = store.getDbl("percent")
        self.stage = RepRangeStage(rawValue: store.getInt("stage"))!
    }

    func save(_ store: Store) {
        store.addInt("reps", reps)
        store.addDbl("percent", percent)
        store.addInt("stage", stage.rawValue)
    }
}

/// Number of sets are fixed. Reps can be fixed or an inclusive range. Useful for stuff like 3x5 squat
/// or 3x8-12 lat pulldown
final class RepRangesInfo: Equatable, Storable {
    var sets: [RepsSet]
    
    var expectedWeight = 0.0
    var expectedReps: [ActualRepRange]   // includes warmup, work, and backoff sets
    
    var current = Current()
    var currentReps: [ActualRepRange] = []   // includes warmup, work, and backoff sets

    init(sets: [RepsSet]) {
        ASSERT(sets.first(where: {$0.stage == .workset}) != nil, "should not have zero worksets")
        self.sets = sets
        self.expectedReps = []
    }
    
    required init(from store: Store) {
        self.sets = store.getObjArray("sets")
        self.expectedWeight = store.getDbl("expectedWeight")
        self.expectedReps = store.getObjArray("expectedReps")
        self.current = store.getObj("current")
        self.currentReps = store.getObjArray("currentReps")
    }

    func save(_ store: Store) {
        store.addObjArray("sets", sets)
        store.addDbl("expectedWeight", expectedWeight)
        store.addObjArray("expectedReps", expectedReps)
        store.addObj("current", current)
        store.addObjArray("currentReps", currentReps)
    }

    func clone() -> RepRangesInfo {
        let store = Store()
        store.addObj("self", self)
        let result: RepRangesInfo = store.getObj("self")
        return result
    }

    func currentSet(_ delta: Int = 0) -> RepsSet {
        let index = self.current.setIndex + delta
        return self.sets[index]
    }
    
    func resetCurrent(weight: Double) {
        self.current.reset(weight: weight)
        self.currentReps = []
    }
    
    func resetExpected() {
        self.expectedReps = []
    }

    static func == (lhs: RepRangesInfo, rhs: RepRangesInfo) -> Bool {
        return lhs.sets == rhs.sets && abs(lhs.expectedWeight - rhs.expectedWeight) < 0.01 && lhs.expectedReps == rhs.expectedReps
    }
}

/// Both number of sets and reps can vary. Useful for things like 30 pullups spread across as many sets
/// as neccesary.
final class RepTotalInfo: Equatable, Storable {
    var total: Int
    var rest: Int
    
    var expectedWeight = 0.0
    var expectedReps: [Int] = []           // this can be empty since we can't properly reset it, for the sake of consistency we allow the other info's to also be empty
    
    var current = Current()
    var currentReps: [Int] = []           // what the user has done so far

    init(total: Int, rest: Int) {
        ASSERT(total > 0, "total reps should not be zero")
        self.total = total
        self.rest = rest
    }
    
    required init(from store: Store) {
        self.total = store.getInt("total")
        self.rest = store.getInt("rest")
        self.expectedWeight = store.getDbl("expectedWeight")
        self.expectedReps = store.getIntArray("expectedReps")
        self.current = store.getObj("current")
        self.currentReps = store.getIntArray("currentReps")
    }

    func save(_ store: Store) {
        store.addInt("total", total)
        store.addInt("rest", rest)
        store.addDbl("expectedWeight", expectedWeight)
        store.addIntArray("expectedReps", expectedReps)
        store.addObj("current", current)
        store.addIntArray("currentReps", currentReps)
    }

    func clone() -> RepTotalInfo {
        let store = Store()
        store.addObj("self", self)
        let result: RepTotalInfo = store.getObj("self")
        return result
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

extension ExerciseInfo: Storable {
    init(from store: Store) {
        let tname = store.getStr("type")
        switch tname {
        case "durations":
            self = .durations(store.getObj("info"))
            
        case "fixedReps":
            self = .fixedReps(store.getObj("info"))
            
        case "maxReps":
            self = .maxReps(store.getObj("info"))
            
        case "repRanges":
            self = .repRanges(store.getObj("info"))

        case "repTotal":
            self = .repTotal(store.getObj("info"))
            
        default:
            ASSERT(false, "loading apparatus had unknown type: \(tname)"); abort()
        }
    }
    
    func save(_ store: Store) {
        switch self {
        case .durations(let info):
            store.addStr("type", "durations")
            store.addObj("info", info)

        case .fixedReps(let info):
            store.addStr("type", "fixedReps")
            store.addObj("info", info)

        case .maxReps(let info):
            store.addStr("type", "maxReps")
            store.addObj("info", info)

        case .repRanges(let info):
            store.addStr("type", "repRanges")
            store.addObj("info", info)

        case .repTotal(let info):
            store.addStr("type", "repTotal")
            store.addObj("info", info)
        }
    }

    func clone() -> ExerciseInfo {
        let store = Store()
        store.addObj("self", self)
        let result: ExerciseInfo = store.getObj("self")
        return result
    }
}

extension ExerciseInfo {
    func resetCurrent(_ weight: Double) {
        switch self {
        case .durations(let info):
            info.resetCurrent(weight: weight)
        case .fixedReps(let info):
            info.resetCurrent(weight: weight)
        case .maxReps(let info):
            info.resetCurrent(weight: weight)
        case .repRanges(let info):
            info.resetCurrent(weight: weight)
        case .repTotal(let info):
            info.resetCurrent(weight: weight)
        }
    }

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
}
