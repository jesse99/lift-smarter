//  Created by Jesse Vorisek on 9/18/21.
import Foundation

enum ActualSet: Equatable {    // note that this represents a single set
    case reps(count: Int, percent: Double)
    case duration(secs: Int, percent: Double)
}

class History: Storable {
    // Note that this is associated with the exercise: to know when an instance has been completed check the workout.
    class Record: Storable {
        var completed: Date     // date exercise was finished
        var weight: Double      // may be 0.0, this is from current.weight
        var sets: [ActualSet]
        var workout: String     // not used atm, but may be used later to show users more detailed views
        var formalName: String  // not used atm, but may be used later to show users more detailed views
        var note: String = ""   // optional arbitrary text set by user

        init(_ workout: Workout, _ exercise: Exercise) {
            self.workout = workout.name
            self.formalName = exercise.formalName
            
            switch exercise.info {
            case .durations(let info):
                self.completed = info.current.startDate    // using startDate instead of Date() makes testing a bit easier...
                self.weight = info.current.weight
                self.sets = info.currentSecs.map({.duration(secs: $0, percent: 1.0)})
            case .fixedReps(let info):
                self.completed = info.current.startDate
                self.weight = info.current.weight
                self.sets = info.currentReps.map({.reps(count: $0, percent: 1.0)})
            case .maxReps(let info):
                self.completed = info.current.startDate
                self.weight = info.current.weight
                self.sets = info.currentReps.map({.reps(count: $0, percent: 1.0)})
            case .repRanges(let info):
                self.completed = info.current.startDate
                self.weight = info.current.weight
                let worksets = info.currentReps.filter({$0.stage == .workset})
                self.sets = worksets.map({.reps(count: $0.reps, percent: $0.percent)})
            case .repTotal(let info):
                self.completed = info.current.startDate
                self.weight = info.current.weight
                self.sets = info.currentReps.map({.reps(count: $0, percent: 1.0)})
            }
        }

        required init(from store: Store) {
            self.completed = store.getDate("completed")
            self.weight = store.getDbl("weight")
            self.sets = store.getObjArray("reps")
            self.workout = store.getStr("workout")
            self.formalName = store.getStr("formalName")
            self.note = store.getStr("note")
        }

        func save(_ store: Store) {
            store.addDate("completed", completed)
            store.addDbl("weight", weight)
            store.addObjArray("reps", sets)
            store.addStr("workout", workout)
            store.addStr("formalName", formalName)
            store.addStr("note", note)
        }

    }

    var records: [String: [Record]] = [:]   // keyed by exercise name, last record is the most recent
    
    init() {
    }

    required init(from store: Store) {
        for name in store.getStrArray("names") {
            self.records[name] = store.getObjArray("\(name)-records")
        }
    }

    func save(_ store: Store) {
        store.addStrArray("names", Array(self.records.keys))
        for (name, records) in self.records {
            store.addObjArray("\(name)-records", records)
        }
    }
}

extension ActualSet: Storable {
    init(from store: Store) {
        let tname = store.getStr("type")
        switch tname {
        case "reps":
            self = .reps(count: store.getInt("count"), percent: store.getDbl("percent"))
        case "duration":
            self = .duration(secs: store.getInt("secs"), percent: store.getDbl("percent"))
        default:
            ASSERT(false, "loading ActualRep had unknown type: \(tname)"); abort()
        }
    }
    
    func save(_ store: Store) {
        switch self {
        case .reps(count: let count, percent: let percent):
            store.addStr("type", "reps")
            store.addInt("count", count)
            store.addDbl("percent", percent)

        case .duration(secs: let secs, percent: let percent):
            store.addStr("type", "duration")
            store.addInt("secs", secs)
            store.addDbl("percent", percent)
        }
    }
}
