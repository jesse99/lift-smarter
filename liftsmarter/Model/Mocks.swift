//  Created by Jesse Vorisek on 9/11/21.
import Foundation

let defaultDeadPlates = Plates([
    Plate(weight: 45, count: 4, type: .bumper),
    Plate(weight: 35, count: 4, type: .bumper),
    Plate(weight: 25, count: 4, type: .bumper),
    Plate(weight: 10, count: 4, type: .standard),
    Plate(weight: 5, count: 4, type: .standard)
])

let defaultDualPlates = Plates([
    Plate(weight: 45, count: 4, type: .standard),
    Plate(weight: 35, count: 4, type: .standard),
    Plate(weight: 25, count: 4, type: .standard),
    Plate(weight: 10, count: 4, type: .standard),
    Plate(weight: 5, count: 4, type: .standard)
])

let defaultSinglePlates = Plates([
    Plate(weight: 45, count: 2, type: .standard),   // don't need to use as many plates here and Plates.getAll is kinda slow with single plates
    Plate(weight: 35, count: 2, type: .standard),
    Plate(weight: 25, count: 2, type: .standard),
    Plate(weight: 10, count: 2, type: .standard),
    Plate(weight: 5, count: 2, type: .standard)
])

func defaultDurations() -> ExerciseInfo {
    let set = DurationSet(secs: 120, restSecs: 0)
    let info = DurationsInfo(sets: [set, set])
    return .durations(info)
}

func defaultFixedReps() -> ExerciseInfo {
    let set = FixedRepsSet(reps: FixedReps(8), restSecs: 60)
    let info = FixedRepsInfo(reps: [set, set, set])
    return .fixedReps(info)
}

func defaultMaxReps() -> ExerciseInfo {
    let info = MaxRepsInfo(restSecs: [60, 60, 60], targetReps: 24)
    return .maxReps(info)
}

func defaultRepRanges() -> ExerciseInfo {
    let set = RepsSet(reps: RepRange(min: 8, max: 12), restSecs: 120, stage: .workset)
    let info = RepRangesInfo(sets: [set, set, set])
    return .repRanges(info)
}

func defaultPercentage() -> ExerciseInfo {
    let info = PercentageInfo(percent: 0.6, rest: 120, baseName: "none")
    return .percentage(info)
}

func defaultRepTotal() -> ExerciseInfo {
    let info = RepTotalInfo(total: 24, rest: 60)
    return .repTotal(info)
}

