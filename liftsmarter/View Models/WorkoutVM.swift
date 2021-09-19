//  Created by Jesse Vorisek on 9/13/21.
import Foundation
import SwiftUI

class WorkoutVM: ObservableObject, Identifiable {
    let program: ProgramVM
    private let workout: Workout
    
    init(_ program: ProgramVM, _ workout: Workout) {
        self.program = program
        self.workout = workout
    }
        
    func willChange() {
        self.objectWillChange.send()
        self.program.willChange()
    }

    var name: String {
        get {return self.workout.name}
    }
    
    var exercises: [ExerciseVM] {
        get {return self.program.instances(self.workout)}
    }
    
    func lastCompleted(_ exercise: ExerciseVM) -> Date? {
        return self.workout.completed[exercise.name]
    }

    var id: String {
        get {
            return self.workout.name
        }
    }
}

// Misc logic
extension WorkoutVM {
    func log(_ level: LogLevel, _ message: String) {
        self.program.log(level, message)
    }

    func recentlyCompleted(_ exercise: ExerciseVM) -> Bool {
        if let completed = self.lastCompleted(exercise) {
            return Date().hoursSinceDate(completed) < RecentHours
        } else {
            return false
        }
    }
        
}

// UI Labels
extension WorkoutVM {
    func label(_ exercise: ExerciseVM) -> String {
        return exercise.name
    }

    func subLabel(_ exercise: ExerciseVM) -> String {
        let tuple = exercise.workoutLabel()
        let sets = tuple.0
        let trailer = tuple.1
        let limit = 8
        
        if sets.count == 0 {
            return ""
        } else if sets.count == 1 {
            return sets[0] + trailer
        } else {
            let sets = dedupe(sets)
            let prefix = sets.prefix(limit)
            let result = prefix.joined(separator: ", ")
            if prefix.count < sets.count {
                return result + ", ..."
            } else {
                return result + trailer
            }
        }
    }

    func color(_ exercise: ExerciseVM) -> Color {
        if self.recentlyCompleted(exercise) {
            return .gray
        } else if exercise.inProgress() {
            return .blue
        } else {
            return .black
        }
    }
}


// View Model internals (views can't call these because they don't have direct access
// to model classes).
extension WorkoutVM {
    func workout(_ model: Model) -> Workout {
        return self.workout
    }
}

/// Replaces consecutive duplicate strings, e.g. ["alpha", "alpha", "beta"]
/// becomes ["2xalpha", "beta"].
func dedupe(_ sets: [String]) -> [String] {
    func numDupes(_ i: Int) -> Int {
        var count = 1
        while i+count < sets.count && sets[i] == sets[i+count] {
            count += 1
        }
        return count
    }
                
    var i = 0
    var result: [String] = []
    while i < sets.count {
        let count = numDupes(i)
        if count > 1 {
            result.append("\(count)x\(sets[i])")
            i += count
            
        } else {
            result.append(sets[i])
            i += 1
        }
    }
    
    return result
}

// TODO: move this into Weights.swift?
func weightSuffix(_ percent: WeightPercent, _ maxWeight: Double) -> String {
    let weight = maxWeight * percent
    return percent.value >= 0.01 && weight >= 0.1 ? " @ " + friendlyUnitsWeight(weight) : ""
}

func friendlyFloat(_ str: String) -> String {
    var result = str
    while result.hasSuffix("0") {
        let start = result.index(result.endIndex, offsetBy: -1)
        let end = result.endIndex
        result.removeSubrange(start..<end)
    }
    if result.hasSuffix(".") {
        let start = result.index(result.endIndex, offsetBy: -1)
        let end = result.endIndex
        result.removeSubrange(start..<end)
    }
    
    return result
}

func friendlyWeight(_ weight: Double) -> String {
    var result: String
    
    // Note that weights are always stored as lbs internally.
    //        let app = UIApplication.shared.delegate as! AppDelegate
    //        switch app.units()
    //        {
    //        case .imperial:
    //            // Kind of annoying to use three decimal places but people
    //            // sometimes use 0.625 fractional plates (5/8 lb).
    result = String(format: "%.3f", weight)
    //
    //        case .metric:
    //            result = String(format: "%.2f", arguments: [weight*Double.lbToKg])
    //        }
    
    return friendlyFloat(result)
}

func friendlyUnitsWeight(_ weight: Double, plural: Bool = true) -> String {
    if plural && weight != 1.0 {
        return friendlyWeight(weight) + " lbs"  // TODO: also kg
    } else {
        return friendlyWeight(weight) + " lb"
    }
}
