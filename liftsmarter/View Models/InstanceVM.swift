//  Created by Jesse Vorisek on 9/13/21.
import Foundation
import SwiftUI

// This is used with exercises that are part of a particular workout.
class InstanceVM: Equatable, Identifiable, ObservableObject {
    let program: ProgramVM
    let workout: WorkoutVM
    let exercise: ExerciseVM
    private let instance: Exercise
    
    init(_ program: ProgramVM, _ workout: WorkoutVM, _ instance: Exercise) {
        ASSERT(workout.workout(instance).exercises.contains(where: {$0.name == instance.name}), "exercise is missing from the workout")
        self.program = program
        self.workout = workout
        self.exercise = ExerciseVM(program, instance)
        self.instance = instance
    }
    
    func willChange() {
        self.objectWillChange.send()
        self.workout.willChange()
    }

    var name: String {
        get {return self.instance.name}
    }
    
    var formalName: String {
        get {return self.instance.formalName}
    }
    
    var enabled: Bool {
        get {return self.instance.enabled}
    }
    
    var setIndex: Int {
        get {
            switch self.instance.info {
            case .durations(let info):
                return info.current.setIndex
            case .fixedReps(let info):
                return info.current.setIndex
            case .maxReps(let info):
                return info.current.setIndex
            case .repRanges(let info):
                return info.current.setIndex
            case .repTotal(let info):
                return info.current.setIndex
            }
        }
    }

    var startDate: Date {
        get {
            switch self.instance.info {
            case .durations(let info):
                return info.current.startDate
            case .fixedReps(let info):
                return info.current.startDate
            case .maxReps(let info):
                return info.current.startDate
            case .repRanges(let info):
                return info.current.startDate
            case .repTotal(let info):
                return info.current.startDate
            }
        }
    }

