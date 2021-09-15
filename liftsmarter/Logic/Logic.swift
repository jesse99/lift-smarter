//  Created by Jesse Vorisek on 9/11/21.
import Foundation

func defaultExpected(_ modality: Modality) -> Expected {
    // TODO: if apparatus is a fixed weight set then default weight to the smallest weight
    switch modality.sets {
    case .durations(_, _):
        return Expected(weight: 0.0, sets: .durations)

    case .fixedReps(_):
        return Expected(weight: 0.0, sets: .fixedReps)

    case .maxReps(_, _):
        return Expected(weight: 0.0, sets: .maxReps(reps: [8, 8, 8]))

    case .repRanges(warmups: let warmups, worksets: let worksets, backoffs: let backoff):
        let r1 = warmups.map({$0.reps.min})
        let r2 = worksets.map({$0.reps.min})
        let r3 = backoff.map({$0.reps.min})
        return Expected(weight: 0.0, sets: .repRanges(warmupsReps: r1, worksetsReps: r2, backoffsReps: r3))

    case .repTotal(total: _, rest: _):
        return Expected(weight: 0.0, sets: .repTotal(reps: [5, 5, 5]))
    }
}