func mockProgram() -> Program {
    // https://www.defrancostraining.com/joe-ds-qlimber-11q-flexibility-routine/
    func foamRolling() -> Exercise {
        let work = FixedRepsSet(reps: FixedReps(15), restSecs: 30)
        let info = ExerciseInfo.fixedReps(FixedRepsInfo(reps: [work, work]))
        return Exercise("Foam Rolling", "IT-Band Foam Roll", .bodyWeight, info)
    }

    func ironCross() -> Exercise {
        let work = FixedRepsSet(reps: FixedReps(10), restSecs: 0)
        let info = ExerciseInfo.fixedReps(FixedRepsInfo(reps: [work]))
        return Exercise("Bent-knee Iron Cross", "Bent-knee Iron Cross", .bodyWeight, info)
    }

    func vSit() -> Exercise {
        let work = FixedRepsSet(reps: FixedReps(15), restSecs: 0)
        let info = ExerciseInfo.fixedReps(FixedRepsInfo(reps: [work]))
        return Exercise("Roll-over into V-sit", "Roll-over into V-sit", .bodyWeight, info)
    }

    func frog() -> Exercise {
        let work = FixedRepsSet(reps: FixedReps(10), restSecs: 0)
        let info = ExerciseInfo.fixedReps(FixedRepsInfo(reps: [work]))
        return Exercise("Rocking Frog Stretch", "Rocking Frog Stretch", .bodyWeight, info)
    }

    func fireHydrant() -> Exercise {
        let work = FixedRepsSet(reps: FixedReps(10), restSecs: 0)
        let info = ExerciseInfo.fixedReps(FixedRepsInfo(reps: [work]))
        return Exercise("Fire Hydrant Hip Circle", "Fire Hydrant Hip Circle", .bodyWeight, info)
    }

    func mountain() -> Exercise {
        let work = FixedRepsSet(reps: FixedReps(10), restSecs: 30)
        let info = ExerciseInfo.fixedReps(FixedRepsInfo(reps: [work]))
        return Exercise("Mountain Climber", "Mountain Climber", .bodyWeight, info)
    }

    func cossack() -> Exercise {
        let work = FixedRepsSet(reps: FixedReps(10), restSecs: 0)
        let info = ExerciseInfo.fixedReps(FixedRepsInfo(reps: [work]))
        return Exercise("Cossack Squat", "Cossack Squat", .bodyWeight, info)
    }

    func piriformis() -> Exercise {
        let durations = [DurationSet(secs: 30, restSecs: 0), DurationSet(secs: 30, restSecs: 0)]
        let info = ExerciseInfo.durations(DurationsInfo(sets: durations))
        return Exercise("Piriformis Stretch", "Seated Piriformis Stretch", .bodyWeight, info)
    }
    
    // Rehab
    func shoulderFlexion() -> Exercise {
        let work = FixedRepsSet(reps: FixedReps(12), restSecs: 0)
        let info = ExerciseInfo.fixedReps(FixedRepsInfo(reps: [work]))
        return Exercise("Shoulder Flexion", "Single Shoulder Flexion", .bodyWeight, info)
    }
    
    func bicepsStretch() -> Exercise {
        let durations = [
            DurationSet(secs: 15, restSecs: 30),
            DurationSet(secs: 15, restSecs: 30),
            DurationSet(secs: 15, restSecs: 0)]
        let info = ExerciseInfo.durations(DurationsInfo(sets: durations))
        return Exercise("Biceps Stretch", "Wall Biceps Stretch", .bodyWeight, info)
    }
    
    func externalRotation() -> Exercise {
        let work = FixedRepsSet(reps: FixedReps(15), restSecs: 0)
        let info = ExerciseInfo.fixedReps(FixedRepsInfo(reps: [work]))
        return Exercise("External Rotation", "Lying External Rotation", .bodyWeight, info)
    }
    
    func sleeperStretch() -> Exercise {
        let durations = [
            DurationSet(secs: 30, restSecs: 0),
            DurationSet(secs: 30, restSecs: 0),
            DurationSet(secs: 30, restSecs: 0)]
        let info = ExerciseInfo.durations(DurationsInfo(sets: durations))
        return Exercise("Sleeper Stretch", "Sleeper Stretch", .bodyWeight, info)
    }

    // https://www.builtlean.com/2012/04/10/dumbbell-complex
    // DBCircuit looks to be a harder version of this
//    func perry() -> Exercise {
//        let work = RepsSet(reps: RepRange(6)!, restSecs: 30)!   // TODO: ideally woulf use no rest
//        let sets = Sets.repRanges(warmups: [], worksets: [work, work, work], backoffs: [])  // TODO: want to do up to six sets
//        let modality = Modality(Apparatus.bodyWeight, sets)
//        return Exercise("Complex", "Perry Complex", modality, overridePercent: "Squat, Lunge, Row, Curl&Press")
//    }

    // Lower
    // progression: https://old.reddit.com/r/bodyweightfitness/wiki/exercises/squat
    func splitSquats() -> Exercise {
        let warmup = RepsSet(reps: RepRange(min: 4, max: 4), percent: WeightPercent(0.7), restSecs: 90, stage: .warmup)
        let work = RepsSet(reps: RepRange(min: 4, max: 8), restSecs: 3*60, stage: .workset)
        let info = RepRangesInfo(sets: [warmup] + [work, work, work])
        info.expectedWeight = 16.4
        return Exercise("Split Squat", "Body-weight Split Squat", .bells(name: "Dumbbells"), .repRanges(info))
    }

    func lightSquats() -> Exercise {
        let info = PercentageInfo(percent: 0.6, rest: 120, baseName: "Split Squat")
        return Exercise("Light Squat", "Body-weight Split Squat", .bells(name: "Dumbbells"), .percentage(info))
    }

    func deadlift() -> Exercise {
        let warmup = RepsSet(reps: RepRange(min: 4, max: 4), percent: WeightPercent(0.7), restSecs: 90, stage: .warmup)
        let work = RepsSet(reps: RepRange(min: 4, max: 8), restSecs: 3*60, stage: .workset)
        let info = RepRangesInfo(sets: [warmup] + [work, work, work])
        info.expectedWeight = 225
        return Exercise("Deadlift", "Deadlift", .dualPlates(barWeight: 56, "Deadlift"), .repRanges(info))
    }

    func lunge() -> Exercise {
        let work = RepsSet(reps: RepRange(min: 4, max: 8), restSecs: 150, stage: .workset)
        let work2 = RepsSet(reps: RepRange(min: 4, max: 8), restSecs: 0, stage: .workset)
        let info = RepRangesInfo(sets: [work, work, work2])
        info.expectedWeight = 16.4
        return Exercise("Lunge", "Dumbbell Lunge", .bells(name: "Dumbbells"), .repRanges(info))
    }

    // Upper
    func planks() -> Exercise { // TODO: this should be some sort of progression
        let durations = [
            DurationSet(secs: 50, restSecs: 2*60),
            DurationSet(secs: 50, restSecs: 2*60),
            DurationSet(secs: 50, restSecs: 2*60)]
        let info = ExerciseInfo.durations(DurationsInfo(sets: durations, targetSecs: [60, 60, 60]))
        return Exercise("Front Plank", "Front Plank", .bodyWeight, info)
    }
    
    func pushup() -> Exercise {
        let info = RepTotalInfo(total: 50, rest: 60)
        return Exercise("Pushup", "Pushup", .bodyWeight, .repTotal(info))
    }

    func reversePlank() -> Exercise { // TODO: this should be some sort of progression
        let durations = [
            DurationSet(secs: 50, restSecs: 90),
            DurationSet(secs: 50, restSecs: 90),
            DurationSet(secs: 50, restSecs: 90)]
        let info = ExerciseInfo.durations(DurationsInfo(sets: durations, targetSecs: [60, 60, 60]))
        return Exercise("Reverse Plank", "Reverse Plank", .bodyWeight, info)
    }
    
    func curls() -> Exercise {
        let info = MaxRepsInfo(restSecs: [90, 90, 90], targetReps: nil)
        info.expectedWeight = 16.4
        return Exercise("Curls", "Hammer Curls", .bells(name: "Dumbbells"), .maxReps(info))
     }

    func latRaise() -> Exercise {
        let work = RepsSet(reps: RepRange(min: 4, max: 12), restSecs: 120, stage: .workset)
        let info = RepRangesInfo(sets: [work, work, work])
        info.expectedWeight = 8.2
        return Exercise("Lateral Raise", "Side Lateral Raise", .bells(name: "Dumbbells"), .repRanges(info))
    }

    func tricepPress() -> Exercise {
        let work = FixedRepsSet(reps: FixedReps(15), restSecs: 0)
        let info = ExerciseInfo.fixedReps(FixedRepsInfo(reps: [work]))
        return Exercise("Triceps Press", "Standing Triceps Press", .bells(name: "Dumbbells"), info)
    }
    
    let rehabExercises = [shoulderFlexion(), bicepsStretch(), externalRotation(), sleeperStretch()]
    let mobilityExercises = [foamRolling(), ironCross(), vSit(), frog(), fireHydrant(), mountain(), cossack(), piriformis()]
    let lowerExercises = [foamRolling(), splitSquats(), lightSquats(), lunge(), deadlift()]
    let upperExercises = [foamRolling(), planks(), pushup(), reversePlank(), curls(), latRaise(), tricepPress()]
    
    let rehab = Workout("Rehab", rehabExercises, schedule: .days([.saturday, .sunday, .tuesday, .thursday, .friday]))
    let mobility = Workout("Mobility", mobilityExercises, schedule: .days([.saturday, .sunday, .tuesday, .thursday, .friday]))
    let lower1 = Workout("Lower 1", lowerExercises, schedule: .days([.tuesday]))
    let lower2 = Workout("Lower 2", lowerExercises, schedule: .days([.thursday]))
    let upper = Workout("Upper", upperExercises, schedule: .days([.sunday]))

    let workouts = [rehab, mobility, lower1, lower2, upper]

    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy/MM/dd HH:mm"
    let date = formatter.date(from: "2021/09/06 09:00")!

    let exercises = [
        shoulderFlexion(), bicepsStretch(), externalRotation(), sleeperStretch(),
        foamRolling(), ironCross(), vSit(), frog(), fireHydrant(), mountain(), cossack(), piriformis(),
        splitSquats(), lightSquats(), lunge(), deadlift(),
        planks(), pushup(), reversePlank(), curls(), latRaise(), tricepPress()]
    return Program("Home", workouts, exercises, weeksStart: date)

}

func mockModel() -> Model {
    let program = mockProgram()
    let model = Model(program)
    model.bellsSet = ["Dumbbells": Bells([5, 10, 15, 20, 25, 30, 40, 50]), "Cable machine": Bells([10, 20, 30, 40, 50, 60, 70, 80, 90, 100])]
    return model
}
