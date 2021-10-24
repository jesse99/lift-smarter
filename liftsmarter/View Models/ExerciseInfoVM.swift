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

        case .repTotal(let info):
            let e = info.expectedReps.map({$0.description})
            return ["total": info.total.description, "rest": info.rest.description, "expected": joinedX(e)]
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
            case .right((let d, let t, var r)):
                let count1 = d.count
                let count2 = t.count
                let count3 = r.count
                let match = (count2 == 0 || count1 == count2) && (count3 == 0 || count1 == count3)

                if !match {
                    return .left("Durations, target, and rest must have the same number of sets (although target and rest can be empty)")
                } else if count1 == 0 {
                    return .left("Durations needs at least one set")
                } else {
                    if r.isEmpty {
                        r = Array(repeating: 0, count: count1)
                    }
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
            case .right((let rr, var r)):
                let count1 = rr.count
                let count2 = r.count
                let match = count2 == 0 || count1 == count2

                if !match {
                    return .left("Reps and rest must have the same number of sets (although rest can be empty)")
                } else if count1 == 0 {
                    return .left("Reps needs at least one set")
                } else {
                    if r.isEmpty {
                        r = Array(repeating: 0, count: count1)
                    }
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
            switch coalesce(parseInt(table["total"]!, label: "total"),
                            parseInt(table["rest"]!, label: "rest", zeroOK: true),
                            parseIntList(table["expected"]!, label: "expected reps", emptyOK: true)) {
            case .right((let t, let r, let e)):
                let info = RepTotalInfo(total: t, rest: r)
                info.expectedReps = e
                return .right(.repTotal(info))
            case .left(let err):
                return .left(err)
            }
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
