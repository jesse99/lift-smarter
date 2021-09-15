//  Created by Jesse Vorisek on 9/13/21.
import Foundation

func getTitle(_ exercise: Exercise, _ instance: ExerciseInstance) -> String {
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

func getSubTitle(_ exercise: Exercise, _ instance: ExerciseInstance) -> String {
    switch exercise.modality.sets {
    case .durations(let durations, targetSecs: let targetSecs):
        // TODO: If there is an expected weight I think we'd annotate subTitle.
        if instance.current.setIndex < durations.count {
            let duration = durations[instance.current.setIndex]
            if targetSecs.count > 0 {
                let target = targetSecs[instance.current.setIndex]
                return "\(duration) (target is \(target)s)"
            } else {
                return "\(duration)"
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

func getSubSubTitle(_ exercise: Exercise, _ instance: ExerciseInstance) -> String {
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
