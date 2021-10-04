//  Created by Jesse Vorisek on 9/18/21.
import Foundation

class History {
    // Note that this is associated with the exercise: to know when an instance has been completed check the workout.
    class Record {
        var completed: Date     // date exercise was finished
        var weight: Double      // may be 0.0, this is from current.weight
        var reps: [ActualRep]
        var workout: String     // not used atm, but may be used later to show users more detailed views
        var formalName: String  // not used atm, but may be used later to show users more detailed views
        var note: String = ""   // optional arbitrary text set by user

        init(_ workout: Workout, _ exercise: Exercise, _ instance: ExerciseInstance) {
            self.completed = instance.current.startDate    // using startDate instead of Date() makes testing a bit easier...
            self.weight = instance.current.weight
            self.reps = instance.current.reps
            self.workout = workout.name
            self.formalName = exercise.formalName
        }
    }

    var records: [String: [Record]] = [:]   // keyed by exercise name, last record is the most recent
}
