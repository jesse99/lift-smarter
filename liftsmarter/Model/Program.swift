//  Created by Jesse Vorisek on 9/9/21.
import Foundation

/// Used to manage the workouts the user is expected to perform on some schedule.
class Program {
    var name: String
    var workouts: [Workout]    // workout names must be unique
    var exercises: [Exercise]  // exercise names must be unique
    var restWeeks: [Int] = []  // empty => no rest, else 1-based weeks to de-schedule exercises (if they have allowRest on)
    var weeksStart: Date       // a date within week 1
    var exerciseClipboard: [Exercise] = []
//    var notes: [EditNote]

    init(_ name: String, _ workouts: [Workout], _ exercises: [Exercise], weeksStart: Date) {
        let names = workouts.map {$0.name}
        ASSERT_EQ(names.count, Set(names).count)

        let names2 = exercises.map {$0.name}
        ASSERT_EQ(names2.count, Set(names2).count)
        
        for workout in workouts {
            for exercise in workout.exercises {
                ASSERT(exercises.contains(where: {$0.name == exercise.name}), "program is missing workout exercise \(exercise.name)")
                ASSERT(!exercises.contains(where: {$0 === exercise}), "workout should have a cloned version of exercise \(exercise.name)")
            }
        }

        self.name = name
        self.workouts = workouts
        self.exercises = exercises.sorted(by: {$0.name < $1.name})
        self.weeksStart = weeksStart
//        self.notes = []
//        self.addNote("Created")
        
        self.validate()
    }
    
    // TODO: can we put this behind a flag? or maybe only when run on a sim or one of my devices? Use #if DEBUG?
    func validate() {
        ASSERT(!self.name.isBlankOrEmpty(), "program name cannot be empty")
        
        var names = self.exercises.map {$0.name}
        ASSERT_EQ(names.count, Set(names).count, "program exercise names must be unique")

        names = self.workouts.map {$0.name}
        ASSERT_EQ(names.count, Set(names).count, "workout names must be unique")
        
        var instances = Set<ObjectIdentifier>()
        for exercise in self.exercises {
            let id = ObjectIdentifier(exercise)
            ASSERT(!instances.contains(id), "exercise identities must be unique")
            instances.update(with: id)

            self.validate(exercise, inProgram: true)
        }

        // These are not copied until it's required so we can't do an identity check.
        for exercise in self.exerciseClipboard {
            self.validate(exercise, inProgram: false)
        }

        for workout in self.workouts {
            self.validate(&instances, workout)
        }
    }

    private func validate(_ instances: inout Set<ObjectIdentifier>, _ workout: Workout) {
        ASSERT(!workout.name.isBlankOrEmpty(), "workout name cannot be empty")

        let names = workout.exercises.map {$0.name}
        ASSERT_EQ(names.count, Set(names).count, "workout exercise names must be unique")

        for exercise in workout.exercises {
            let id = ObjectIdentifier(exercise)
            ASSERT(!instances.contains(id), "exercise identities must be unique")
            instances.update(with: id)

            ASSERT(self.exercises.contains(where: {$0.name == exercise.name}), "workout exercises must also be in the program")
            self.validate(exercise, inProgram: false)
        }
    }
    
