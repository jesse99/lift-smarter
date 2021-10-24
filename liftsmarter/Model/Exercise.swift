//  Created by Jesse Vorisek on 9/9/21.
import Foundation

let RecentHours = 8.0

/// An Exercise all the details for how to do a particular movement. Most of the fields should be
/// mirrored between the program and the workouts that use an exercise, but info.current and
/// enabled are specific to workouts.
/// 
/// This is essentially a de-normalized form of the data designed to simplify usage (but slightly
/// complicate edits).
class Exercise {
    var name: String            // "Heavy Bench"
    var formalName: String      // "Bench Press"
    var apparatus: Apparatus
    var info: ExerciseInfo      // set info, expected, and current
    var allowRest: Bool         // respect rest weeks
    var overridePercent: String // used to replace the normal weight percent label in exercise views with custom text
    var enabled: Bool           // true if the user wants to perform the exercise within a particular workout

    init(_ name: String, _ formalName: String, _ apparatus: Apparatus, _ info: ExerciseInfo, overridePercent: String = "") {
        self.name = name
        self.formalName = formalName
        self.apparatus = apparatus
        self.info = info
        self.allowRest = true
        self.overridePercent = overridePercent
        self.enabled = true
    }
        
    func clone() -> Exercise {
        let copy = Exercise(self.name, self.formalName, self.apparatus, self.info, overridePercent: self.overridePercent)
        copy.allowRest = self.allowRest
        copy.enabled = self.enabled
        return copy
    }
        
//    func isBodyWeight() -> Bool {
//        switch self.modality.apparatus {
//        case .bodyWeight:
//            return true
//        default:
//            return false
//        }
//    }
//
//    static func ==(lhs: Exercise, rhs: Exercise) -> Bool {  // TODO: names would have to be unique?
//        return lhs.name == rhs.name
//    }

//    func hash(into hasher: inout Hasher) {
//        hasher.combine(self.id)
//    }
}


//func defaultExpectedSets(_ sets: Sets) -> ExpectedSets {
//    switch sets {
//    case .durations(_, _):
//        return .durations
//
//    case .fixedReps(_):
//        return .fixedReps
//
//    case .maxReps(_, _):
//        return .maxReps(reps: [8, 8, 8])
//
//    case .repRanges(warmups: let warmups, worksets: let worksets, backoffs: let backoff):
//        let r1 = warmups.map({$0.reps.min})
//        let r2 = worksets.map({$0.reps.min})
//        let r3 = backoff.map({$0.reps.min})
//        return .repRanges(warmupsReps: r1, worksetsReps: r2, backoffsReps: r3)
//
//    case .repTotal(total: _, rest: _):
//        return .repTotal(reps: [5, 5, 5])
//    }
//}
//
//func defaultExpected(_ sets: Sets) -> Expected {
//    // TODO: if apparatus is a fixed weight set then default weight to the smallest weight?
//    return Expected(weight: 0.0, sets: defaultExpectedSets(sets))
//}
