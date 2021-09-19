//  Created by Jesse Vorisek on 9/13/21.
import Foundation
import SwiftUI

class ExerciseVM: Identifiable, ObservableObject {
    let workout: WorkoutVM
    private let exercise: Exercise
    private let instance: ExerciseInstance
    
    init(_ vm: WorkoutVM, _ exercise: Exercise, _ instance: ExerciseInstance) {
        self.workout = vm
        self.exercise = exercise
        self.instance = instance
    }
    
    func willChange() {
        self.objectWillChange.send()
        self.workout.willChange()
    }

    var name: String {
        get {return self.exercise.name}
    }
    
    var enabled: Bool {
        get {return self.instance.enabled}
    }

    var setIndex: Int {
        get {return self.instance.current.setIndex}
    }

    func numSets() -> Int? {
        switch self.exercise.modality.sets {
        case .durations(let durations, _):
            return durations.count

        case .fixedReps(let worksets):
            return worksets.count

        case .maxReps(let restSecs, _):
            return restSecs.count

        case .repRanges(warmups: let warmups, worksets: let worksets, backoffs: let backoffs):
            return warmups.count + worksets.count + backoffs.count

        case .repTotal(total: _, rest: _):
            return nil
        }
    }

    var id: String {
        get {
            return self.name
        }
    }
}

// Misc Logic
extension ExerciseVM {
    func log(_ level: LogLevel, _ message: String) {
        self.workout.log(level, message)
    }

    func shouldReset() -> Bool {
        // 1) If it's been a long time since the user began the exercise then start over.
        // 2) If setIndex has become whacked as a result of user edits then start over.
        if let numSets = self.numSets() {
            return Date().hoursSinceDate(self.instance.current.startDate) > RecentHours || self.setIndex > numSets
        } else {
            return Date().hoursSinceDate(self.instance.current.startDate) > RecentHours
        }
    }
    
    func reset() {
        self.willChange()
        
        instance.current.reset(weight: exercise.expected.weight)
    }
    
    func inProgress() -> Bool {
        if let numSets = self.numSets() {
            return self.setIndex > 0 && self.setIndex < numSets
        } else {
            return false
        }
    }
        
    func incomplete() -> Bool {
        switch self.exercise.modality.sets {
        case .durations(let durations, targetSecs: _):
            return self.setIndex < durations.count
        case .fixedReps(let sets):
            return self.setIndex < sets.count
        case .maxReps(restSecs: let rests, targetReps: _):
            return self.setIndex < rests.count
        case .repRanges(warmups: let warmups, worksets: let worksets, backoffs: let backoffs):
            return self.setIndex < (warmups.count + worksets.count + backoffs.count)
        case .repTotal(total: let totalReps, rest: _):
            let reps = self.instance.current.reps.reduce(0, {
                switch $1 {
                case .reps(count: let reps, percent: _):
                    return $0 + reps
                default:
                    ASSERT(false, "expected reps")
                    return 0
                }
            })
            return reps < totalReps
        }
    }
    
    func updateCurrent(_ reps: Int? = nil) {
        switch self.exercise.modality.sets {
        case .durations(let durations, targetSecs: _):
            ASSERT(reps == nil, "reps is for repRanges")
            self.willChange()

            let duration = durations[self.setIndex]
            instance.current.reps.append(.duration(secs: duration.secs, percent: 1.0))
            instance.current.setIndex += 1
        default:
            ASSERT(false, "not implemented")
        }
    }

    func appendCurrent(_ reps: ActualRep) {
    }
    
    func setSets(_ sets: Sets) { 
        self.willChange()

        self.exercise.modality.sets = sets
    }

    // For rest between sets.
    func implicitTimer() -> TimerView {
        switch self.exercise.modality.sets {
        case .durations(let durations, targetSecs: _):
            return TimerView(title: self.getSetTimerTitle("Set"), duration: durations[self.setIndex].secs, secondDuration: self.restDuration())
        default:
            return TimerView(title: "not implemented", duration: 120)
        }
    }
    
    // User pressed the Start Timer button.
    func explicitTimer() -> TimerView {
        switch self.exercise.modality.sets {
        case .durations(let durations, targetSecs: _):
            var title: String
            if instance.current.setIndex < durations.count {
                title = getSetTimerTitle("On set")
            } else {
                title = "Finished"
            }

            let secs = self.restDuration()
            return TimerView(title: title, duration: secs > 0 ? secs : 60)
        default:
            return TimerView(title: "not implemented", duration: 0, secondDuration: 0)
        }
    }