    func shouldReset() -> Bool {
        if let numSets = self.exercise.numSets() {
            // 1) If it's been a long time since the user began the exercise then start over.
            // 2) If setIndex has become whacked as a result of user edits then start over.
            return Date().hoursSinceDate(self.startDate) > RecentHours || self.setIndex > numSets
        } else {
            return Date().hoursSinceDate(self.startDate) > RecentHours
        }
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
        if case .repTotal(let info) = self.instance.info {
            let currentReps = info.currentReps.reduce(0, {$0 + $1})
            if currentReps == 0 {
                return .notStarted
            } else if currentReps < info.total {
                return .started
            } else {
                return .finished
            }
        }

        if let numSets = self.exercise.numSets() {
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
        switch self.instance.info {
        case .maxReps(let info):
            return info.expectedReps.at(info.current.setIndex) ?? 1
        case .repRanges(let info):
            return info.expectedReps.at(info.current.setIndex)?.reps ?? 1
        case .repTotal(let info):
            return info.expectedReps.at(info.current.setIndex) ?? 1
        case .durations, .fixedReps:
            return nil
        }
    }
        
    func currentIsUnexpected() -> Bool {
        switch self.instance.info {
        case .maxReps(let info):
            return info.expectedReps != info.currentReps
        case .repRanges(let info):
            return info.expectedReps != info.currentReps
        case .repTotal(let info):
            return info.expectedReps != info.currentReps
        case .durations, .fixedReps:
            return false
        }
    }

    func canAdvanceWeight() -> Bool {
        switch self.instance.info {
        case .repRanges(let info):
            if self.exercise.advancedWeight() != nil && info.currentReps.count >= info.worksets.count {
                for i in 0..<info.worksets.count {
                    if let maxReps = info.worksets[i].reps.max {
                        if info.currentReps[i].reps < maxReps {
                            return false
                        }
                    } else {
                        return false    // set is min to inf
                    }
                }
                return true
            }
            
            return false
        default:
            return false
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

// Mutators
extension InstanceVM {
    func toggleEnabled() {
        self.willChange()
        self.instance.enabled = !self.instance.enabled
    }

    func resetCurrent() {
        self.willChange()
        switch self.instance.info {
        case .durations(let info):
            info.resetCurrent(weight: info.expectedWeight)  // current applies to an exercise not all of them
        case .fixedReps(let info):
            info.resetCurrent(weight: info.expectedWeight)
        case .maxReps(let info):
            info.resetCurrent(weight: info.expectedWeight)
        case .repRanges(let info):
            info.resetCurrent(weight: info.expectedWeight)
        case .repTotal(let info):
            info.resetCurrent(weight: info.expectedWeight)
        }
    }

    func appendCurrent(_ reps: Int? = nil, now: Date = Date()) {
        self.willChange()

        var finished = false
        switch self.instance.info {
        case .durations(let info):
            if info.current.setIndex == 0 {
                info.current.startDate = now
            }

            ASSERT(reps == nil, "reps is for repRanges and repTotal")
            let duration = info.sets[self.setIndex]
            info.current.setIndex += 1
            info.currentSecs.append(duration.secs)
            finished = info.current.setIndex == info.sets.count

        case .fixedReps(let info):
            if info.current.setIndex == 0 {
                info.current.startDate = now
            }

            ASSERT(reps == nil, "reps is for repRanges and repTotal")
            let reps = info.sets[self.setIndex].reps.reps
            info.current.setIndex += 1
            info.currentReps.append(reps)
            finished = info.current.setIndex == info.sets.count

        case .maxReps(let info):
            if info.current.setIndex == 0 {
                info.current.startDate = now
            }

            info.current.setIndex += 1
            info.currentReps.append(reps!)
            finished = info.current.setIndex == info.restSecs.count

        case .repRanges(let info):
            if info.current.setIndex == 0 {
                info.current.startDate = now
            }

            let set = info.currentSet()
            info.current.setIndex += 1
            info.currentReps.append(ActualRepRange(reps: reps!, percent: set.percent.value))
            finished = self.finished

        case .repTotal(let info):
            if info.current.setIndex == 0 {
                info.current.startDate = now
            }

            info.current.setIndex += 1
            info.currentReps.append(reps!)
            finished = self.finished
        }
        
        if finished {
            let history = self.program.history()
            history.append(workout, self, now)
            
            let workout = workout.workout(self.instance)
            workout.completed[self.name] = now
        }
    }
    
    // This one is a little unusual: it requires current but needs to update
    // all the exercises
    func updateExpected() {
        switch self.instance.info {
        case .durations(_), .fixedReps(_):
            ASSERT(false, "nonsensical")

        case .maxReps(let info):
            info.expectedReps = info.currentReps

        case .repRanges(let info):
            info.expectedReps = info.currentReps

        case .repTotal(let info):
            info.expectedReps = info.currentReps
            info.total = info.currentReps.reduce(0, {$0 + $1})
        }

        self.program.modify(self.instance, callback: {$0.info = self.instance.info})
    }
}

// UI
extension InstanceVM {
    // DurationsView, FixedRepsView, etc
    func title() -> String {
        switch self.instance.info {
        case .repTotal(let info):
            switch self.progress() {
            case .notStarted, .started:
                return "Set \(info.current.setIndex+1)"
            case .finished:
                if info.current.setIndex == 1 {
                    return "Finished"
                } else {
                    return "Finished using \(info.current.setIndex) sets"
                }
            }
        case .repRanges(let info):
            switch self.progress() {
            case .notStarted, .started:
                var index = info.current.setIndex
                
                if index < info.warmups.count {
                    return "Warmup \(index + 1) of \(info.warmups.count)"
                }
                index -= info.warmups.count

                if index < info.worksets.count {
                    return "Workset \(index + 1) of \(info.worksets.count)"
                }
                index -= info.worksets.count

                return "Backoff \(index + 1) of \(info.backoffs.count)"
            case .finished:
                return "Finished"
            }
        default:
            let numSets = self.exercise.numSets()!
            switch self.progress() {
            case .notStarted, .started:
                return "Set \(self.setIndex + 1) of \(numSets)"
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
        
        var weight = 0.0
        var percent = WeightPercent(1.0)
        switch self.instance.info {
        case .durations(let info):
            weight = info.expectedWeight
            if info.current.setIndex < info.sets.count {
                let duration = info.sets[info.current.setIndex]
                if info.targetSecs.count > 0 {
                    let target = info.targetSecs[info.current.setIndex]
                    text = "\(duration.secs)s (target is \(target)s)"   // TODO: might want to use some sort of shortTimeStr function
                } else {
                    text = "\(duration.secs)s"
                }
            }

        case .fixedReps(let info):
            weight = info.expectedWeight
            if info.current.setIndex < info.sets.count {
                let reps = info.sets[info.current.setIndex]
                if reps.reps.reps == 1 {
                    text = "1 rep"
                } else {
                    text = "\(reps.reps.reps) reps"
                }
            }

        case .maxReps(let info):
            if info.current.setIndex < info.expectedReps.count {
                weight = info.expectedWeight
                let reps = info.expectedReps[info.current.setIndex]
                text = "\(reps)+ reps"
            } else if info.currentReps.count == info.restSecs.count {
                text = ""
            } else {
                weight = info.expectedWeight
                text = "AMRAP"
            }

        case .repRanges(let info):
            if info.current.setIndex < info.expectedReps.count {
                let set = info.currentSet()
                weight = info.expectedWeight
                percent = set.percent
                
                if let max = set.reps.max {
                    let min = info.expectedReps.at(info.current.setIndex)?.reps ?? set.reps.min
                    text = "\(min)-\(max) reps"
                } else {
                    if set.reps.min == 1 {
                        text = "1 rep"
                    } else {
                        text = "\(set.reps.min) reps"
                    }
                }
            }
            
        case .repTotal(let info):
            weight = info.expectedWeight
            if info.current.setIndex < info.expectedReps.count {
                let reps = info.expectedReps[info.current.setIndex]
                if reps == 1 {
                    text = "1 rep"
                } else {
                    text = "\(reps) reps"
                }
            } else {
                let completed = info.currentReps.reduce(0, {$0 + $1})
                if completed < info.total {
                    text = "Up to \(info.total - completed) reps"
                } else {
                    text = ""
                }
            }
        }

        let closest = exercise.getClosestBelow(weight*percent)
        if case .right(let weight) = closest {
            let suffix = percent.value >= 0.01 && weight >= 0.1 ? " @ " + friendlyUnitsWeight(weight) : ""
            text += suffix
        }

        return text
    }

    // TODO: this would be stuff like plates
    func subSubTitle() -> String {
        switch self.instance.info {
        case .durations(_):
//        switch exercise.getClosest(self.display, exercise.expected.weight) {
//        case .right(let weight):
//            return weight >= 0.1 ? friendlyUnitsWeight(weight) : ""
//        case .left(let err):
//            return err
//        }
            return ""       // TODO: implement this

        case .fixedReps(_):
            return ""

        case .maxReps(_):
            return ""

        case .repRanges(_):
            return ""       // note that this one, at least, will depend upon setIndex

        case .repTotal(_):
            return ""
        }

    }

    func nextLabel() -> String {
        switch self.instance.info {
        case .durations(_):
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
    
    // For rest between sets.
    func implicitTimer(delta: Int = 0) -> TimerView {
        let title = self.getSetTimerTitle("Set", delta)
        switch self.instance.info {
        case .durations(let info):
            return TimerView(title: title, duration: info.sets[self.setIndex + delta].secs, secondDuration: self.restDuration())

        case .fixedReps(let info):
            return TimerView(title: title, duration: info.sets[self.setIndex + delta].restSecs)

        case .maxReps(let info):
            return TimerView(title: title, duration: info.restSecs[self.setIndex + delta])

        case .repRanges(let info):
            let set = info.currentSet(delta)
            return TimerView(title: title, duration: set.restSecs)

        case .repTotal(let info):
            return TimerView(title: title, duration: info.rest)
        }
    }
    
    func explicitTimer() -> TimerView {      // User pressed the Start Timer button.
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

    func restDuration() -> Int {
        var secs = 0

        switch self.instance.info {
        case .durations(let info):
            if info.current.setIndex < info.sets.count {
                secs = info.sets[info.current.setIndex].restSecs
            } else {
                secs = info.sets.last!.restSecs
            }

        case .fixedReps(let info):
            if info.current.setIndex < info.sets.count {
                secs = info.sets[info.current.setIndex].restSecs
            } else {
                secs = info.sets.last!.restSecs
            }

        case .maxReps(let info):
            if info.current.setIndex < info.restSecs.count {
                secs = info.restSecs[info.current.setIndex]
            } else {
                secs = info.restSecs.last!
            }

        case .repRanges(let info):
            let set = info.currentSet()
            return set.restSecs

        case .repTotal(let info):
            return info.rest
        }

        return secs
    }

    // ExerciseView
    func view(_ program: ProgramVM) -> AnyView {
        switch self.instance.info {
        case .durations(_):
            return AnyView(DurationsView(program, self))
        case .fixedReps(_):
            return AnyView(FixedRepsView(program, self))
        case .maxReps(_):
            return AnyView(MaxRepsView(program, self))
        case .repRanges(_):
            return AnyView(RepRangesView(program, self))
        case .repTotal(_):
            return AnyView(RepTotalView(program, self))
        }
    }

    // WorkoutView
    func workoutLabel() -> ([String], String, Int) {
        func getRepLabel(_ reps: Int) -> String {
            if reps == 1 {
                return "1 rep"
            } else {
                return "\(reps) reps"  // 5 reps
            }
        }
        
        func getRepRangeLabel(_ info: RepRangesInfo, _ index: Int, _ workset: RepsSet) -> String {
            let min = info.expectedReps.at(index + info.warmups.count)?.reps ?? workset.reps.min
            let max = workset.reps.max ?? min
            let suffix = weightSuffix(workset.percent, info.expectedWeight)
            if !suffix.isEmpty {
                if min == max {
                    if min == 1 {
                        return "1\(suffix)"
                    } else {
                        return "\(min)\(suffix)"
                    }
                } else {
                    return "\(min)-\(max)\(suffix)"
                }
            } else {
                if min == max {
                    if min == 1 {
                        return "1 rep"
                    } else {
                        return "\(min) reps"
                    }
                } else {
                    return "\(min)-\(max) reps"
                }
            }
        }
        
        var setStrs: [String] = []
        var trailer = ""
        var limit = 8

        switch self.instance.info {
        case .durations(let info):
            setStrs = info.sets.map({"\($0.secs)s"})
            trailer = weightSuffix(WeightPercent(1.0), info.expectedWeight)

        case .fixedReps(let info):
            setStrs = info.sets.map({getRepLabel($0.reps.reps)})
            trailer = weightSuffix(WeightPercent(1.0), info.expectedWeight)
            limit = 6

        case .maxReps(let info):
            if info.expectedReps.isEmpty {
                setStrs = ["\(info.restSecs.count)xAMRAP"]
            } else {
                setStrs = info.expectedReps.map({getRepLabel($0)})
            }
            trailer = weightSuffix(WeightPercent(1.0), info.expectedWeight)

        case .repRanges(let info):
            setStrs = info.worksets.mapi({getRepRangeLabel(info, $0, $1)})

        case .repTotal(let info):
            if info.expectedReps.isEmpty {
                setStrs = ["\(info.total) reps"]
            } else {
                setStrs = ["\(info.total) reps over \(info.expectedReps.count) sets"]
            }
            trailer = weightSuffix(WeightPercent(1.0), info.expectedWeight)
        }
        
        return (setStrs, trailer, limit)
    }
    
    private func getSetTimerTitle(_ prefix: String, _ delta: Int = 0) -> String {
        let i = self.setIndex + delta
        if let numSets = self.exercise.numSets() {
            return "\(prefix) \(i+1) of \(numSets)"
        } else {
            return "\(prefix) \(i+1)"
        }
    }
}

// View Model internals (views can't call these because they don't have direct access
// to model classes).
extension InstanceVM {
    func exercise(_ model: Model) -> Exercise {
        return self.exercise.exercise(model)
    }

    func exercise(_ workout: Workout) -> Exercise {
        return self.instance
    }
}

