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
class Workout: Storable {
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

    required init(from store: Store) {
        self.name = store.getStr("name")
        self.enabled = store.getBool("enabled")
        self.exercises = store.getObjArray("exercises")
        self.schedule = store.getObj("schedule")
        
        let names = store.getStrArray("completed-names")
        for (i, name) in names.enumerated() {
            self.completed[name] = store.getDate("completed-\(i)")
        }
    }

    func save(_ store: Store) {
        store.addStr("name", name)
        store.addBool("enabled", enabled)
        store.addObjArray("exercises", exercises)
        store.addObj("schedule", schedule)
        
        let names = Array(self.completed.keys)
        store.addStrArray("completed-names", names)
        for (i, name) in names.enumerated() {
            store.addDate("completed-\(i)", self.completed[name]!)
        }
    }
}

extension WeekDay: Storable {
    init(from store: Store) {
        self = WeekDay(rawValue: store.getInt("day"))!
    }
    
    func save(_ store: Store) {
        store.addInt("day", self.rawValue)
    }
}

extension Schedule: Storable {
    init(from store: Store) {
        let tname = store.getStr("type")
        switch tname {
        case "anyDay":
            self = .anyDay
            
        case "cyclic":
            self = .cyclic(store.getInt("count"))
            
        case "days":
            self = .days(store.getObjArray("days"))
            
        case "weeks":
            self = .weeks(store.getIntArray("weeks"), store.getObj("schedule"))
            
        default:
            ASSERT(false, "loading Schedule had unknown type: \(tname)"); abort()
        }
    }
    
    func save(_ store: Store) {
        switch self {
        case .anyDay:
            store.addStr("type", "anyDay")
            
        case .cyclic(let count):
            store.addStr("type", "cyclic")
            store.addInt("count", count)

        case .days(let days):
            store.addStr("type", "days")
            store.addObjArray("days", days)

        case .weeks(let weeks, let schedule):
            store.addStr("type", "weeks")
            store.addIntArray("weeks", weeks)
            store.addObj("schedule", schedule)
        }
    }
}
