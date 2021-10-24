//  Created by Jesse Vorisek on 9/9/21.
import Foundation

enum WeekDay: Int {
    case sunday = 0, monday, tuesday, wednesday, thursday, friday, saturday
}

enum Schedule {
    /// User can do the workout whenever he pleases, i.e. it's more or less optional.
    case anyDay
    
    /// If 1 then exercise is scheduled for every day, if 2 every other day, 3 every 3rd day, etc.
    case cyclic(Int)
    
    /// User should perform the exercise on the enumerated days.
    case days([WeekDay])
    
    /// Scheduled for specific 1-based weeks. Note that Program contains the date for week 1.
    indirect case weeks([Int], Schedule)
}

/// Encapsulates the exercises that the user is expected to peform on a day (or sey of days).
class Workout {
    var name: String
    var enabled: Bool                   // true if the user wants to perform this workout
    var exercises: [Exercise]           // names must be unique
    var schedule: Schedule
    var completed: [String: Date] = [:] // exercise.name => date last completed

    init(_ name: String, _ exercises: [Exercise], schedule: Schedule) {
        let names = exercises.map {$0.name}
        ASSERT_EQ(names.count, Set(names).count)

        self.name = name
        self.enabled = true
        self.exercises = exercises.map {$0.clone()}
        self.schedule = schedule
    }
}

