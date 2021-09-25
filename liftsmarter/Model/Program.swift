//  Created by Jesse Vorisek on 9/9/21.
import Foundation

/// Used to manage the workouts the user is expected to perform on some schedule.
class Program {
    var name: String
    var workouts: [Workout]    // workout names must be unique
    var exercises: [Exercise]  // exercise names must be unique, TODO: probably want to sort these by name
    var restWeeks: [Int] = []  // empty => no rest, else 1-based weeks to de-schedule exercises (if they have allowRest on)
    var weeksStart: Date       // a date within week 1
    var instanceClipboard: [ExerciseInstance] = []
//    var notes: [EditNote]

    init(_ name: String, _ workouts: [Workout], _ exercises: [Exercise], weeksStart: Date) {
        let names = workouts.map {$0.name}
        ASSERT_EQ(names.count, Set(names).count)

        let names2 = exercises.map {$0.name}
        ASSERT_EQ(names2.count, Set(names2).count)

        self.name = name
        self.workouts = workouts
        self.exercises = exercises.sorted(by: {$0.name < $1.name})
        self.weeksStart = weeksStart
//        self.notes = []
//        self.addNote("Created")
    }
}

