//  Created by Jesse Vorisek on 9/18/21.
import Foundation
import SwiftUI

// Model views act as an intermdiary between views and the model. Views cannot directly access
// mutable model classes although they are allowed to access model enums and structs,
class ProgramVM: ObservableObject {
    private let model: Model

    init(_ model: Model) {
        self.model = model
    }
    
    var name: String {
        get {return self.model.program.name}
    }
    
    var workouts: [WorkoutVM] {
        get {return self.model.program.workouts.map({WorkoutVM(self, $0)})}
    }
    
    var exercises: [String] {
        get {return self.model.program.exercises.map({$0.name})}
    }
    
    var instanceClipboard: [ExerciseInstance] {
        get {return self.model.program.instanceClipboard}
    }
    
    func willChange() {
        self.objectWillChange.send()
    }
}

// Misc logic
extension ProgramVM {
    func setName(_ name: String) {
        self.willChange()
        self.model.program.name = name
    }
    
    func addWorkout(_ name: String) {
        self.willChange()
        let workout = Workout(name, [], schedule: .days([.monday, .wednesday, .friday]))
        self.model.program.workouts.append(workout)
    }

    func copyInstances(_ exercises: [InstanceVM]) {
        self.willChange()
        self.model.program.instanceClipboard = exercises.map({$0.instance(self.model)})
    }
    
    /// Returns 1 if date falls within program.weeksStart, 2 if the date is the week after
    /// weeksStart, etc.
    func getWeek(_ currentDate: Date = Date()) -> Int { // tests will use the date argument
        ASSERT_NE(self.model.program.weeksStart.compare(currentDate), .orderedDescending)
        let weeks = weeksBetween(from: self.model.program.weeksStart, to: currentDate)
        let week = (weeks % self.maxWeek()) + 1
        return week
    }

    /// Update program.weeksStart such that getWeek(date) will return week.
    func setWeek(_ week: Int, _ date: Date = Date()) {
        ASSERT_GE(week, 1, "week must be possitive")
        self.willChange()

        if let d = Calendar.current.date(byAdding: .weekOfYear, value: -(week - 1), to: date) {
            self.model.program.weeksStart = d
        } else {
            ASSERT(false, "failed to set date")
        }
    }
    
    func maxWeek() -> Int {
        var result = self.model.program.restWeeks.max() ?? 1
        
        for workout in self.model.program.workouts {
            switch workout.schedule {
            case .weeks(let weeks, _):
                let n = weeks.max() ?? 1
                result = max(n, result)
            default:
                break
            }
        }
        
        return result
    }

    func setRest(_ weeks: [Int]) {
        self.willChange()
        self.model.program.restWeeks = weeks
    }
    
    func setWorkouts(_ workouts: [WorkoutVM]) {
        self.willChange()
        self.model.program.workouts = workouts.map({$0.workout(self.model)})
    }
    
    func moveWorkout(_ vm: WorkoutVM, by: Int) {
        self.willChange()

        let index = self.model.program.workouts.firstIndex(where: {$0.name == vm.name})!
        let workout = self.model.program.workouts.remove(at: index)
        self.model.program.workouts.insert(workout, at: index + by)
    }
    
    func deleteWorkout(_ vm: WorkoutVM) {
        self.willChange()

        let index = self.model.program.workouts.firstIndex(where: {$0.name == vm.name})!
        self.model.program.workouts.remove(at: index)
    }
    
    func toggleEnabled(_ vm: WorkoutVM) {
        self.willChange()
        vm.workout(self.model).enabled = !vm.workout(self.model).enabled
    }
    
    func log(_ level: LogLevel, _ message: String) {
        let vm = LogsVM(model)
        vm.log(level, message)
    }
}

struct Confirmation: Identifiable {
    let title: String
    let message: String
    let button: String
    let callback: () -> Void

    var id: String {get {return self.title + self.message}}
}

extension ProgramVM {
    func editButtons(_ selection: Binding<WorkoutVM?>, _ confirm: Binding<Confirmation?>) -> [ActionSheet.Button] {
        var buttons: [ActionSheet.Button] = []

        if self.workouts.first !== selection.wrappedValue {
            buttons.append(.default(Text("Move Up"), action: {self.moveWorkout(selection.wrappedValue!, by: -1)}))
        }
        if self.workouts.last !== selection.wrappedValue {
            buttons.append(.default(Text("Move Down"), action: {self.moveWorkout(selection.wrappedValue!, by: 1)}))
        }
        if selection.wrappedValue!.enabled {
            buttons.append(.default(Text("Disable Workout"), action: {self.toggleEnabled(selection.wrappedValue!)}))
        } else {
            buttons.append(.default(Text("Enable Workout"), action: {self.toggleEnabled(selection.wrappedValue!)}))
        }
        buttons.append(.destructive(Text("Delete Workout"), action: {
            confirm.wrappedValue = Confirmation(
                title: "Confirm delete",
                message: selection.wrappedValue!.name + " workout",
                button: "Delete",
                callback: {self.deleteWorkout(selection.wrappedValue!)})
            
        }))

        buttons.append(.cancel(Text("Cancel"), action: {}))

        return buttons
    }
}

// Editing
extension ProgramVM {
    func render() -> (String, String) {
        let currentWeek = self.getWeek().description
        let restN = self.model.program.restWeeks.map(({$0.description}))
        let rest = restN.joined(separator: " ")
        return (currentWeek, rest)
    }

    // There are a couple reasons why we parse all of the text fields collectively:
    // 1) If we parse a text field only on changes then validation gets awkward if the
    // user tabs away from a malformed field.
    // 2) We can show the user all the problems with the current configuration.
    func parse(_ name: String, _ currentWeek: String, _ restWeeks: String) -> Either<String, (Int, [Int])> {
        var errors: [String] = []
        
        if name.isBlankOrEmpty() {
            errors.append("Name cannot be empty.")
        }
        
        let week = Int(currentWeek)
        if let w = week {
            if w < 1 {
                errors.append("Current week should be greater than zero.")
            } else if w > self.maxWeek() {
                errors.append("Current week should be less than the max workout week (\(self.maxWeek()).")
            }
        } else {
            errors.append("Current week should be a 1-based number.")
        }
        
        var rest: [Int] = []
        switch parseIntList(restWeeks, label: "Rest weeks", zeroOK: false, emptyOK: true) {
        case .right(let weeks):
            rest = weeks
            for week in weeks {
                if week > self.maxWeek() {
                    errors.append("Rest week should be less than the max workout week (\(self.maxWeek()).")
                    break
                }
            }
        case .left(let err):
            errors.append(err)
        }

        if !errors.isEmpty {
            return .left(errors.joined(separator: " "))
        } else {
            return .right((week!, rest))
        }
    }
}

// View Model internals (views can't call these because they don't have direct access
// to model classes).
extension ProgramVM {
    func exercises(_ workout: Workout) -> [InstanceVM] {
        let vm = WorkoutVM(self, workout)
        return self.model.program.exercises.map({
            return InstanceVM(vm, $0, ExerciseInstance($0.name))
        })
    }

    func instances(_ workout: Workout) -> [InstanceVM] {
        let vm = WorkoutVM(self, workout)
        return workout.instances.map({
            let name = $0.name
            let exercise = self.model.program.exercises.first(where: {$0.name == name})!
            return InstanceVM(vm, exercise, $0)
        })
    }
}

