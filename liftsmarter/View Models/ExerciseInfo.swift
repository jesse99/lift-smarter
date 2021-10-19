//  Created by Jesse Vorisek on 10/19/21.
import Foundation

// What if we got rid of Exercise and only had instances?
// Program could maintain a list of canonical instances
// on edit would have to update canonical instances and any in a workout
//    denormalized data
//    all the different exercise specific data is in one place
// history would probably stay as is

struct CurrentDurationInfo {
    var startDate: Date
    var weight: Double
    var setIndex: Int
    var secs: [Int]
    var percents: [Double]
}

struct CurrentRepsInfo {
    var startDate: Date
    var weight: Double
    var setIndex: Int
    var reps: [Int]
    var percents: [Double]
}

// TODO: what about history?
struct DurationsInfo {
    let sets: [DurationSet]
    let targetSecs: [Int]

    let expectedWeight: Double

    let current: CurrentDurationInfo
}

struct MaxRepsInfo {
    let restSecs: [Int]
    let targetReps: Int?
    
    let expectedWeight: Double
    let expectedReps: [Int]

    let current: CurrentRepsInfo
}

enum ExerciseInfo {
    case durations(DurationsInfo)
    case maxReps(MaxRepsInfo)
}

func updateExpected2(_ einfo: ExerciseInfo) -> Bool {
    switch einfo {
    case .durations(_):
        return false
    case .maxReps(let info):
        let currentReps = info.current.reps.reduce(0, {$0 + $1})
        let expectedReps = info.expectedReps.reduce(0, {$0 + $1})
        return expectedReps != currentReps
    }
}
