//  Created by Jesse Vorisek on 9/9/21.
import Foundation

enum WeekDay: Int {
    case sunday = 0, monday, tuesday, wednesday, thursday, friday, saturday
}

/// An instantiation of an exercise for a particular workout.
class ExerciseInstance: Identifiable, ObservableObject {
    @Published var name: String         // key into program.exercises
    @Published var enabled: Bool        // true if the user wants to perform the exercise within a particular workout
    @Published var allowRest: Bool      // respect rest weeks
    @Published var current = Current()  // reset if it's been too long since the user was doing the exercise

    init(_ name: String) {
        self.name = name
        self.enabled = true
        self.allowRest = true
    }

    var id: String {
        get {
            return self.name
        }
    }
}

enum Schedule {
    /// User can do the workout whenever he pleases, i.e. it's more or less optional.
    case anyDay
    
    /// If 1 then exercise is scheduled for every day, if 2 every other day, 3 every 3rd day, etc.
    case cyclic(Int)
    
    /// User should perform the exercise on the enumerated days.
    case days([WeekDay])
    
    /// Scheduled for specific 1-based weeks. Note that Program contains the date for week 1.
    case weeks([Int], [Schedule])
}

/// Encapsulates the exercises that the user is expected to peform on a day (or sey of days).
class Workout: Identifiable, ObservableObject {
    @Published var name: String
    @Published var enabled: Bool                   // true if the user wants to perform this workout
    @Published var instances: [ExerciseInstance]   // names must be unique
    @Published var schedule: Schedule
    @Published var restWeeks: [Int] = []           // empty => no rest, else 1-based weeks to de-schedule exercises (if they have allowRest on)

    init(_ name: String, _ names: [String], schedule: Schedule) {
        ASSERT_EQ(names.count, Set(names).count)

        self.name = name
        self.enabled = true
        self.instances = names.map {ExerciseInstance($0)}
        self.schedule = schedule
    }

    var id: String {
        get {
            return self.name
        }
    }
}
