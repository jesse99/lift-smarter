//  Created by Jesse Vorisek on 9/11/21.
import Foundation

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
    let set = RepsSet(reps: RepRange(min: 8, max: 12), restSecs: 120)
    let info = RepRangesInfo(warmups: [], worksets: [set, set, set], backoffs: [])
    return .repRanges(info)
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
        let warmup = RepsSet(reps: RepRange(min: 4, max: 4), percent: WeightPercent(0.0), restSecs: 90)
        let work = RepsSet(reps: RepRange(min: 4, max: 8), restSecs: 3*60)
        let info = RepRangesInfo(warmups: [warmup], worksets: [work, work, work], backoffs: [])
        info.expectedWeight = 16.4
        info.expectedReps = [ActualRepRange(reps: 4, percent: 0.5),
                            ActualRepRange(reps: 8, percent: 1.0), ActualRepRange(reps: 8, percent: 1.0), ActualRepRange(reps: 8, percent: 1.0)]
        return Exercise("Split Squat", "Body-weight Split Squat", .fixedWeights(name: "Dumbbells"), .repRanges(info))
    }

    func lunge() -> Exercise {
        let work = RepsSet(reps: RepRange(min: 4, max: 8), restSecs: 150)
        let work2 = RepsSet(reps: RepRange(min: 4, max: 8), restSecs: 0)
        let info = RepRangesInfo(warmups: [], worksets: [work, work, work2], backoffs: [])
        info.expectedWeight = 16.4
        info.expectedReps = [ActualRepRange(reps: 8, percent: 1.0), ActualRepRange(reps: 8, percent: 1.0), ActualRepRange(reps: 8, percent: 1.0)]
        return Exercise("Lunge", "Dumbbell Lunge", .fixedWeights(name: "Dumbbells"), .repRanges(info))
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
        info.expectedReps = [20, 20, 10]
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
        info.expectedReps = [10,10,10]
        return Exercise("Curls", "Hammer Curls", .fixedWeights(name: "Dumbbells"), .maxReps(info))
     }

    func latRaise() -> Exercise {
        let work = RepsSet(reps: RepRange(min: 4, max: 12), restSecs: 120)
        let info = RepRangesInfo(warmups: [], worksets: [work, work, work], backoffs: [])
        info.expectedWeight = 8.2
        info.expectedReps = [ActualRepRange(reps: 12, percent: 1.0), ActualRepRange(reps: 12, percent: 1.0), ActualRepRange(reps: 12, percent: 1.0)]
        return Exercise("Lateral Raise", "Side Lateral Raise", .fixedWeights(name: "Dumbbells"), .repRanges(info))
    }

    func tricepPress() -> Exercise {
        let work = FixedRepsSet(reps: FixedReps(15), restSecs: 0)
        let info = ExerciseInfo.fixedReps(FixedRepsInfo(reps: [work]))
        return Exercise("Triceps Press", "Standing Triceps Press", .fixedWeights(name: "Dumbbells"), info)
    }
    
    let rehabExercises = [shoulderFlexion(), bicepsStretch(), externalRotation(), sleeperStretch()]
    let mobilityExercises = [foamRolling(), ironCross(), vSit(), frog(), fireHydrant(), mountain(), cossack(), piriformis()]
    let lowerExercises = [foamRolling(), splitSquats(), lunge()]
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
        splitSquats(), lunge(),
        planks(), pushup(), reversePlank(), curls(), latRaise(), tricepPress()]
    return Program("Home", workouts, exercises, weeksStart: date)

}

func mockModel() -> Model {
    let program = mockProgram()
    let model = Model(program)
    model.fixedWeights = ["Dumbbells": FixedWeightSet([5, 10, 20, 25, 35]), "Cable machine": FixedWeightSet([10, 20, 30, 40, 50, 60, 70, 80, 90, 100])]
    return model
}
