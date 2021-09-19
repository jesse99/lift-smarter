//  Created by Jesse Vorisek on 9/11/21.
import Foundation

func mockProgram() -> Program {
    // https://www.defrancostraining.com/joe-ds-qlimber-11q-flexibility-routine/
    func formRolling() -> Exercise {
        let work = FixedRepsSet(reps: FixedReps(15), restSecs: 0)
        let sets = Sets.fixedReps([work])
        let modality = Modality(Apparatus.bodyWeight, sets)
        return Exercise("Foam Rolling", "IT-Band Foam Roll", modality)
    }

    func ironCross() -> Exercise {
        let work = FixedRepsSet(reps: FixedReps(10), restSecs: 0)
        let sets = Sets.fixedReps([work])
        let modality = Modality(Apparatus.bodyWeight, sets)
        return Exercise("Bent-knee Iron Cross", "Bent-knee Iron Cross", modality)
    }

    func vSit() -> Exercise {
        let work = FixedRepsSet(reps: FixedReps(15), restSecs: 0)
        let sets = Sets.fixedReps([work])
        let modality = Modality(Apparatus.bodyWeight, sets)
        return Exercise("Roll-over into V-sit", "Roll-over into V-sit", modality)
    }

    func frog() -> Exercise {
        let work = FixedRepsSet(reps: FixedReps(10), restSecs: 0)
        let sets = Sets.fixedReps([work])
        let modality = Modality(Apparatus.bodyWeight, sets)
        return Exercise("Rocking Frog Stretch", "Rocking Frog Stretch", modality)
    }

    func fireHydrant() -> Exercise {
        let work = FixedRepsSet(reps: FixedReps(10), restSecs: 0)
        let sets = Sets.fixedReps([work])
        let modality = Modality(Apparatus.bodyWeight, sets)
        return Exercise("Fire Hydrant Hip Circle", "Fire Hydrant Hip Circle", modality)
    }

    func mountain() -> Exercise {
        let work = FixedRepsSet(reps: FixedReps(10), restSecs: 30)
        let sets = Sets.fixedReps([work])
        let modality = Modality(Apparatus.bodyWeight, sets)
        return Exercise("Mountain Climber", "Mountain Climber", modality)
    }

    func cossack() -> Exercise {
        let work = FixedRepsSet(reps: FixedReps(10), restSecs: 0)
        let sets = Sets.fixedReps([work])
        let modality = Modality(Apparatus.bodyWeight, sets)
        return Exercise("Cossack Squat", "Cossack Squat", modality, Expected(weight: 0.0, sets: .fixedReps))
    }

    func piriformis() -> Exercise {
        let sets = Sets.durations([DurationSet(secs: 30, restSecs: 0), DurationSet(secs: 30, restSecs: 0)])
        let modality = Modality(Apparatus.bodyWeight, sets)
        return Exercise("Piriformis Stretch", "Seated Piriformis Stretch", modality)
    }
    
    // Rehab
    func shoulderFlexion() -> Exercise {
        let work = FixedRepsSet(reps: FixedReps(12), restSecs: 0)
        let sets = Sets.fixedReps([work])
        let modality = Modality(Apparatus.bodyWeight, sets)
        return Exercise("Shoulder Flexion", "Single Shoulder Flexion", modality)
    }
    
    func bicepsStretch() -> Exercise {
        let durations = [
            DurationSet(secs: 15, restSecs: 30),
            DurationSet(secs: 15, restSecs: 30),
            DurationSet(secs: 15, restSecs: 0)]
        let sets = Sets.durations(durations)
        let modality = Modality(Apparatus.bodyWeight, sets)
        return Exercise("Biceps Stretch", "Wall Biceps Stretch", modality)
    }
    
    func externalRotation() -> Exercise {
        let work = FixedRepsSet(reps: FixedReps(15), restSecs: 0)
        let sets = Sets.fixedReps([work])
        let modality = Modality(Apparatus.bodyWeight, sets)
        return Exercise("External Rotation", "Lying External Rotation", modality)
    }
    
    func sleeperStretch() -> Exercise {
        let durations = [
            DurationSet(secs: 30, restSecs: 0),
            DurationSet(secs: 30, restSecs: 0),
            DurationSet(secs: 30, restSecs: 0)]
        let sets = Sets.durations(durations)
        let modality = Modality(Apparatus.bodyWeight, sets)
        return Exercise("Sleeper Stretch", "Sleeper Stretch", modality)
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
        let sets = Sets.repRanges(warmups: [warmup], worksets: [work, work, work], backoffs: [])
        let modality = Modality(Apparatus.bodyWeight, sets)
        return Exercise("Split Squat", "Body-weight Split Squat", modality, Expected(weight: 16.4, sets: .repRanges(warmupsReps: [5,3], worksetsReps: [8,8,8], backoffsReps: [])))
    }

    func lunge() -> Exercise {
        let work = RepsSet(reps: RepRange(min: 4, max: 8), restSecs: 150)
        let work2 = RepsSet(reps: RepRange(min: 4, max: 8), restSecs: 0)
        let sets = Sets.repRanges(warmups: [], worksets: [work, work, work2], backoffs: [])
        let modality = Modality(Apparatus.bodyWeight, sets)
        return Exercise("Lunge", "Dumbbell Lunge", modality, Expected(weight: 16.4, sets: .repRanges(warmupsReps: [5,3], worksetsReps: [8,8,8], backoffsReps: [])))
    }

    // Upper
    func planks() -> Exercise { // TODO: this should be some sort of progression
        let durations = [
            DurationSet(secs: 50, restSecs: 2*60),
            DurationSet(secs: 50, restSecs: 2*60),
            DurationSet(secs: 50, restSecs: 2*60)]
        let sets = Sets.durations(durations, targetSecs: [60, 60, 60])
        let modality = Modality(Apparatus.bodyWeight, sets)
        return Exercise("Front Plank", "Front Plank", modality)
    }
    
    func pushup() -> Exercise {
        let work = RepsSet(reps: RepRange(min: 4, max: 12), restSecs: 150)
        let sets = Sets.repRanges(warmups: [], worksets: [work, work, work], backoffs: [])
        let modality = Modality(Apparatus.bodyWeight, sets)
        return Exercise("Pushup", "Pushup", modality, Expected(weight: 0.0, sets: .repRanges(warmupsReps: [5,3], worksetsReps: [10,10,10], backoffsReps: [])))
    }

    func reversePlank() -> Exercise { // TODO: this should be some sort of progression
        let durations = [
            DurationSet(secs: 50, restSecs: 90),
            DurationSet(secs: 50, restSecs: 90),
            DurationSet(secs: 50, restSecs: 90)]
        let sets = Sets.durations(durations, targetSecs: [60, 60, 60])
        let modality = Modality(Apparatus.bodyWeight, sets)
        return Exercise("Reverse Plank", "Reverse Plank", modality)
    }
    
    func curls() -> Exercise {
        let sets = Sets.maxReps(restSecs: [90, 90, 90])
        let modality = Modality(Apparatus.bodyWeight, sets)
        return Exercise("Curls", "Hammer Curls", modality, Expected(weight: 16.4, sets: .maxReps(reps: [10,10,10])))
     }

    func latRaise() -> Exercise {
        let work = RepsSet(reps: RepRange(min: 4, max: 12), restSecs: 120)
        let sets = Sets.repRanges(warmups: [], worksets: [work, work, work], backoffs: [])
        let modality = Modality(Apparatus.bodyWeight, sets)
        return Exercise("Lateral Raise", "Side Lateral Raise", modality, Expected(weight: 8.2, sets: .repRanges(warmupsReps: [], worksetsReps: [12,12,12], backoffsReps: [])))
    }

    func tricepPress() -> Exercise {
        let work1 = RepsSet(reps: RepRange(min: 4, max: 12), restSecs: 120)
        let work2 = RepsSet(reps: RepRange(min: 4, max: 12), restSecs: 0)
        let sets = Sets.repRanges(warmups: [], worksets: [work1, work1, work2], backoffs: [])
        let modality = Modality(Apparatus.bodyWeight, sets)
        return Exercise("Triceps Press", "Standing Triceps Press", modality, Expected(weight: 8.2, sets: .repRanges(warmupsReps: [], worksetsReps: [11,11,11], backoffsReps: [])))
    }
    
    let rehabExercises = [shoulderFlexion(), bicepsStretch(), externalRotation(), sleeperStretch()]
    let mobilityExercises = [formRolling(), ironCross(), vSit(), frog(), fireHydrant(), mountain(), cossack(), piriformis()]
    let lowerExercises = [splitSquats(), lunge()]
    let upperExercises = [planks(), pushup(), reversePlank(), curls(), latRaise(), tricepPress()]
    
    let rehab = Workout("Rehab", rehabExercises.map({$0.name}), schedule: .days([.saturday, .sunday, .tuesday, .thursday, .friday]))
    let mobility = Workout("Mobility", mobilityExercises.map({$0.name}), schedule: .days([.saturday, .sunday, .tuesday, .thursday, .friday]))
    let lower = Workout("Lower", lowerExercises.map({$0.name}), schedule: .days([.tuesday, .thursday, .saturday]))
    let upper = Workout("Upper", upperExercises.map({$0.name}), schedule: .days([.friday, .sunday]))

    let workouts = [rehab, mobility, lower, upper]
    let exercises = rehabExercises + mobilityExercises + lowerExercises + upperExercises

    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy/MM/dd HH:mm"
    let date = formatter.date(from: "2021/09/06 09:00")!

    return Program("Home", workouts, exercises, weeksStart: date)
}

func mockModel() -> Model {
    let program = mockProgram()
    return Model(program)
}
