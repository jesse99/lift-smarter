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
    
    var exercises: [ExerciseVM] {
        get {
            let program = ProgramVM(self.model)
            return self.model.program.exercises.map({ExerciseVM(program, $0)})
        }
    }
    
    var userNoteKeys: [String] {
        get {return Array(self.model.userNotes.keys)}
    }
    
    var restWeeks: [Int] {
        get {return self.model.program.restWeeks}
    }
    
    var instanceClipboard: [ExerciseInstance] {
        get {return self.model.program.instanceClipboard}
    }
    
    func history() -> HistoryVM {
        return HistoryVM(self.model)
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
    
    func setExercises(_ exercises: [ExerciseVM]) {
        self.willChange()
        self.model.program.exercises = exercises.map({$0.exercise(self.model)})
    }
    
    func addWorkout(_ name: String) {
        self.willChange()
        let workout = Workout(name, [], schedule: .days([.monday, .wednesday, .friday]))
        self.model.program.workouts.append(workout)
    }
    
    func addExercise(_ name: String) {
        let work = FixedRepsSet(reps: FixedReps(10), restSecs: 60)
        let sets = Sets.fixedReps([work, work, work])
        let modality = Modality(Apparatus.bodyWeight, sets)
        let exercise = Exercise(name, "", modality, Expected(weight: 0.0, sets: .fixedReps))

        self.willChange()
        self.model.program.exercises.append(exercise)
        self.model.program.exercises.sort(by: {$0.name < $1.name})
    }

    // Should only be called if no workouts reference the exercise.
    func deleteExercise(_ exercise: ExerciseVM) {
        self.willChange()
        let index = self.model.program.exercises.firstIndex(where: {$0.name == exercise.name})!
        self.model.program.exercises.remove(at: index)
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

// UI
extension ProgramVM {
    func label(_ workout: WorkoutVM) -> String {
        return workout.name
    }
    
    func subLabel(_ workoutVM: WorkoutVM, now: Date = Date()) -> (String, Color) {
        if workoutVM.instances.isEmpty {
            return ("no exercises", .black)
        }
        
        let instances = workoutVM.instances.filter({$0.enabled})
        if instances.count == 0 {
            return ("nothing enabled", .black)
        }
        
        for candidate in instances {
            let instance = candidate.instance(self.model)
            if now.hoursSinceDate(instance.current.startDate) <= RecentHours && candidate.inProgress() {
                // If any exercise has been started recently but not completed.
                return ("in progress", .red)
            }
        }
        
        var numCompleted = 0
        for candidate in instances {
            if let completed = workoutVM.lastCompleted(candidate) {
                if now.hoursSinceDate(completed) <= RecentHours {
                    numCompleted += 1
                }
            }
        }
        if numCompleted > 0 && numCompleted < instances.count {
            // Some but not all exercises were completed recently.
            return ("partially completed", .red)
        }
        else if numCompleted == instances.count {
            // If every exercise has been completed recently.
            return ("completed", .black)
        }
        
        let workout = workoutVM.workout(self.model)
        var delta: ScheduleDelta = .error
        switch workout.schedule {
        case .weeks(let defaultWeeks, let subSchedule):
            let weeks = pruneRestWeeks(workout, defaultWeeks)
            if scheduledForThisWeek(weeks, subSchedule, now) {
                delta = findDelta(workoutVM, instances, subSchedule, now)

            } else {
                if let scheduledStart = startOfNextScheduledWeek(weeks, now) {
                    let extraDays = daysBetween(from: now, to: scheduledStart)
                    delta = findAdjustedDelta(workoutVM, instances, subSchedule, extraDays, now)
                } else {
                    delta = .notScheduled
                }
            }
        default:
            let currentWeek = self.getWeek(now)
            if self.restWeeks.contains(currentWeek) {
                if let start = startOfNonRestWeek(now) {
                    let extraDays = daysBetween(from: now, to: start)
                    delta = findAdjustedDelta(workoutVM, instances, workout.schedule, extraDays, now)
                } else {
                    delta = .notScheduled
                }
            } else {
                delta = findDelta(workoutVM, instances, workout.schedule, now)
            }
        }
        
        switch delta {
        case .anyDay:
            return ("any day", .orange)
            
        case .days(let n):
            switch n {
            case 0: return ("today", .orange)
            case 1: return ("tomorrow", .blue)
            default: return ("in \(n) days", .black)
            }

        case .error:
            return ("", .black)
                
        case .notScheduled:
            return ("not scheduled", .black)
                
        case .notStarted:
            return ("never started", .orange)

        case .overdue(let n):
            if n == 1 {
                return ("overdue by 1 day", .orange)
            } else if n > 60 {
                return ("overdue by more than \(n/30) months", .orange) // relatively crude estimate is fine here
            } else if n > 30 {
                return ("overdue by more than 1 month", .orange)
            } else {
                return ("overdue by \(n) days", .orange)
            }
        }
    }
    
    private func findAdjustedDelta(_ workout: WorkoutVM, _ instances: [InstanceVM], _ schedule: Schedule, _ extraDays: Int, _ now: Date) -> ScheduleDelta {
        let adjustedNow = Calendar.current.date(byAdding: .day, value: extraDays, to: now)!
        let delta = findDelta(workout, instances, schedule, adjustedNow)
        switch delta {
        case .anyDay:
            return .days(extraDays)
        case .days(let n):
            return .days(n + extraDays)
        case .error, .notScheduled, .notStarted:
            return delta
        case .overdue(_):
            ASSERT(false, "week schedule dosn't support cyclic sub-schedule")
            return .error
        }
    }
    
    func editWorkoutButtons(_ selection: Binding<WorkoutVM?>, _ confirm: Binding<Confirmation?>) -> [ActionSheet.Button] {
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

    func editExerciseButtons(_ selection: Binding<ExerciseVM?>) -> [ActionSheet.Button] {
        var buttons: [ActionSheet.Button] = []

        if selection.wrappedValue!.canDelete() {
            buttons.append(.destructive(Text("Delete Exercise"), action: {  // maybe we should have confirmation here
                    self.deleteExercise(selection.wrappedValue!)
            }))
        }
        
        buttons.append(.cancel(Text("Cancel"), action: {}))

        return buttons
    }
    
    enum ScheduleDelta {
        case anyDay
        case days(Int)
        case error
        case notScheduled
        case notStarted
        case overdue(Int)
    }
    
    private func findDelta(_ workout: WorkoutVM, _ instances: [InstanceVM], _ schedule: Schedule, _ now: Date) -> ScheduleDelta {
        switch schedule {
        case .anyDay:
            return .anyDay
                
        case .cyclic(let delta):
            let calendar = Calendar.current
            if let completed = self.newestCompleted(workout, instances) {
                let dueDate = calendar.date(byAdding: .day, value: delta, to: completed)!
                if now.compare(dueDate) != .orderedDescending {
                    for n in 0..<delta {
                        let candidate = calendar.date(byAdding: .day, value: -n, to: dueDate)!
                        if candidate.daysMatch(now) {
                            return .days(n)
                        }
                    }
                    ASSERT(false, "should never happen")
                    return .error
                } else {
                    let n = daysBetween(from: dueDate, to: now)
                    return .overdue(n)
                }
                
            } else {
                if delta == 1 {
                    return .days(0)
                } else {
                    return .notStarted
                }
            }

        case .days(let days):
            var daysToScheduled = 8
            for day in days {
                daysToScheduled = min(self.daysTo(now, day), daysToScheduled)
            }
            switch daysToScheduled {
            case 8: return .notScheduled
            default: return .days(daysToScheduled)
            }

        case .weeks(_, _):
            ASSERT(false, "don't call this with a week schedule")
            return .error
        }
    }
    
    private func scheduledForThisWeek(_ weeks: [Int], _ schedule: Schedule, _ now: Date) -> Bool {
        let currentWeek = self.getWeek(now)
        switch schedule {
        case .anyDay:
            return weeks.contains(currentWeek)
        case .days(let days):
            if weeks.contains(currentWeek) {
                let currentDay = Calendar.current.component(.weekday, from: now) - 1
                for candidate in days {
                    if currentDay <= candidate.rawValue {
                        return true
                    }
                }
            }
        default:
            ASSERT(false, "not supported as a sub-schedule")
        }
        return false
    }
    
    // Used for weeks schedule.
    private func startOfNextScheduledWeek(_ weeks: [Int], _ now: Date) -> Date? {
        let currentWeek = self.getWeek(now)
        
        // Find the smallest scheduled week larger than currentWeek.
        var nextWeek: Int? = nil
        for candidate in weeks {
            if candidate > currentWeek && (nextWeek == nil || candidate < nextWeek!) {
                nextWeek = candidate
            }
        }
        
        // If not then the weeks have wrapped around.
        if nextWeek == nil {
            if let firstWeek = weeks.min() {
                nextWeek = firstWeek + self.maxWeek()
            }
        }
        
        if let next = nextWeek {
            let scheduledWeek = Calendar.current.date(byAdding: .weekOfMonth, value: next - currentWeek, to: now)!
            return scheduledWeek.startOfWeek()
        } else {
            return nil
        }
    }
    
    // Used for non-weeks schedule.
    private func startOfNonRestWeek(_ now: Date) -> Date? {
        let currentWeek = self.getWeek(now)
        
        for delta in 1..<self.maxWeek() {
            let week = (currentWeek + delta - 1) % self.maxWeek() + 1
            if !self.restWeeks.contains(week) {
                let date = Calendar.current.date(byAdding: .weekOfMonth, value: delta, to: now)!
                return date.startOfWeek()
            }
        }
        
        return nil
    }
    
    private func pruneRestWeeks(_ workout: Workout, _ weeks: [Int]) -> [Int] {
        var result: [Int] = []
        
        let filterIn = {(exercise: Exercise) -> Bool in workout.instances.contains(where: {$0.name == exercise.name})}
        let exercises = self.model.program.exercises.filter(filterIn)
        let allWillRest = exercises.all({$0.allowRest})
        if allWillRest {
            for candidate in weeks {
                if !self.model.program.restWeeks.contains(candidate) {
                    result.append(candidate)
                }
            }

        } else {
            // If any exercise ignores rest weeks then, in the program view, we don't want to special case
            // the week (but we will special case it in the workout view).
            result = weeks
        }
        
        return result
    }
    
    private func daysTo(_ now: Date, _ scheduledDay: WeekDay) -> Int {
        let nowDay = Calendar.current.component(.weekday, from: now) - 1
        if scheduledDay.rawValue >= nowDay {
            return scheduledDay.rawValue - nowDay
        } else {
            return 7 + scheduledDay.rawValue - nowDay
        }
    }
    
    private func newestCompleted(_ workout: WorkoutVM, _ instances: [InstanceVM]) -> Date? {
        var result: Date? = nil
        
        for candidate in instances {
            if let completed = workout.lastCompleted(candidate) {
                if let r = result {
                    if r.compare(completed) == .orderedAscending {
                        result = completed
                    }
                } else {
                    result = completed
                }
            }
        }
        
        return result
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
                errors.append("Current week should be less than the max workout week (\(self.maxWeek())).")
            }
        } else {
            errors.append("Current week should be a 1-based number.")
        }
        
        var rest: [Int] = []
        switch parseIntList(restWeeks, label: "Rest weeks", zeroOK: false, emptyOK: true) {
        case .right(let weeks):
            rest = weeks
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
    func model(_ workout: Workout) -> Model {
        return self.model
    }

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

