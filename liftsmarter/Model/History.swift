//  Created by Jesse Vorisek on 9/18/21.
import Foundation

class History {
    class Reps {
        var completed: Date     // date exercise was finished
        var weight: Double      // may be 0.0, this is from current.weight
        var reps: ActualReps
        var key: String         // exercise.name + workout.name
        var note: String = ""   // optional arbitrary text set by user

        init(_ date: Date, _ weight: Double, _ reps: ActualReps, _ key: String) {
            self.completed = date
            self.weight = weight
            self.reps = reps
            self.key = key
        }
    }


}
