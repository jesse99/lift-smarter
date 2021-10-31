//  Created by Jesse Vorisek on 9/9/21.
import Foundation

struct FixedReps: Equatable, Storable {
    let reps: Int
    
    init(_ reps: Int) {
        self.reps = reps
    }

    init(from store: Store) {
        self.reps = store.getInt("reps")
    }

    func save(_ store: Store) {
        store.addInt("reps", reps)
    }
}

struct RepRange: Equatable, Storable {
    let min: Int
    let max: Int?   // missing means min+
    
    init(min: Int, max: Int?) {
        self.min = min
        self.max = max
    }

    init(from store: Store) {
        self.min = store.getInt("min")
        if store.hasKey("max") {
            self.max = store.getInt("max")
        } else {
            self.max = nil
        }
    }

    func save(_ store: Store) {
        store.addInt("min", min)
        if let max = self.max {
            store.addInt("max", max)
        }
    }
}

struct WeightPercent: Equatable, Storable {
    let value: Double

    init(_ value: Double) {
        self.value = value
    }

    init(from store: Store) {
        self.value = store.getDbl("value")
    }

    func save(_ store: Store) {
        store.addDbl("value", value)
    }

    static func * (lhs: Double, rhs: WeightPercent) -> Double {
        return lhs * rhs.value
    }
}

struct FixedRepsSet: Equatable, Storable {
    let reps: FixedReps
    let restSecs: Int
    
    init(reps: FixedReps, restSecs: Int = 0) {
        self.reps = reps
        self.restSecs = restSecs
    }

    init(from store: Store) {
        self.reps = store.getObj("reps")
        self.restSecs = store.getInt("restSecs")
    }

    func save(_ store: Store) {
        store.addObj("reps", reps)
        store.addInt("restSecs", restSecs)
    }
}

enum RepRangeStage: Int {case warmup, workset, backoff}

struct RepsSet: Equatable, Storable {
    let reps: RepRange
    let percent: WeightPercent
    let restSecs: Int
    let stage: RepRangeStage
    
    init(reps: RepRange, percent: WeightPercent = WeightPercent(1.0), restSecs: Int = 0, stage: RepRangeStage) {
        self.reps = reps
        self.percent = percent
        self.restSecs = restSecs
        self.stage = stage
    }

    init(from store: Store) {
        self.reps = store.getObj("reps")
        self.percent = store.getObj("percent")
        self.restSecs = store.getInt("restSecs")
        let raw = store.getInt("stage")
        self.stage = RepRangeStage(rawValue: raw)!
    }

    func save(_ store: Store) {
        store.addObj("reps", reps)
        store.addObj("percent", percent)
        store.addInt("restSecs", restSecs)
        store.addInt("stage", stage.rawValue)
    }
}

struct DurationSet: Equatable, Storable {
    let secs: Int
    let restSecs: Int
    
    init(secs: Int, restSecs: Int = 0) {
        self.secs = secs
        self.restSecs = restSecs
    }

    init(from store: Store) {
        self.secs = store.getInt("secs")
        self.restSecs = store.getInt("restSecs")
    }

    func save(_ store: Store) {
        store.addInt("secs", secs)
        store.addInt("restSecs", restSecs)
    }
}