    func view() -> AnyView {
        switch self.exercise.modality.sets {
        case .durations(_, _):
            return AnyView(DurationsView(self))

        case .fixedReps(_):
            return AnyView(Text("not implemented"))
//            return AnyView(FixedRepsView(model, workout, instance))

        case .maxReps(_, _):
            return AnyView(Text("not implemented"))
//            return AnyView(MaxRepsView(model, workout, instance))

        case .repRanges(_, _, _):
            return AnyView(Text("not implemented"))
//            return AnyView(RepRangesView(model, workout, instance))

        case .repTotal(total: _, rest: _):
            return AnyView(Text("not implemented"))
//            return AnyView(RepTotalView(model, workout, instance))

//      case .untimed(restSecs: let secs):
//          sets = Array(repeating: "untimed", count: secs.count)
        }
    }

    fileprivate func restDuration() -> Int {
        var secs = 0

        switch exercise.modality.sets {
        case .durations(let durations, targetSecs: _):
            if instance.current.setIndex < durations.count {
                secs = durations[instance.current.setIndex].restSecs
            } else {
                secs = durations.last!.restSecs
            }
        case .fixedReps(_):
            ASSERT(false, "not implemented")
        case .maxReps(restSecs: _, targetReps: _):
            ASSERT(false, "not implemented")
        case .repRanges(warmups: _, worksets: _, backoffs: _):
            ASSERT(false, "not implemented")
        case .repTotal(total: _, rest: _):
            ASSERT(false, "not implemented")
        }

        return secs
    }
}

// UI Labels
extension ExerciseVM {
    func title() -> String {
        switch exercise.modality.sets {
        case .durations(let durations, targetSecs: _):
            if instance.current.setIndex < durations.count {
                return "Set \(instance.current.setIndex+1) of \(durations.count)"
            } else if durations.count == 1 {
                return "Finished"
            } else {
                return "Finished all \(durations.count) sets"
            }
        case .fixedReps(_):
            return "not implemented"
        case .maxReps(restSecs: _, targetReps: _):
            return "not implemented"
        case .repRanges(warmups: _, worksets: _, backoffs: _):
            return "not implemented"
        case .repTotal(total: _, rest: _):
            return "not implemented"
        }
    }

    func subTitle() -> String {
        switch exercise.modality.sets {
        case .durations(let durations, targetSecs: let targetSecs):
            // TODO: If there is an expected weight I think we'd annotate subTitle.
            if instance.current.setIndex < durations.count {
                let duration = durations[instance.current.setIndex]
                if targetSecs.count > 0 {
                    let target = targetSecs[instance.current.setIndex]
                    return "\(duration.secs)s (target is \(target)s)"   // TODO: might want to use some sort of shortTimeStr function
                } else {
                    return "\(duration.secs)s"
                }
            } else {
                return ""
            }
        case .fixedReps(_):
            return "not implemented"
        case .maxReps(restSecs: _, targetReps: _):
            return "not implemented"
        case .repRanges(warmups: _, worksets: _, backoffs: _):
            return "not implemented"
        case .repTotal(total: _, rest: _):
            return "not implemented"
        }
    }

    func subSubTitle() -> String {
        switch exercise.modality.sets {
        case .durations(_, targetSecs: _):
    //        switch exercise.getClosest(self.display, exercise.expected.weight) {
    //        case .right(let weight):
    //            return weight >= 0.1 ? friendlyUnitsWeight(weight) : ""
    //        case .left(let err):
    //            return err
    //        }
            return ""       // TODO: implement this
        case .fixedReps(_):
            return "not implemented"
        case .maxReps(restSecs: _, targetReps: _):
            return "not implemented"
        case .repRanges(warmups: _, worksets: _, backoffs: _):
            return "not implemented"
        case .repTotal(total: _, rest: _):
            return "not implemented"
        }
    }

    func nextLabel() -> String {
        switch exercise.modality.sets {
        case .durations(let durations, targetSecs: _):
            if self.setIndex == durations.count {
                return "Done"
            } else {
                return "Start"
            }
        case .fixedReps(_):
            return "not implemented"
        case .maxReps(restSecs: _, targetReps: _):
            return "not implemented"
        case .repRanges(warmups: _, worksets: _, backoffs: _):
            return "not implemented"
        case .repTotal(total: _, rest: _):
            return "not implemented"
        }
    }

