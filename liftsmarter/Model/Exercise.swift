//  Created by Jesse Vorisek on 9/9/21.
import Foundation

let RecentHours = 8.0

/// An Exercise all the details for how to do a particular movement.
class Exercise {
    var name: String            // "Heavy Bench"
    var formalName: String      // "Bench Press"
    var modality: Modality
    var expected: Expected      // this may not always be ideal, but user's can always add a second version of an exercise
    var allowRest: Bool         // respect rest weeks
    var overridePercent: String // used to replace the normal weight percent label in exercise views with custom text

    init(_ name: String, _ formalName: String, _ modality: Modality, _ expected: Expected, overridePercent: String = "") {
        ASSERT_EQ(modality.sets.caseIndex(), expected.sets.caseIndex())
        self.name = name
        self.formalName = formalName
        self.modality = modality
        self.expected = expected
        self.allowRest = true
        self.overridePercent = overridePercent
    }
        
    convenience init(_ name: String, _ formalName: String, _ modality: Modality) {
        self.init(name, formalName, modality, defaultExpected(modality))
    }
        
    func isBodyWeight() -> Bool {
        switch self.modality.apparatus {
        case .bodyWeight:
            return true
        default:
            return false
        }
    }

    func getClosestBelow(_ model: Model, _ target: Double) -> Either<String, Double> {
        switch self.modality.apparatus {
        case .fixedWeights(name: let name):
            if let name = name {
                if let fws = model.fixedWeights[name] {
                    return .right(fws.getClosestBelow(target))
                } else {
                    return .left("There is no fixed weight set named \(name)")
                }
            } else {
                return .left("No fixed weights activated")
            }
        default:
            return .right(target)
        }
    }

//    static func ==(lhs: Exercise, rhs: Exercise) -> Bool {  // TODO: names would have to be unique?
//        return lhs.name == rhs.name
//    }

//    func hash(into hasher: inout Hasher) {
//        hasher.combine(self.id)
//    }
}


fileprivate func defaultExpected(_ modality: Modality) -> Expected {
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
