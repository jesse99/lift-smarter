//  Created by Jesse Vorisek on 9/9/21.
import Foundation

/// Used to manage the workouts the user is expected to perform on some schedule.
class Program: ObservableObject {
    @Published var name: String
    @Published var workouts: [Workout]    // workout names must be unique
    @Published var exercises: [Exercise]  // exercise names must be unique, TODO: probably want to sort these by name
    @Published var weeksStart: Date       // a date within week 1
//    @Published var notes: [EditNote]

    init(_ name: String, _ workouts: [Workout], _ exercises: [Exercise], weeksStart: Date) {
        let names = workouts.map {$0.name}
        ASSERT_EQ(names.count, Set(names).count)

        let names2 = exercises.map {$0.name}
        ASSERT_EQ(names2.count, Set(names2).count)

        self.name = name
        self.workouts = workouts
        self.exercises = exercises
        self.weeksStart = weeksStart
//        self.notes = []
//        self.addNote("Created")
    }
}

