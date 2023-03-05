//  Created by Jesse Vorisek on 9/18/21.
import Foundation

class HistoryVM: ObservableObject {
    private let model: Model
    
    init(_ model: Model) {
        self.model = model
    }
    
    func records(_ exerciseName: String) -> [History.Record] {
        return model.history.records[exerciseName] ?? []
    }
}

// Misc Logic
extension HistoryVM {
    @discardableResult func append(_ workout: WorkoutVM, _ exercise: InstanceVM, _ startDate: Date) -> History.Record {
        self.objectWillChange.send()
        workout.willChange()
        
        let workout = workout.workout(self.model)
        let exercise = exercise.exercise(self.model)
        
        let record = History.Record(workout, exercise)
        self.model.history.records[exercise.name, default: []].append(record)
        workout.completed[exercise.name] = startDate
        return record
    }
    
    func delete(_ workout: WorkoutVM, _ exercise: InstanceVM, _ record: History.Record) {
        self.objectWillChange.send()
        workout.willChange()

        if var records = self.model.history.records[exercise.name] {
            if let index = records.firstIndex(where: {$0 === record}) {
                records.remove(at: index)
                self.model.history.records[exercise.name] = records
                
                if index >= records.count {
                    let workout = workout.workout(self.model)
                    if let last = records.last {
                        workout.completed[exercise.name] = last.completed
                    } else {
                        workout.completed[exercise.name] = nil
                    }
                }
            } else {
                ASSERT(false, "couldn't find record for \(exercise.name)")
            }
        }
    }
    
    func deleteAll(_ workout: WorkoutVM, _ exercise: InstanceVM) {
        self.objectWillChange.send()
        workout.willChange()

        if var records = self.model.history.records[exercise.name] {
            records.removeAll()
            self.model.history.records[exercise.name] = records

            let workout = workout.workout(self.model)
            workout.completed[exercise.name] = nil
        }
    }
}

// UI Labels
extension HistoryVM {
    func label(_ record: History.Record) -> String {
        var reps: [String] = []
        var percents: [Double] = []
        
        for rep in record.sets {
            switch rep {
            case .duration(secs: let duration, percent: let percent):
                reps.append("\(duration)s")
                percents.append(percent)
            default:
                reps.append("not implemented")
            }
        }

        if percents.all({$0 == 1.0}) {
            return dedupe(reps).joined(separator: ", ") + self.labelSuffix(record.weight, 1.0)
        }

        if percents.all({$0 == percents[0]}) {
            return dedupe(reps).joined(separator: ", ") + self.labelSuffix(record.weight, percents[0])
        }
        
        var actual: [String] = []
        for i in 0..<reps.count {
            actual.append(reps[i] + self.labelSuffix(record.weight, percents[i]))
        }
        
        return dedupe(actual).joined(separator: ", ")
    }
    
    private func labelSuffix(_ weight: Double, _ percent: Double) -> String {
        let w = weight*percent
        if w >= 0.01 {
            return " @ " + friendlyUnitsWeight(w)
        } else {
            return ""
        }
    }
}
