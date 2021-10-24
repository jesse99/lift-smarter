//  Created by Jesse Vorisek on 10/17/21.
import Foundation

// TODO: Should we make this a real VM?

// Editing
extension ExerciseInfo {
    func render() -> [String: String] {
        switch self {
        case .durations(let info):
            let d = info.sets.map({restToStr($0.secs)})
            let r = info.sets.map({restToStr($0.restSecs)})
            let t = info.targetSecs.map({restToStr($0)})
            return ["durations": joinedX(d), "rest": joinedX(r), "target": joinedX(t)]

        case .fixedReps(let info):
            let rr = info.sets.map({$0.reps.reps.description})
            let r = info.sets.map({restToStr($0.restSecs)})
            return ["reps": joinedX(rr), "rest": joinedX(r)]

        case .maxReps(_):
            ASSERT(false, "not implemented")
            return [:]

        case .repRanges(_):
            ASSERT(false, "not implemented")
            return [:]

        case .repTotal(_):
            ASSERT(false, "not implemented")
            return [:]
        }
    }

    func parse(_ table: [String: String]) -> Either<String, ExerciseInfo> {
        // Note that we don't use comma separated lists because that's more visual noise and
        // because some locales use commas for the decimal points.
        switch self {
        case .durations(_):
            switch coalesce(parseTimes(table["durations"]!, label: "durations"),
                            parseTimes(table["target"]!, label: "target"),
                            parseTimes(table["rest"]!, label: "rest", zeroOK: true)) {
            case .right((let d, let t, let r)):
                let count1 = d.count
                let count2 = r.count
                let count3 = t.count
                let match = count1 == count2 && (count3 == 0 || count1 == count3)

                if !match {
                    return .left("Durations, target, and rest must have the same number of sets (although target can be empty)")
                } else if count1 == 0 {
                    return .left("Durations and rest need at least one set")
                } else {
                    let z = zip(d, r)
                    let s = z.map({DurationSet(secs: $0.0, restSecs: $0.1)})
                    return .right(.durations(DurationsInfo(sets: s, targetSecs: t)))
                }
            case .left(let err):
                return .left(err)
            }

        case .fixedReps(_):
            switch coalesce(parseIntList(table["reps"]!, label: "reps"),
                            parseTimes(table["rest"]!, label: "rest", zeroOK: true)) {
            case .right((let rr, let r)):
                let count1 = rr.count
                let count2 = r.count
                let match = count1 == count2

                if !match {
                    return .left("Reps and rest must have the same number of sets")
                } else if count1 == 0 {
                    return .left("Reps and rest need at least one set")
                } else {
                    let z = zip(rr, r)
                    let s = z.map({FixedRepsSet(reps: FixedReps($0.0), restSecs: $0.1)})
                    return .right(.fixedReps(FixedRepsInfo(reps: s)))
                }
            case .left(let err):
                return .left(err)
            }

        case .maxReps(_):
            return .left("not implemented")

        case .repRanges(_):
            return .left("not implemented")

        case .repTotal(_):
            return .left("not implemented")
        }
    }

    private func restToStr(_ secs: Int) -> String {
        if secs <= 0 {
            return "0s"

        } else if secs <= 60 {
            return "\(secs)s"
        
        } else {
            let s = friendlyFloat(String.init(format: "%.1f", Double(secs)/60.0))
            return s + "m"
        }
    }

    private func joinedX(_ values: [String]) -> String {
        if values.count > 1 && values.all({$0 == values[0]}) {
            return values[0] + " x\(values.count)"
        } else {
            return values.joined(separator: " ")
        }
    }
}