    func workoutLabel() -> ([String], String) {
        var sets: [String] = []
        var trailer = ""

        switch self.exercise.modality.sets {
        case .durations(let durations, _):
            sets = durations.map({"\($0.secs)s"})
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
        
        return (sets, trailer)
    }
    
    private func getSetTimerTitle(_ prefix: String) -> String {
        let i = instance.current.setIndex
        if let numSets = self.numSets() {
            return "\(prefix) \(i+1) of \(numSets)"
        } else {
            return "\(prefix) \(i+1)"
        }
    }
}

// Editing
extension ExerciseVM {
    func render() -> [String: String] {
        switch self.exercise.modality.sets {
        case .durations(let durations, targetSecs: let target): // ["durations: "60s x3", "rest": "0s x3", "target": "90s x3"]
            let d = durations.map({restToStr($0.secs)})
            let r = durations.map({restToStr($0.restSecs)})
            let t = target.map({restToStr($0)})
            return ["durations": joinedX(d), "rest": joinedX(r), "target": joinedX(t)]
        default:
            ASSERT(false, "not implemented")
            return [:]
        }
    }

    func parse(_ table: [String: String]) -> Either<String, Sets> {
        // Note that we don't use comma separated lists because that's more visual noise and
        // because some locales use commas for the decimal points.
        switch self.exercise.modality.sets {
        case .durations(_, targetSecs: _):
            switch coalesce(parseTimes(table["durations"]!, label: "durations"),
                            parseTimes(table["target"]!, label: "target"),
                            parseTimes(table["rest"]!, label: "rest", zeroOK: true)) {
            case .right((let d, let t, let r)):
                let count1 = d.count
                let count2 = r.count
                let count3 = t.count
                let match = count1 == count2 && (count3 == 0 || count1 == count3)

                if !match {
                    return .left("Durations, target, and rest must have the same number of sets (although target can be empty)")
                } else if count1 == 0 {
                    return .left("Durations and rest need at least one set")
                } else {
                    let z = zip(d, r)
                    let s = z.map({DurationSet(secs: $0.0, restSecs: $0.1)})
                    return .right(.durations(s, targetSecs: t))
                }
            case .left(let err):
                return .left(err)
            }
        default:
            return .left("not implemented")
        }
    }

    // Times = Time+ ('x' Int)?
    // Time = Int ('s' | 'm' | 'h')?    if units are missing seconds are assumed
    // Int = [0-9]+
    private func parseTimes(_ text: String, label: String, zeroOK: Bool = false) -> Either<String, [Int]> {
        func parseTime(_ scanner: Scanner) -> Either<String, Int> {
            let time = scanner.scanDouble()
            if time == nil {
                return .left("Expected a number for \(label) followed by optional s, m, or h")
            }
            
            var secs = time!
            if scanner.scanString("s") != nil {
                // nothing to do
            } else if scanner.scanString("m") != nil {
                secs *=  60.0
            } else if scanner.scanString("h") != nil {
                secs *=  60.0*60.0
            }

            if secs < 0.0 {
                return .left("\(label.capitalized) time cannot be negative")
            }
            if secs.isInfinite {
                return .left("\(label.capitalized) time must be finite")
            }
            if secs.isNaN {
                return .left("\(label.capitalized) time must be a number")
            }
            if !zeroOK && secs == 0.0 {
                return .left("\(label.capitalized) time cannot be zero")
            }

            return .right(Int(secs))
        }
        
        var times: [Int] = []
        let scanner = Scanner(string: text)
        while !scanner.isAtEnd {
            switch parseTime(scanner) {
            case .right(let time): times.append(time)
            case .left(let err): return .left(err)
            }
            
            if scanner.scanString("x") != nil {
                if let n = scanner.scanUInt64(), n > 0 {
                    if n < 1000 {
                        times = times.duplicate(x: Int(n))
                        break
                    } else {
                        return .left("repeat count is too large")
                    }
                } else {
                    return .left("x should be followed by the number of times to duplicate")
                }
            }
        }
        
        if !scanner.isAtEnd {
            return .left("\(label.capitalized) should be times followed by an optional xN to repeat")
        }
        
        return .right(times)
    }
    private func restToStr(_ secs: Int) -> String {
        if secs <= 0 {
            return "0s"

        } else if secs <= 60 {
            return "\(secs)s"
        
        } else {
            let s = friendlyFloat(String.init(format: "%.1f", Double(secs)/60.0))
            return s + "m"
        }
    }

    private func joinedX(_ values: [String]) -> String {
        if values.count > 1 && values.all({$0 == values[0]}) {
            return values[0] + " x\(values.count)"
        } else {
            return values.joined(separator: " ")
        }
    }
}

// View Model internals (views can't call these because they don't have direct access
// to model classes).
extension ExerciseVM {
    func exercise(_ model: Model) -> Exercise {
        return self.exercise
    }

    func instance(_ model: Model) -> ExerciseInstance {
        return self.instance
    }
}

