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
    
    var formalName: String {
        get {return self.exercise.formalName}
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

enum Progress {
    case notStarted
    case started
    case finished
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
        if let numSets = self.numSets() {
            // 1) If it's been a long time since the user began the exercise then start over.
            // 2) If setIndex has become whacked as a result of user edits then start over.
            return Date().hoursSinceDate(self.instance.current.startDate) > RecentHours || self.setIndex > numSets
        } else {
            return Date().hoursSinceDate(self.instance.current.startDate) > RecentHours
        }
    }
    
    func reset() {
        self.willChange()
        instance.current.reset(weight: exercise.expected.weight)
    }
    
    var notStarted: Bool {
        get {
            if case .notStarted = self.progress() {
                return true
            } else {
                return false
            }
        }
    }

    var started: Bool {
        get {
            if case .started = self.progress() {
                return true
            } else {
                return false
            }
        }
    }

    var finished: Bool {
        get {
            if case .finished = self.progress() {
                return true
            } else {
                return false
            }
        }
    }

    func progress() -> Progress {
        if case .repTotal(total: let totalReps, rest: _) = self.exercise.modality.sets {
            let currentReps = self.instance.current.reps.reduce(0, {
                if case .reps(count: let reps, percent: _) = $1 {
                    return $0 + reps
                } else {
                    ASSERT(false, "current should be using ,reps")
                    return $0
                }
            })
            if currentReps == 0 {
                return .notStarted
            } else if currentReps < totalReps {
                return .started
            } else {
                return .finished
            }
        }
        if let numSets = self.numSets() {
            if self.setIndex == 0 {
                return .notStarted
            } else if self.setIndex < numSets {
                return .started
            } else {
                return .finished
            }
        } else {
            ASSERT(false, "shouldn't have landed here")
            return .notStarted
        }
    }
    
    func expectedReps() -> Int? {
        switch self.exercise.expected.sets {
        case .repTotal(reps: let repsArray):
            return repsArray.at(self.instance.current.setIndex) ?? 1
        case .maxReps(reps: let repsArray):
            return repsArray.at(self.instance.current.setIndex) ?? 1
        case .repRanges(warmupsReps: _, worksetsReps: let repsArray, backoffsReps: _):
            return repsArray.at(self.instance.current.setIndex) ?? 1
        case .durations, .fixedReps:
            return nil
        }
    }
        
    func currentIsUnexpected() -> Bool {
        let currentReps = self.instance.current.reps.reduce(0, {
            if case .reps(count: let reps, percent: _) = $1 {
                return $0 + reps
            } else {
                return $0
            }
        })

        switch self.exercise.modality.sets {
        case .durations(_, targetSecs: _), .fixedReps(_):
            return false
        case .maxReps(restSecs: _, targetReps: _):
            if case .maxReps(reps: let repsArray) = self.exercise.expected.sets {
                let expectedReps = repsArray.reduce(0, {$0 + $1})
                return expectedReps != currentReps
            } else {
                ASSERT(false, "expected .maxReps")
                return false
            }
        case .repRanges(warmups: _, worksets: _, backoffs: _):
            if case .repRanges(warmupsReps: _, worksetsReps: let repsArray, backoffsReps: _) = self.exercise.expected.sets {
                let expectedReps = repsArray.reduce(0, {$0 + $1})
                return expectedReps != currentReps
            } else {
                ASSERT(false, "expected .repRanges")
                return false
            }
        case .repTotal(total: _, rest: _):
            if case .repTotal(reps: let repsArray) = self.exercise.expected.sets {
                let expectedReps = repsArray.reduce(0, {$0 + $1})
                return expectedReps != currentReps
            } else {
                ASSERT(false, "expected .repTotal")
                return false
            }
        }
    }
        
    func appendCurrent(_ reps: Int? = nil, now: Date = Date()) {
        self.willChange()

        if instance.current.setIndex == 0 {
            instance.current.startDate = now
        }

        switch self.exercise.modality.sets {
        case .durations(let durations, targetSecs: _):
            ASSERT(reps == nil, "reps is for repRanges and repTotal")
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
            ASSERT(reps == nil, "reps is for repRanges and repTotal")
            let reps = sets[self.setIndex].reps.reps
            instance.current.setIndex += 1
            instance.current.reps.append(.reps(count: reps, percent: 1.0))
            
            if instance.current.setIndex == sets.count {
                let history = self.workout.program.history()
                history.append(self.workout, self)
                
                let workout = workout.workout(self.instance)
                workout.completed[self.name] = now
            }
            
        case .repTotal(total: _, rest: _):
            ASSERT(reps != nil, "reps should be set")
            instance.current.setIndex += 1
            instance.current.reps.append(.reps(count: reps!, percent: 1.0))
            
            if self.finished {
                let history = self.workout.program.history()
                history.append(self.workout, self)
                
                let workout = workout.workout(self.instance)
                workout.completed[self.name] = now
            }

        default:
            ASSERT(false, "not implemented")
        }
    }
    
    func updateExpected() {
        self.willChange()

        switch self.exercise.modality.sets {
        case .durations(_, targetSecs: _), .fixedReps(_):
            ASSERT(false, "nonsensical")

        case .repTotal(total: _, rest: let rest):
            let repsArray: [Int] = self.instance.current.reps.map({
                if case .reps(count: let reps, percent: _) = $0 {
                    return reps
                } else {
                    ASSERT(false, "expected reps")
                    return 0
                }
            })
            self.exercise.expected.sets = .repTotal(reps: repsArray)
            
            let totalReps = repsArray.reduce(0, {$0 + $1})
            let sets = Sets.repTotal(total: totalReps, rest: rest)
            self.setSets(sets)

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
        switch exercise.modality.sets {
        case .repTotal(total: _, rest: _):
            switch self.progress() {
            case .notStarted, .started:
                return "Set \(instance.current.setIndex+1)"
            case .finished:
                if instance.current.setIndex == 1 {
                    return "Finished"
                } else {
                    return "Finished using \(instance.current.setIndex) sets"
                }
            }
        default:
            let numSets = self.numSets()!
            switch self.progress() {
            case .notStarted, .started:
                return "Set \(instance.current.setIndex+1) of \(numSets)"
            case .finished:
                if numSets == 1 {
                    return "Finished"
                } else {
                    return "Finished all \(numSets) sets"
                }
            }

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
            if case .repTotal(reps: let repArray) = self.exercise.expected.sets {
                if instance.current.setIndex < repArray.count {
                    let reps = repArray[instance.current.setIndex]
                    if reps == 1 {
                        text = "Expecting 1 rep"
                    } else {
                        text = "Expecting \(reps) reps"
                    }
                }
            } else {
                ASSERT(false, "shouldn't land here")
                text = "error"
            }
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
            return ""
        }
    }

    func nextLabel() -> String {
        switch exercise.modality.sets {
        case .durations(_, targetSecs: _):
            if self.finished {
                return "Done"
            } else {
                return "Start"
            }
        default:
            if self.finished {
                return "Done"
            } else {
                return "Next"
            }
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

        case .repTotal(total: let totalReps, rest: _):
            if case .repTotal(reps: let repArray) = self.exercise.expected.sets {
                if repArray.isEmpty {
                    setStrs = ["\(totalReps) reps"]
                } else {
                    setStrs = ["\(totalReps) reps over \(repArray.count) sets"]
                }
            } else {
                ASSERT(false, "shouldn't have landed here")
            }
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
        let title = self.getSetTimerTitle("Set")
        switch self.exercise.modality.sets {
        case .durations(let durations, targetSecs: _):
            return TimerView(title: title, duration: durations[self.setIndex].secs, secondDuration: self.restDuration())
        case .fixedReps(let sets):
            return TimerView(title: title, duration: sets[self.setIndex].restSecs)
        case .repTotal(total: _, rest: let rest):
            return TimerView(title: title, duration: rest)
        default:
            return TimerView(title: "not implemented", duration: 120)
        }
    }
    
    // User pressed the Start Timer button.
    func explicitTimer() -> TimerView {
        var title: String
        switch self.progress() {
        case .notStarted, .started:
            title = getSetTimerTitle("On set")
        case .finished:
            title = "Finished"
        }

        let secs = self.restDuration()
        return TimerView(title: title, duration: secs > 0 ? secs : 60)
    }

    func view(_ program: ProgramVM) -> AnyView {
        switch self.exercise.modality.sets {
        case .durations(_, _):
            return AnyView(DurationsView(program, self))

        case .fixedReps(_):
            return AnyView(FixedRepsView(program, self))

        case .maxReps(_, _):
            return AnyView(Text("not implemented"))

        case .repRanges(_, _, _):
            return AnyView(Text("not implemented"))

        case .repTotal(total: _, rest: _):
            return AnyView(RepTotalView(program, self))
        }
    }

    func restDuration() -> Int {
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
        case .repTotal(total: _, rest: let rest):
            return rest
        }

        return secs
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

