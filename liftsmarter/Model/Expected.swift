//  Created by Jesse Vorisek on 9/9/21.
import Foundation

enum ExpectedSets {
    case durations              // expected is whatever Sets wants
    case fixedReps              // expected is whatever Sets wants
    case maxReps(reps: [Int])
    case repRanges(warmupsReps: [Int], worksetsReps: [Int], backoffsReps: [Int])
    case repTotal(reps: [Int])  // reps.count may differ from Sets
}

/// What the user is expected to do the next time he performs the exercise.
class Expected {
    var weight: Double      // may be 0.0
    var sets: ExpectedSets

    init(weight: Double, sets: ExpectedSets) {
        ASSERT_GE(weight, 0.0)
        
        self.weight = weight
        self.sets = sets
    }    
}


extension ExpectedSets {
    func caseIndex() -> Int {
        switch self {
        case .durations:
            return 0
        case .fixedReps:
            return 1
        case .maxReps(reps: _):
            return 2
        case .repRanges(warmupsReps: _, worksetsReps: _, backoffsReps: _):
            return 3
        case .repTotal(reps: _):
            return 4
        }
    }
}
