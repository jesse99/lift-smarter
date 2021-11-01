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

        case .maxReps(let info):
            let r = info.restSecs.map({restToStr($0)})
            let t = info.targetReps != nil ? info.targetReps!.description : ""
            let e = info.expectedReps.map({$0.description})
            return ["rest": joinedX(r), "target": t, "expected": joinedX(e)]

        case .repRanges(_):
            ASSERT(false, "use the other editing method")
            return [:]

        case .repTotal(let info):
            let e = info.expectedReps.map({$0.description})
            return ["total": info.total.description, "rest": info.rest.description, "expected": joinedX(e)]
        }
    }
    
    func render(_ editing: RepRangeStage) -> (reps: String, percents: String, rest: String, expected: String) {
        switch self {
        case .repRanges(let info):
            let warmups = info.sets.filter({$0.stage == .warmup})
            let worksets = info.sets.filter({$0.stage == .workset})
            let backoffs = info.sets.filter({$0.stage == .backoff})

            var reps, percents, rest, expected: [String]
            switch editing {
            case .warmup:
                reps = warmups.map({repRangeLabel($0.reps.min, $0.reps.max, suffix: nil)})
                percents = warmups.map({friendlyPercent($0.percent.value)})
                rest = warmups.map({restToStr($0.restSecs)})
                
                if !info.expectedReps.isEmpty {
                    let slice = info.expectedReps.filter({$0.stage == .warmup})
                    expected = slice.map({$0.reps.description})
                } else {
                    expected = []
                }

            case .workset:
                reps = worksets.map({repRangeLabel($0.reps.min, $0.reps.max, suffix: nil)})
                percents = worksets.map({friendlyPercent($0.percent.value)})
                rest = worksets.map({restToStr($0.restSecs)})
                
                if !info.expectedReps.isEmpty {
                    let slice = info.expectedReps.filter({$0.stage == .workset})
                    expected = slice.map({$0.reps.description})
                } else {
                    expected = []
                }

            case .backoff:
                reps = backoffs.map({repRangeLabel($0.reps.min, $0.reps.max, suffix: nil)})
                percents = backoffs.map({friendlyPercent($0.percent.value)})
                rest = backoffs.map({restToStr($0.restSecs)})
                
                if !info.expectedReps.isEmpty {
                    let slice = info.expectedReps.filter({$0.stage == .backoff})
                    expected = slice.map({$0.reps.description})
                } else {
                    expected = []
                }
            }
            return (reps: joinedX(reps), percents: joinedX(percents), rest: joinedX(rest), expected: joinedX(expected))

        default:
            ASSERT(false, "use the other editing method")
            return (reps: "", percents: "", rest: "", expected: "")
        }
    }

    func parse(_ table: [String: String]) -> Either<String, ExerciseInfo> {
        // Note that we don't use comma separated lists because that's more visual noise and
        // because some locales use commas for the decimal points.
        switch self {
        case .durations(_):
            switch coalesce(parseTimes(table["durations"]!, label: "durations"),
                            parseTimes(table["target"]!, label: "target", emptyOK: true),
                            parseTimes(table["rest"]!, label: "rest", zeroOK: true, emptyOK: true)) {
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
                            parseTimes(table["rest"]!, label: "rest", zeroOK: true, emptyOK: true)) {
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
            switch coalesce(parseTimes(table["rest"]!, label: "rest", zeroOK: true),    // this controls how many sets there are so it cannot be empty
                            parseOptionalInt(table["target"]!, label: "target reps"),   // TODO: should the edit view have an explicit num sets text field?
                            parseIntList(table["expected"]!, label: "expected reps", emptyOK: true)) {
            case .right((let r, let t, let e)):
                if !r.isEmpty {
                    let info = MaxRepsInfo(restSecs: r, targetReps: t)
                    info.expectedReps = e
                    return .right(.maxReps(info))
                } else {
                    return .left("Rest cannot be empty")
                }
            case .left(let err):
                return .left(err)
            }

        case .repRanges(_):
            return .left("use the other parse function")

        case .repTotal(_):
            switch coalesce(parseInt(table["total"]!, label: "total"),
                            parseTimes(table["rest"]!, label: "rest", zeroOK: true, multipleOK: false),
                            parseIntList(table["expected"]!, label: "expected reps", emptyOK: true)) {
            case .right((let t, let r, let e)):
                let expected = e.reduce(0, {$0 + $1})
                if expected == t {
                    let info = RepTotalInfo(total: t, rest: r.at(0) ?? 0)
                    info.expectedReps = e
                    return .right(.repTotal(info))
                } else if e.isEmpty {
                    let info = RepTotalInfo(total: t, rest: r.at(0) ?? 0)
                    return .right(.repTotal(info))
                } else {
                    return .left("Expected reps is \(expected) which doesn't match total")
                }
            case .left(let err):
                return .left(err)
            }
        }
    }


    func parse(_ reps: String, _ percents: String, _ rest: String, _ expected: String, _ stage: RepRangeStage, emptyRepsOK: Bool) -> Either<String, ([RepsSet], [ActualRepRange])> {
        switch coalesce(parseRepRanges(reps, label: "reps", emptyOK: emptyRepsOK),
                        parseIntList(percents, label: "percents", zeroOK: true, emptyOK: true),
                        parseTimes(rest, label: "rest", zeroOK: true, emptyOK: true),
                        parseIntList(expected, label: "expected reps", emptyOK: true)) {
        case .right((let repsList, var percentsList, var restList, var expectedList)):
            if percentsList.isEmpty {   // percents can (rarely) be larger than 100, TODO: but maybe we should disallow really large percents
                percentsList = Array(repeating: 100, count: repsList.count)
            }
            if restList.isEmpty {
                restList = Array(repeating: 0, count: repsList.count)
            }
            if expectedList.isEmpty {
                expectedList = repsList.map({$0.min})
            }
            if repsList.count == percentsList.count && repsList.count == restList.count && repsList.count == expectedList.count {
                let percents = percentsList.map({WeightPercent(Double($0)/100.0)})
                let x = zip3(repsList, percents, restList)
                let reps = x.map({RepsSet(reps: $0.0, percent: $0.1, restSecs: $0.2, stage: stage)})
                
                let y = zip(expectedList, percents)
                let expected = y.map({ActualRepRange(reps: $0.0, percent: $0.1.value, stage: stage)})
                return .right((reps, expected))

            } else {
                return .left("Number of reps must match percents, rest, and expected (although the later can be empty)")
            }
        case .left(let err):
            return .left(err)
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
