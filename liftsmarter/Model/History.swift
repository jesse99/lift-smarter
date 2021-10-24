//  Created by Jesse Vorisek on 9/18/21.
import Foundation

enum ActualRep {    // note that this represents a single rep
    case reps(count: Int, percent: Double)
    case duration(secs: Int, percent: Double)
}

class History {
    // Note that this is associated with the exercise: to know when an instance has been completed check the workout.
    class Record {
        var completed: Date     // date exercise was finished
        var weight: Double      // may be 0.0, this is from current.weight
        var reps: [ActualRep]
        var workout: String     // not used atm, but may be used later to show users more detailed views
        var formalName: String  // not used atm, but may be used later to show users more detailed views
        var note: String = ""   // optional arbitrary text set by user

        init(_ workout: Workout, _ exercise: Exercise) {
            self.workout = workout.name
            self.formalName = exercise.formalName
            
            switch exercise.info {
            case .durations(let info):
                self.completed = info.current.startDate    // using startDate instead of Date() makes testing a bit easier...
                self.weight = info.current.weight
                self.reps = info.currentSecs.map({.duration(secs: $0, percent: 1.0)})
            case .fixedReps(let info):
                self.completed = info.current.startDate
                self.weight = info.current.weight
                self.reps = info.currentReps.map({.reps(count: $0, percent: 1.0)})
            case .maxReps(let info):
                self.completed = info.current.startDate
                self.weight = info.current.weight
                self.reps = info.currentReps.map({.reps(count: $0, percent: 1.0)})
            case .repRanges(let info):
                self.completed = info.current.startDate
                self.weight = info.current.weight
                self.reps = info.currentReps.map({.reps(count: $0.reps, percent: $0.percent)})
            case .repTotal(let info):
                self.completed = info.current.startDate
                self.weight = info.current.weight
                self.reps = info.currentReps.map({.reps(count: $0, percent: 1.0)})
            }
        }
    }

    var records: [String: [Record]] = [:]   // keyed by exercise name, last record is the most recent
}
