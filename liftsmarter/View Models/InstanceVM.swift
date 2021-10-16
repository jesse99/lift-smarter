//  Created by Jesse Vorisek on 9/13/21.
import Foundation
import SwiftUI

class InstanceVM: Equatable, Identifiable, ObservableObject {
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

    var exerciseVM: ExerciseVM {
        get {return ExerciseVM(self.workout.program, self.exercise)}
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

    static func ==(lhs: InstanceVM, rhs: InstanceVM) -> Bool {
        return lhs.name == rhs.name
    }
    
    var id: String {
        get {
            return self.name
        }
    }
}

// Misc Logic
extension InstanceVM {
    func log(_ level: LogLevel, _ message: String) {
        self.workout.log(level, message)
    }

    func setName(_ name: String) {
        self.willChange()
        self.instance.name = name
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
            return false        // TODO: this doesn't seem right
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
    
    func appendCurrent(_ reps: Int? = nil, now: Date = Date()) {
        self.willChange()

        if instance.current.setIndex == 0 {
            instance.current.startDate = now
        }

        switch self.exercise.modality.sets {
        case .durations(let durations, targetSecs: _):
            ASSERT(reps == nil, "reps is for repRanges")
            let duration = durations[self.setIndex]
            instance.current.setIndex += 1
            instance.current.reps.append(.duration(secs: duration.secs, percent: 1.0))
            
            if instance.current.setIndex == durations.count {
                let history = self.workout.program.history()
                history.append(self.workout, self)
                
                let workout = workout.workout(self.instance)
                workout.completed[self.name] = now
            }

        case .fixedReps(let sets):
            ASSERT(reps == nil, "reps is for repRanges")
            let reps = sets[self.setIndex].reps.reps
            instance.current.setIndex += 1
            instance.current.reps.append(.reps(count: reps, percent: 1.0))
            
            if instance.current.setIndex == sets.count {
                let history = self.workout.program.history()
                history.append(self.workout, self)
                
                let workout = workout.workout(self.instance)
                workout.completed[self.name] = now
            }

        default:
            ASSERT(false, "not implemented")
        }
    }
    
    func setSets(_ sets: Sets) { 
        self.willChange()
        self.exercise.modality.sets = sets
    }

    func toggleEnabled() {
        self.willChange()
        self.instance.enabled = !self.instance.enabled
    }
}

// UI
extension InstanceVM {
    func title() -> String {
        func text(numSets: Int) -> String {
            if instance.current.setIndex < numSets {
                return "Set \(instance.current.setIndex+1) of \(numSets)"
            } else if numSets == 1 {
                return "Finished"
            } else {
                return "Finished all \(numSets) sets"
            }
        }

        switch exercise.modality.sets {
        case .durations(let durations, targetSecs: _):  // TODO: might be able to use numSets()
            return text(numSets: durations.count)
        case .fixedReps(let sets):
            return text(numSets: sets.count)
        case .maxReps(restSecs: _, targetReps: _):
            return "not implemented"
        case .repRanges(warmups: _, worksets: _, backoffs: _):
            return "not implemented"
        case .repTotal(total: _, rest: _):
            return "not implemented"
        }
    }

    func subTitle() -> String {
        var text = ""
        
        let weight = exercise.expected.weight
        let percent = WeightPercent(1.0)
        switch exercise.modality.sets {
        case .durations(let durations, targetSecs: let targetSecs):
            if instance.current.setIndex < durations.count {
                let duration = durations[instance.current.setIndex]
                if targetSecs.count > 0 {
                    let target = targetSecs[instance.current.setIndex]
                    text = "\(duration.secs)s (target is \(target)s)"   // TODO: might want to use some sort of shortTimeStr function
                } else {
                    text = "\(duration.secs)s"
                }
            }
        case .fixedReps(let sets):
            if instance.current.setIndex < sets.count {
                let reps = sets[instance.current.setIndex]
                if reps.reps.reps == 1 {
                    text = "1 rep"
                } else {
                    text = "\(reps.reps.reps) reps"
                }
            }
        case .maxReps(restSecs: _, targetReps: _):
            text = "not implemented"
        case .repRanges(warmups: _, worksets: _, backoffs: _):
            text = "not implemented"
        case .repTotal(total: _, rest: _):
            text = "not implemented"
        }
        
        let closest = exercise.getClosestBelow(self.workout.model(instance), weight*percent)
        if case .right(let weight) = closest {
            let suffix = percent.value >= 0.01 && weight >= 0.1 ? " @ " + friendlyUnitsWeight(weight) : ""
            text += suffix
        }

        return text
    }

    // TODO: this would be stuff like plates
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
            return ""
        case .maxReps(restSecs: _, targetReps: _):
            return "not implemented"
        case .repRanges(warmups: _, worksets: _, backoffs: _):
            return "not implemented"
        case .repTotal(total: _, rest: _):
            return "not implemented"
        }
    }

    func nextLabel() -> String {
        func text(numSets: Int) -> String {
            if self.setIndex == numSets {
                return "Done"
            } else {
                return "Start"
            }
        }

        switch exercise.modality.sets {
        case .durations(let durations, targetSecs: _):
            return text(numSets: durations.count)
        case .fixedReps(let sets):
            return text(numSets: sets.count)
        case .maxReps(restSecs: _, targetReps: _):
            return "not implemented"
        case .repRanges(warmups: _, worksets: _, backoffs: _):
            return "not implemented"
        case .repTotal(total: _, rest: _):
            return "not implemented"
        }
    }