    private func validate(_ exercise: Exercise, inProgram: Bool) {
        ASSERT(!exercise.name.isBlankOrEmpty(), "exercise name cannot be empty")

        switch exercise.info {
        case .durations(let info):
            ASSERT(info.sets.count > 0, "must have at least one set")
            ASSERT(info.targetSecs.isEmpty || info.targetSecs.count == info.sets.count, "targetSecs must match sets")
            ASSERT(info.currentSecs.count <= info.sets.count, "currentSecs must match sets")
            ASSERT(info.current.setIndex <= info.sets.count, "setIndex must match sets")
            
        case .fixedReps(let info):
            ASSERT(info.sets.count > 0, "must have at least one set")
            ASSERT(info.currentReps.count <= info.sets.count, "currentReps must match sets")
            ASSERT(info.current.setIndex <= info.sets.count, "setIndex must match sets")

        case .maxReps(let info):
            ASSERT(info.restSecs.count > 0, "must have at least one set")
            ASSERT(info.expectedReps.isEmpty || info.expectedReps.count == info.restSecs.count, "expectedReps must match sets")
            ASSERT(info.currentReps.count <= info.restSecs.count, "currentReps must match sets")
            ASSERT(info.current.setIndex <= info.restSecs.count, "setIndex must match sets")
            
        case .repRanges(let info):
            ASSERT(info.sets.first(where: {$0.stage == .workset}) != nil, "must have at least one workset")
            
            ASSERT(info.expectedReps.isEmpty || info.expectedReps.count == info.sets.count, "expectedReps must match sets")
            if !info.expectedReps.isEmpty {
                for i in 0..<info.sets.count {
                    ASSERT(info.expectedReps[i].stage == info.sets[i].stage, "expected must match sets")
                }
            }
            
            ASSERT(info.currentReps.count <= info.sets.count, "currentReps must match sets")
            ASSERT(info.current.setIndex <= info.sets.count, "setIndex must match sets")
            
        case .repTotal(let info):
            ASSERT(info.total > 0, "at least one rep is required")
            // Note that expectedReps can be empty and currentReps.count can be smaller or larger than expectedReps
        }

        // Most state within a workout exercise should match that of the exercise in the program.
        if !inProgram {
            let parent = self.exercises.first(where: {$0.name == exercise.name})!
            
            // exercise.name - matched above
            ASSERT(exercise.formalName == parent.formalName, "formalName must match")
            ASSERT(exercise.apparatus == parent.apparatus, "apparatus must match")
            validateInfos(exercise, parent)
            ASSERT(exercise.allowRest == parent.allowRest, "allowRest must match")
            ASSERT(exercise.overridePercent == parent.overridePercent, "overridePercent must match")
            ASSERT(exercise.formalName == parent.formalName, "formalName must match")
            // exercise.enabled - per workout
        }
    }
    
    private func validateInfos(_ exercise: Exercise, _ parent: Exercise) {
        switch exercise.info {
        case .durations(let info):
            switch parent.info {
            case .durations(let pinfo):
                self.validateInfos(info, pinfo)
            default:
                ASSERT(false, "workout exercise and program exercise infos don't match")
            }
        case .fixedReps(let info):
            switch parent.info {
            case .fixedReps(let pinfo):
                self.validateInfos(info, pinfo)
            default:
                ASSERT(false, "workout exercise and program exercise infos don't match")
            }
        case .maxReps(let info):
            switch parent.info {
            case .maxReps(let pinfo):
                self.validateInfos(info, pinfo)
            default:
                ASSERT(false, "workout exercise and program exercise infos don't match")
            }
        case .repRanges(let info):
            switch parent.info {
            case .repRanges(let pinfo):
                self.validateInfos(info, pinfo)
            default:
                ASSERT(false, "workout exercise and program exercise infos don't match")
            }
        case .repTotal(let info):
            switch parent.info {
            case .repTotal(let pinfo):
                self.validateInfos(info, pinfo)
            default:
                ASSERT(false, "workout exercise and program exercise infos don't match")
            }
        }
    }

    // Everything should match within infos except current.
    private func validateInfos(_ info: DurationsInfo, _ parent: DurationsInfo) {
        ASSERT(info.sets == parent.sets, "sets must match")
        ASSERT(info.targetSecs == parent.targetSecs, "targetSecs must match")
        ASSERT(info.expectedWeight == parent.expectedWeight, "expectedWeight must match")
    }

    private func validateInfos(_ info: FixedRepsInfo, _ parent: FixedRepsInfo) {
        ASSERT(info.sets == parent.sets, "sets must match")
        ASSERT(info.expectedWeight == parent.expectedWeight, "expectedWeight must match")
    }

    private func validateInfos(_ info: MaxRepsInfo, _ parent: MaxRepsInfo) {
        ASSERT(info.restSecs == parent.restSecs, "restSecs must match")
        ASSERT(info.targetReps == parent.targetReps, "targetReps must match")
        ASSERT(info.expectedWeight == parent.expectedWeight, "expectedWeight must match")
        ASSERT(info.expectedReps == parent.expectedReps, "expectedReps must match")
    }

    private func validateInfos(_ info: RepRangesInfo, _ parent: RepRangesInfo) {
        ASSERT(info.sets == parent.sets, "sets must match")
        ASSERT(info.expectedWeight == parent.expectedWeight, "expectedWeight must match")
        ASSERT(info.expectedReps == parent.expectedReps, "expectedReps must match")
    }

    private func validateInfos(_ info: RepTotalInfo, _ parent: RepTotalInfo) {
        ASSERT(info.total == parent.total, "total must match")
        ASSERT(info.rest == parent.rest, "rest must match")
        ASSERT(info.expectedWeight == parent.expectedWeight, "expectedWeight must match")
        ASSERT(info.expectedReps == parent.expectedReps, "expectedReps must match")
    }
}

