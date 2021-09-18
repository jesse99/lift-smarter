//  Created by Jesse Vorisek on 9/13/21.
import Foundation
import SwiftUI

class WorkoutVM: ObservableObject {
    let model: Model
    let workout: Workout
    
    init(_ model: Model, _ workout: Workout) {
        self.model = model
        self.workout = workout
    }
    
    var name: String {
        get {return self.workout.name}
    }

    func label(_ instance: ExerciseInstance) -> (String, Color) {
        var sets: [String] = []
        let limit = 8

        var trailer = ""
        let exercise = self.model.program.exercises.first(where: {$0.name == instance.name})!
        switch exercise.modality.sets {
        case .durations(let durations, _):
            sets = durations.map({$0.description})
            trailer = weightSuffix(WeightPercent(1.0), exercise.expected.weight)    // always the same for each set so we'll stick it at the end

        case .fixedReps(_):
            sets.append("not implemented")

        case .maxReps(_, _):
            sets.append("not implemented")

        case .repRanges(warmups: _, worksets: _, backoffs: _):
            sets.append("not implemented")

        case .repTotal(total: _, rest: _):
            sets.append("not implemented")
        }
        
        let color = Color.black // TODO: use recentlyCompleted
        if sets.count == 0 {
            return ("", color)
        } else if sets.count == 1 {
            return (sets[0] + trailer, color)
        } else {
            let sets = dedupe(sets)
            let prefix = sets.prefix(limit)
            let result = prefix.joined(separator: ", ")
            if prefix.count < sets.count {
                return (result + ", ...", color)
            } else {
                return (result + trailer, color)
            }
        }
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