    func workoutLabel() -> ([String], String, Int) {
        func getFixedRepsLabel(_ index: Int, _ sets: FixedRepsSet) -> String {
            let reps = sets.reps.reps
            let suffix = weightSuffix(WeightPercent(1.0), exercise.expected.weight)
            if !suffix.isEmpty {
                return reps.description + suffix   // 5 @ 120 lbs
            } else {
                if reps == 1 {
                    return "1 rep"
                } else {
                    return "\(reps) reps"  // 5 reps
                }
            }
        }
        
        var setStrs: [String] = []
        var trailer = ""
        var limit = 8

        switch self.exercise.modality.sets {
        case .durations(let durations, _):
            setStrs = durations.map({"\($0.secs)s"})
            trailer = weightSuffix(WeightPercent(1.0), exercise.expected.weight)    // always the same for each set so we'll stick it at the end

        case .fixedReps(let sets):
            setStrs = sets.mapi(getFixedRepsLabel)
            limit = 6

        case .maxReps(_, _):
            setStrs.append("not implemented")

        case .repRanges(warmups: _, worksets: _, backoffs: _):
            setStrs.append("not implemented")

        case .repTotal(total: _, rest: _):
            setStrs.append("not implemented")
        }
        
        return (setStrs, trailer, limit)
    }
    
    private func getSetTimerTitle(_ prefix: String) -> String {
        let i = instance.current.setIndex
        if let numSets = self.numSets() {
            return "\(prefix) \(i+1) of \(numSets)"
        } else {
            return "\(prefix) \(i+1)"
        }
    }

    // For rest between sets.
    func implicitTimer() -> TimerView {
        switch self.exercise.modality.sets {
        case .durations(let durations, targetSecs: _):
            return TimerView(title: self.getSetTimerTitle("Set"), duration: durations[self.setIndex].secs, secondDuration: self.restDuration())
        case .fixedReps(let sets):
            return TimerView(title: self.getSetTimerTitle("Set"), duration: sets[self.setIndex].restSecs)
        default:
            return TimerView(title: "not implemented", duration: 120)
        }
    }
    
    // User pressed the Start Timer button.
    func explicitTimer() -> TimerView {
        var title: String
        if instance.current.setIndex < self.numSets() ?? 1000 {
            title = getSetTimerTitle("On set")
        } else {
            title = "Finished"
        }

        let secs = self.restDuration()
        return TimerView(title: title, duration: secs > 0 ? secs : 60)
    }

    func view() -> AnyView {
        switch self.exercise.modality.sets {
        case .durations(_, _):
            return AnyView(DurationsView(self))

        case .fixedReps(_):
            return AnyView(FixedRepsView(self))

        case .maxReps(_, _):
            return AnyView(Text("not implemented"))

        case .repRanges(_, _, _):
            return AnyView(Text("not implemented"))

        case .repTotal(total: _, rest: _):
            return AnyView(Text("not implemented"))
        }
    }
}

// Editing
extension InstanceVM {
    func render() -> [String: String] {
        switch self.exercise.modality.sets {
        case .durations(let durations, targetSecs: let target): // ["durations: "60s x3", "rest": "0s x3", "target": "90s x3"]
            let d = durations.map({restToStr($0.secs)})
            let r = durations.map({restToStr($0.restSecs)})
            let t = target.map({restToStr($0)})
            return ["durations": joinedX(d), "rest": joinedX(r), "target": joinedX(t)]
        case .fixedReps(let sets):
            let rr = sets.map({$0.reps.reps.description})
            let r = sets.map({restToStr($0.restSecs)})
            return ["reps": joinedX(rr), "rest": joinedX(r)]
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
        case .fixedReps(_):
            switch coalesce(parseIntList(table["reps"]!, label: "reps"),
                            parseTimes(table["rest"]!, label: "rest", zeroOK: true)) {
            case .right((let rr, let r)):
                let count1 = rr.count
                let count2 = r.count
                let match = count1 == count2

                if !match {
                    return .left("Reps and rest must have the same number of sets")
                } else if count1 == 0 {
                    return .left("Reps and rest need at least one set")
                } else {
                    let z = zip(rr, r)
                    let s = z.map({FixedRepsSet(reps: FixedReps($0.0), restSecs: $0.1)})
                    return .right(.fixedReps(s))
                }
            case .left(let err):
                return .left(err)
            }
        default:
            return .left("not implemented")
        }
    }

    private func restDuration() -> Int {
        var secs = 0

        switch exercise.modality.sets {
        case .durations(let durations, targetSecs: _):
            if instance.current.setIndex < durations.count {
                secs = durations[instance.current.setIndex].restSecs
            } else {
                secs = durations.last!.restSecs
            }
        case .fixedReps(let sets):
            if instance.current.setIndex < sets.count {
                secs = sets[instance.current.setIndex].restSecs
            } else {
                secs = sets.last!.restSecs
            }
        case .maxReps(restSecs: _, targetReps: _):
            ASSERT(false, "not implemented")
        case .repRanges(warmups: _, worksets: _, backoffs: _):
            ASSERT(false, "not implemented")
        case .repTotal(total: _, rest: _):
            ASSERT(false, "not implemented")
        }

        return secs
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
extension InstanceVM {
    func exercise(_ model: Model) -> Exercise {
        return self.exercise
    }

    func instance(_ model: Model) -> ExerciseInstance {
        return self.instance
    }

    func instance(_ workout: Workout) -> ExerciseInstance {
        return self.instance
    }
}

