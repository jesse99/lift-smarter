//  Created by Jesse Vorisek on 9/13/21.
import Foundation
import SwiftUI

// Suffix is normally either empty or something like " @ 10 lbs", or nil for no suffix at all.
func repRangeLabel(_ min: Int, _ max: Int?, suffix inSuffix: String?) -> String {
    var prefix: String
    if let max = max {
        if min == max {
            prefix = "\(min)"
        } else {
            prefix = "\(min)-\(max)"
        }
    } else {
        prefix = "\(min)+"
    }
    
    if var suffix = inSuffix {
        if suffix.isEmpty {
            if prefix == "1" {
                suffix = " rep"
            } else {
                suffix = " reps"
            }
        }
        
        return prefix + suffix
    } else {
        return prefix
    }
}

// This is used with exercises that are part of a particular workout.
class InstanceVM: Equatable, Identifiable, ObservableObject {
    let program: ProgramVM
    let workout: WorkoutVM
    let exercise: ExerciseVM
    private let instance: Exercise
    
    init(_ program: ProgramVM, _ workout: WorkoutVM, _ instance: Exercise) {
        ASSERT(workout.workout(instance).exercises.first(where: {$0 === instance}) != nil, "exercise must be in the workout")
        ASSERT(program.model(instance).program.exercises.first(where: {$0 === instance}) == nil, "exercise cannot be in the program")
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
            case .percentage(let info):
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
            case .percentage(let info):
                return info.current.startDate
            case .repRanges(let info):
                return info.current.startDate
            case .repTotal(let info):
                return info.current.startDate
            }
        }
    }

    func shouldReset() -> Bool {
        let numSets = self.exercise.numSets()
        if numSets > 0 {
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

        let numSets = self.exercise.numSets()
        if self.setIndex == 0 {
            return .notStarted
        } else if self.setIndex < numSets {
            return .started
        } else {
            return .finished
        }
    }
    
    func expectedReps() -> Int {
        return self.exercise.expectedReps(setIndex: self.setIndex)
    }
        
    func currentIsUnexpected() -> Bool {
        switch self.instance.info {
        case .maxReps(let info):
            return info.expectedReps != info.currentReps
        case .repRanges(let info):
            if !info.expectedReps.isEmpty {
                return info.expectedReps != info.currentReps
            } else {
                // Don't bother asking the user to update expected if the default expected works.
                let expected = info.sets.map({ActualRepRange(reps: $0.reps.min, percent: $0.percent.value, stage: $0.stage)})
                return info.expectedReps != expected
            }
        case .repTotal(let info):
            return info.expectedReps != info.currentReps
        case .durations, .fixedReps, .percentage:
            return false    // by definition these can't have unexpected
        }
    }

    func canAdvanceWeight() -> Bool {
        switch self.instance.info {
        case .repRanges(let info):
            if self.exercise.advancedWeight() != nil && info.currentReps.count >= info.sets.count {
                for i in 0..<info.sets.count {
                    if info.sets[i].stage == .workset {
                        if let maxReps = info.sets[i].reps.max {
                            if info.currentReps[i].reps < maxReps {
                                return false
                            }
                        } else {
                            return false    // set is min to inf
                        }
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
            return self.workout.name + "/" + self.exercise.name
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
        self.instance.info.resetCurrent(self.exercise.baseExpectedWeight)  // current applies to an exercise not all of them
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

        case .percentage(let info):
            if info.current.setIndex == 0 {
                info.current.startDate = now
            }

            ASSERT(reps == nil, "reps is for repRanges and repTotal")
            let reps = self.exercise.expectedReps(setIndex: info.current.setIndex)
            info.current.setIndex += 1
            info.currentReps.append(reps)
            finished = info.current.setIndex == self.exercise.numSets()

        case .repRanges(let info):
            if info.current.setIndex == 0 {
                info.current.startDate = now
            }

            let set = info.currentSet()
            info.current.setIndex += 1
            info.currentReps.append(ActualRepRange(reps: reps!, percent: set.percent.value, stage: set.stage))
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

            switch self.workout.schedule {
            case .cyclic(let n):
                let calendar = Calendar.current
                let date = calendar.date(byAdding: .day, value: n, to: now)!
                self.workout.setNextCyclic(date)
            default:
                break
            }
        }
    }
    
    // This one is a little unusual: it requires current but needs to update
    // all the exercises
    func updateExpected() {
        switch self.instance.info {
        case .durations, .fixedReps, .percentage:
            ASSERT(false, "nonsensical")

        case .maxReps(let info):
            info.expectedReps = info.currentReps

        case .repRanges(let info):
            info.expectedReps = info.currentReps

        case .repTotal(let info):
            info.expectedReps = info.currentReps
            info.total = info.currentReps.reduce(0, {$0 + $1})
        }

        self.program.modify(self.instance, callback: {$0.info = self.instance.info.clone()})
        
        let exercise = self.program.model(instance).program.exercises.first(where: {$0.name == self.name})!
        exercise.info.resetCurrent(0.0)    // validate expects program exercies to have default current
    }
}

// UI
extension InstanceVM {
    // DurationsView, FixedRepsView, etc
    func title(_ index: Int? = nil) -> String {
        let setIndex = index ?? self.setIndex
        switch self.instance.info {
        case .repTotal:
            switch self.progress() {
            case .notStarted, .started:
                return "Set \(setIndex+1)"
            case .finished:
                if setIndex == 1 {
                    return "Finished"
                } else {
                    return "Finished using \(setIndex) sets"
                }
            }
            
        case .percentage(let info):
            if let base = self.program.instances.first(where: {$0.name == info.baseName}) {
                switch base.exercise.info {
                case .durations:
                    return "'\(info.baseName)' cannot be a durations exercise"
                case .percentage:
                    return "'\(info.baseName)' cannot be a percentage exercise"
                case .repTotal:
                    return "'\(info.baseName)' cannot be a rep total exercise"
                default:
                    if setIndex < self.exercise.numSets() {
                        return base.title(setIndex)
                    } else {
                        return "Finished"
                    }
                }
            } else {
                return "'\(info.baseName)' exercise is missing"
            }
            
        case .repRanges(let info):
            switch self.progress() {
            case .notStarted, .started:
                let numWarmups = info.sets.filter({$0.stage == .warmup}).count
                let numWorksets = info.sets.filter({$0.stage == .workset}).count
                let numBackoff = info.sets.filter({$0.stage == .backoff}).count

                switch info.sets[setIndex].stage {
                case .warmup:
                    return "Warmup \(setIndex + 1) of \(numWarmups)"
                case .workset:
                    return "Workset \(setIndex - numWarmups + 1) of \(numWorksets)"
                case .backoff:
                    return "Backoff \(setIndex - numWarmups - numWorksets + 1) of \(numBackoff)"
                }

            case .finished:
                return "Finished"
            }
        default:
            break
        }
        
        let numSets = self.exercise.numSets()
        switch self.progress() {
        case .notStarted, .started:
            return "Set \(setIndex + 1) of \(numSets)"
        case .finished:
            if numSets == 1 {
                return "Finished"
            } else {
                return "Finished all \(numSets) sets"
            }
        }
    }

    func subTitle() -> String {
        var text = ""
        
        var weight = 0.0
        var percent = WeightPercent(1.0)
        var useBelow = true
        switch self.instance.info {
        case .durations(let info):
            weight = info.expectedWeight
            if info.current.setIndex < info.sets.count {
                let duration = info.sets[info.current.setIndex]
                let ds = friendlyMediumSecs(duration.secs)
                if info.targetSecs.count > 0 {
                    let target = info.targetSecs[info.current.setIndex]
                    let ts = friendlyMediumSecs(target)
                    text = "\(ds) (target is \(ts))"
                } else {
                    text = ds
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

        case .percentage(let info):
            let numSets = self.exercise.numSets()
            if info.current.setIndex < numSets {
                weight = self.exercise.expectedWeight(info.current.setIndex)
                let reps = self.exercise.expectedReps(setIndex: info.current.setIndex)
                if reps == 1 {
                    text = "1 rep"
                } else {
                    text = "\(reps) reps"
                }
                
                useBelow = info.percent >= 1.0
            }

        case .repRanges(let info):
            if info.current.setIndex < info.sets.count {
                let set = info.currentSet()
                weight = info.expectedWeight
                percent = set.percent
                
                let min = info.expectedReps.at(info.current.setIndex)?.reps ?? set.reps.min
                text = repRangeLabel(min, set.reps.max, suffix: "")
                
                useBelow = set.stage == .workset
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

        if weight > 0.0 && !self.finished {
            let closest = useBelow ? exercise.getClosestBelow(weight*percent) : exercise.getClosest(weight*percent)
            if case .right(let weight) = closest {
                let suffix = percent.value >= 0.01 && weight.total > epsilonWeight ? " @ " + friendlyUnitsWeight(weight.total) : ""
                text += suffix
                
                let p = Int(100*percent.value)
                if p != 100 {
                    text += " (\(p)%)"
                }
            }
        }

        return text
    }

    func subSubTitle() -> String {
        func combine(_ parts: [String]) -> [String] {
            var result: [String] = []
            
            var i = 0
            var count = 1
            while i < parts.count {
                if i + 1 < parts.count && parts[i] == parts[i + 1] {
                    count += 1
                } else {
                    if count > 1 {
                        if parts[i].contains(where: {$0 == " "}) {
                            result.append("\(parts[i]) x\(count)")
                        } else {
                            result.append("\(parts[i])x\(count)")
                        }
                    } else {
                        result.append(parts[i])
                    }
                    count = 1
                }
                i += 1
            }
            
            return result
        }
        
        func subSub(_ weight: Double, _ percent: WeightPercent, _ useBelow: Bool, ignoreSingle: Bool) -> String {
            let closest = useBelow ? exercise.getClosestBelow(weight*percent) : exercise.getClosest(weight*percent)
            if case .right(let weight) = closest {
                let parts: [String] = weight.weights.map({
                    if $0.label.isEmpty {
                        return friendlyWeight($0.weight)
                    } else {
                        return friendlyWeight($0.weight) + " " + $0.label
                    }
                })
                if parts.count == 1 && ignoreSingle {
                    return ""
                }
                return combine(parts).joined(separator: " + ")
            }
            return ""
        }
        
        if self.finished {
            return ""
        }

        var weight = 0.0
        var percent = WeightPercent(1.0)
        var useBelow = true
        var prefix = ""
        switch self.instance.info {
        case .durations(let info):
            prefix = info.label
            weight = info.expectedWeight
            if weight > 0.0 && !prefix.isEmpty {
                prefix += " @ "
            }

        case .fixedReps(let info):
            weight = info.expectedWeight

        case .maxReps(let info):
            if info.current.setIndex < info.expectedReps.count {
                weight = info.expectedWeight
            } else if info.currentReps.count != info.restSecs.count {
                weight = info.expectedWeight
            }

        case .percentage(let info):
            weight = self.exercise.expectedWeight(info.current.setIndex)
            useBelow = info.percent >= 1.0

        case .repRanges(let info):
            if info.current.setIndex < info.sets.count {
                let set = info.currentSet()
                weight = info.expectedWeight
                percent = set.percent
                useBelow = set.stage == .workset
            }

        case .repTotal(let info):
            weight = info.expectedWeight
        }
        
        switch self.exercise.apparatus {
        case .bells(name: let name):
            if let name = name, let bells = self.program.getBellsSet()[name], bells.extraAdds > 0 {
                return prefix + subSub(weight, percent, useBelow, ignoreSingle: true)
            }
        case .bodyWeight:
            // The sub-sub title is used to break down the weight into component parts (like plates).
            // That doesn't make sense for body-weight so we do nothing.
            return prefix
        case .dualPlates(barWeight: _, _):
            // Sub-sub title will be half the listed weight and is usually alaos affected by the bar weight.
            return prefix + subSub(weight, percent, useBelow, ignoreSingle: false)
        case .singlePlates(_):
            return prefix + subSub(weight, percent, useBelow, ignoreSingle: true)
        }
        return prefix
    }

    func notesLabel() -> String {
        // This is per the exercise not the instance. That's probably want people want though it does seem slightly confusing.
        var count = 0
        if let records = program.model(instance).history.records[self.name] {
            let weight = self.exercise.baseExpectedWeight
            var sets: [ActualSet]
            
            switch self.exercise.info {
            case .durations(let info):
                sets = info.sets.map({.duration(secs: $0.secs, percent: 1.0)})
            case .fixedReps(let info):
                sets = info.sets.map({.reps(count: $0.reps.reps, percent: 1.0)})
            case .maxReps(let info):
                sets = info.expectedReps.map({.reps(count: $0, percent: 1.0)})
            case .percentage(let info):
                let numSets = self.exercise.numSets()
                sets = (0..<numSets).map({.reps(count: self.exercise.expectedReps(setIndex: $0), percent: info.percent)})
            case .repRanges(let info):
                let worksets = info.expectedReps.filter({$0.stage == .workset})
                sets = worksets.map({.reps(count: $0.reps, percent: $0.percent)})
            case .repTotal(let info):
                sets = info.expectedReps.map({.reps(count: $0, percent: 1.0)})
            }
            
            for record in records.reversed() {
                if sameWeight(record.weight, weight) && record.sets == sets {
                    count += 1
                } else {
                    break
                }
            }

            if self.finished {
                return "Completed=\(records.count)"
            } else if count == 1 {
                return "Same as last  Completed=\(records.count)"
            } else if count >= 1 {
                return "Same x\(count+1)  Completed=\(records.count)"   // + 1 because current sets match previous sets
            } else {
                return "New  Completed=\(records.count)"
            }
        } else {
            return "New"
        }
    }
    
    func nextLabel() -> String {
        switch self.instance.info {
        case .durations(_):
            if self.finished {
                if self.currentIsUnexpected() || self.canAdvanceWeight() {
                    return "Done…"
                } else {
                    return "Done"
                }
            } else {
                return "Start"
            }
        default:
            if self.finished {
                if self.currentIsUnexpected() || self.canAdvanceWeight() {
                    return "Done…"
                } else {
                    return "Done"
                }
            } else {
                return "Next"
            }
        }
    }

    // For rest between sets.
    func restDuration(implicit: Bool, index: Int? = nil) -> Int {
        var secs = 0

        switch self.instance.info {
        case .durations(let info):
            let setIndex = index ?? info.current.setIndex
            if setIndex < info.sets.count {
                secs = info.sets[setIndex].restSecs
            }
            if !implicit && secs == 0 {
                secs = info.sets.max(by: {$0.restSecs < $1.restSecs})?.restSecs ?? 120
            }

        case .fixedReps(let info):
            let setIndex = index ?? info.current.setIndex
            if setIndex < info.sets.count {
                secs = info.sets[setIndex].restSecs
            }
            if !implicit && secs == 0 {
                secs = info.sets.max(by: {$0.restSecs < $1.restSecs})?.restSecs ?? 120
            }

        case .maxReps(let info):
            let setIndex = index ?? info.current.setIndex
            if setIndex < info.restSecs.count {
                secs = info.restSecs[setIndex]
            }
            if !implicit && secs == 0 {
                secs = info.restSecs.max(by: {$0 < $1}) ?? 120
            }

        case .percentage(let info):
            let setIndex = index ?? info.current.setIndex
            if let base = self.program.instances.first(where: {$0.name == info.baseName}) {
                if base.restDuration(implicit: implicit, index: setIndex) > 0 {
                    secs = info.rest
                }
            } else {
                secs = info.rest
            }

        case .repRanges(let info):
            let setIndex = index ?? info.current.setIndex
            if setIndex < info.sets.count {
                secs = info.sets[setIndex].restSecs
            }
            if !implicit && secs == 0 {
                secs = info.sets.max(by: {$0.restSecs < $1.restSecs})?.restSecs ?? 120
            }

        case .repTotal(let info):
            return info.rest
        }

        return secs
    }

    // ExerciseView
    func view(_ program: ProgramVM) -> AnyView {
        switch self.instance.info {
        case .durations:
            return AnyView(DurationsView(program, self))
        case .fixedReps:
            return AnyView(FixedRepsView(program, self))
        case .maxReps:
            return AnyView(MaxRepsView(program, self))
        case .percentage:
            return AnyView(PercentageView(program, self))
        case .repRanges:
            return AnyView(RepRangesView(program, self))
        case .repTotal:
            return AnyView(RepTotalView(program, self))
        }
    }

    // WorkoutView
    func workoutLabel() -> ([String], String, Int) {
        if let secs = restTime(self.id) {
            return ([friendlyMediumSecs(Int(secs)) + " left"], "", 1)
        }
        switch self.instance.info {
        case .percentage(let info):
            if let base = self.program.instances.first(where: {$0.name == info.baseName}) {
                return base.workoutLabel(percent: info.percent, useMax: false)
            }
        default:
            break
        }
        return self.workoutLabel(percent: 1.0, useMax: true)
    }
    
    private func workoutLabel(percent: Double, useMax: Bool) -> ([String], String, Int) {
        func getRepLabel(_ reps: Int) -> String {
            if reps == 1 {
                return "1 rep"
            } else {
                return "\(reps) reps"  // 5 reps
            }
        }
        
        func getRepRangeLabel(_ info: RepRangesInfo, _ index: Int, _ workset: RepsSet, ignoreWeight: Bool = false) -> String {
            let numWarmups = info.sets.filter({$0.stage == .warmup}).count
            let min = info.expectedReps.at(index + numWarmups)?.reps ?? workset.reps.min
            let wp = WeightPercent(percent*workset.percent.value)
            let suffix = ignoreWeight ? "" : weightSuffix(wp, info.expectedWeight)
            return repRangeLabel(min, useMax ? workset.reps.max : min, suffix: suffix)
        }
        
        var setStrs: [String] = []
        var trailer = ""
        var limit = 8

        switch self.instance.info {
        case .durations(let info):
            setStrs = info.sets.map({friendlyMediumSecs($0.secs)})
            trailer = weightSuffix(WeightPercent(percent), info.expectedWeight)

        case .fixedReps(let info):
            setStrs = info.sets.map({getRepLabel($0.reps.reps)})
            trailer = weightSuffix(WeightPercent(percent), info.expectedWeight)
            limit = 6

        case .maxReps(let info):
            if info.expectedReps.isEmpty {
                setStrs = ["\(info.restSecs.count)xAMRAP"]
            } else {
                setStrs = info.expectedReps.map({getRepLabel($0)})
            }
            trailer = weightSuffix(WeightPercent(percent), info.expectedWeight)

        case .percentage:
            log(.Error, "Should have a percentage exercise based on a percentage exercise")

        case .repRanges(let info):
            let worksets = info.sets.filter({$0.stage == .workset})
            if worksets.all({abs($0.percent.value - worksets.first!.percent.value) < 0.01}) {
                let wp = WeightPercent(percent*worksets.first!.percent)
                trailer = weightSuffix(wp, info.expectedWeight)
                setStrs = worksets.mapi({getRepRangeLabel(info, $0, $1, ignoreWeight: true)})
            } else {
                setStrs = worksets.mapi({getRepRangeLabel(info, $0, $1)})
            }

        case .repTotal(let info):
            if info.expectedReps.isEmpty {
                setStrs = ["\(info.total) reps"]
            } else {
                setStrs = ["\(info.total) reps over \(info.expectedReps.count) sets"]
            }
            trailer = weightSuffix(WeightPercent(percent), info.expectedWeight)
        }
        
        return (setStrs, trailer, limit)
    }
    
    private func getSetTimerTitle(_ prefix: String, index: Int? = nil, delta: Int = 0) -> String {
        let i = (index ?? self.setIndex) + delta
        switch self.instance.info {
        case .repRanges(let info):
            let numWarmups = info.sets.filter({$0.stage == .warmup}).count
            let numWorksets = info.sets.filter({$0.stage == .workset}).count
            let numBackoff = info.sets.filter({$0.stage == .backoff}).count

            switch info.sets[i].stage {
            case .warmup:
                return "Warmup \(prefix) \(i+1) of \(numWarmups)"
            case .workset:
                if numWarmups == 0 && numBackoff == 0 {
                    return "Workset \(prefix) \(i+1 - numWarmups) of \(numWorksets)"
                } else {
                    return "Workset \(prefix) \(i+1 - numWarmups) of \(numWorksets)"
                }
            case .backoff:
                return "Backoff \(prefix) \(i+1 - numWarmups - numWorksets) of \(numBackoff)"
            }
        default:
            let numSets = self.exercise.numSets()
            if numSets > 0 {
                return "\(prefix) \(i+1) of \(numSets)"
            } else {
                return "\(prefix) \(i+1)"
            }
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

