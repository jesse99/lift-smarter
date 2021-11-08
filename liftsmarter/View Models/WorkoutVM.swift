//  Created by Jesse Vorisek on 9/13/21.
import Foundation
import SwiftUI

class WorkoutVM: Equatable, ObservableObject, Identifiable {
    let program: ProgramVM
    private let workout: Workout
    
    init(_ program: ProgramVM, _ workout: Workout) {
        self.program = program
        self.workout = workout
    }
        
    func willChange() {
        self.objectWillChange.send()
        self.program.willChange()
    }

    var name: String {
        get {return self.workout.name}
    }
    
    var enabled: Bool {
        get {return self.workout.enabled}
    }
    
    var instances: [InstanceVM] {
        get {return self.workout.exercises.map({InstanceVM(self.program, self, $0)})}
    }
    
    var schedule: Schedule {
        get {return self.workout.schedule}
    }
    
    func nextCyclic() -> Date? {
        return self.workout.nextCyclic
    }

    func lastCompleted(_ instance: InstanceVM) -> Date? {
        return self.workout.completed[instance.name]
    }

    static func == (lhs: WorkoutVM, rhs: WorkoutVM) -> Bool {
        return lhs.name == rhs.name
    }
    
    var id: String {
        get {
            return self.workout.name
        }
    }
}

// Mutators
extension WorkoutVM {
    func setName(_ name: String) {
        // Note that we don't update History records because it is supposed to be a historical record.
        if name != self.workout.name {
            self.willChange()
            self.workout.name = name
        }
    }
    
    func setInstances(_ instances: [InstanceVM]) {
        self.willChange()
        self.workout.exercises = instances.map({$0.exercise(self.workout).clone()})
    }
    
    func setSchedule(_ schedule: Schedule) {
        self.willChange()
        self.workout.schedule = schedule
    }

    func setNextCyclic(_ date: Date) {
        switch self.workout.schedule {
        case .cyclic(_):
            self.willChange()
            self.workout.nextCyclic = date
        default:
            ASSERT(false, "expected cyclic")
        }
    }

    func move(_ instance: InstanceVM, by: Int) {
        self.willChange()

        let index = self.instances.firstIndex(where: {$0.name == instance.name})!
        let instance = self.workout.exercises.remove(at: index)
        self.workout.exercises.insert(instance, at: index + by)
    }

    func delete(_ instance: InstanceVM) {
        self.willChange()

        let index = self.instances.firstIndex(where: {$0.name == instance.name})!
        self.workout.exercises.remove(at: index)
    }

    func deleteAll() {
        self.willChange()
        self.workout.exercises.removeAll()
    }

    func copy(_ instance: InstanceVM) {
        self.program.copyExercises([instance.exercise])
    }

    func copyAll() {
        let exercises = self.instances.map({$0.exercise})
        self.program.copyExercises(exercises)
    }

    func cut(_ instance: InstanceVM) {
        self.program.copyExercises([instance.exercise])
        self.delete(instance)
    }
    
    func canPaste() -> Bool {
        for candidate in self.program.instanceClipboard {
            if self.instances.firstIndex(where: {$0.name == candidate.name}) == nil {
                return true
            }
        }
        return false
    }

    func paste() {
        for candidate in self.program.instanceClipboard {
            self.append(candidate.exercise(self.workout))
        }
    }

    func recentlyCompleted(_ instance: InstanceVM) -> Bool {
        if let completed = self.lastCompleted(instance) {
            return Date().hoursSinceDate(completed) < RecentHours
        } else {
            return false
        }
    }

    func log(_ level: LogLevel, _ message: String) {
        self.program.log(level, message)
    }
}

// UI
extension WorkoutVM {
    func editButtons(_ selection: Binding<InstanceVM?>, _ confirm: Binding<Confirmation?>) -> [ActionSheet.Button] {
        var buttons: [ActionSheet.Button] = []

        buttons.append(.default(Text("Copy"), action: {self.copy(selection.wrappedValue!)}))
        buttons.append(.default(Text("Copy All"), action: {self.copyAll()}))
        buttons.append(.default(Text("Cut"), action: {self.cut(selection.wrappedValue!)}))
        if selection.wrappedValue!.enabled {
            buttons.append(.default(Text("Disable Exercise"), action: {selection.wrappedValue!.toggleEnabled()}))
        } else {
            buttons.append(.default(Text("Enable Exercise"), action: {selection.wrappedValue!.toggleEnabled()}))
        }
        buttons.append(.destructive(Text("Delete Exercise"), action: {
            confirm.wrappedValue = Confirmation(
                title: "Confirm delete",
                message: selection.wrappedValue!.name + " exercise",
                button: "Delete",
                callback: {self.delete(selection.wrappedValue!)})
            
        }))
        buttons.append(.destructive(Text("Delete All Exercises"), action: {
            confirm.wrappedValue = Confirmation(
                title: "Confirm delete all",
                message: "exercises",
                button: "Delete All",
                callback: {self.deleteAll()})
            
        }))
        if self.instances.first != selection.wrappedValue {
            buttons.append(.default(Text("Move Up"), action: {self.move(selection.wrappedValue!, by: -1)}))
        }
        if self.instances.last != selection.wrappedValue {
            buttons.append(.default(Text("Move Down"), action: {self.move(selection.wrappedValue!, by: 1)}))
        }

        buttons.append(.cancel(Text("Cancel"), action: {}))

        return buttons
    }

    func scheduleButton(_ schedule: Binding<Schedule>, _ text: Binding<String>, _ label: Binding<String>,
                        _ subSchedule: Binding<Schedule?>, _ subText: Binding<String>, _ subLabel: Binding<String>, _ nextCyclic: Binding<Date>, _ hasDatePicker: Binding<Bool>) -> AnyView {
        var menuText = ""
        switch schedule.wrappedValue {
        case .anyDay: menuText = "Any Day"
        case .cyclic(_): menuText = "Every"
        case .days(_): menuText = "Days"
        case .weeks(_, _): menuText = "Weeks"
        }
        
        let button = Menu(menuText) {
            Button("Any Day", action: {
                schedule.wrappedValue = .anyDay
                text.wrappedValue = ""
                label.wrappedValue = ""
                
                subSchedule.wrappedValue = nil
                subText.wrappedValue = ""
                subLabel.wrappedValue = ""
                
                nextCyclic.wrappedValue = Date.distantFuture
                hasDatePicker.wrappedValue = false
            })
            Button("Every N Days", action: {
                schedule.wrappedValue = .cyclic(2)
                text.wrappedValue = "2"
                label.wrappedValue = " days"
                
                subSchedule.wrappedValue = nil
                subText.wrappedValue = ""
                subLabel.wrappedValue = ""
                
                let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
                nextCyclic.wrappedValue = self.workout.nextCyclic ?? yesterday
                hasDatePicker.wrappedValue = true
            })
            Button("Week Days", action: {
                schedule.wrappedValue = .days([.monday, .wednesday, .friday])
                text.wrappedValue = "Mon Wed Fri"
                label.wrappedValue = ""
                
                subSchedule.wrappedValue = nil
                subText.wrappedValue = ""
                subLabel.wrappedValue = ""
                
                nextCyclic.wrappedValue = Date.distantFuture
                hasDatePicker.wrappedValue = false
            })
            Button("Weeks", action: {
                subSchedule.wrappedValue = .days([.monday, .wednesday, .friday])
                subText.wrappedValue = "Mon Wed Fri"
                subLabel.wrappedValue = ""

                schedule.wrappedValue = .weeks([1, 3], subSchedule.wrappedValue!)
                text.wrappedValue = "1 3"
                label.wrappedValue = ""
                                
                nextCyclic.wrappedValue = Date.distantFuture
                hasDatePicker.wrappedValue = false
            })
            Button("Cancel", action: {})
        }.font(.callout)
        return AnyView(button)
    }

    func subScheduleButton(_ schedule: Binding<Schedule?>, _ text: Binding<String>, _ label: Binding<String>) -> AnyView {
        var menuText = ""
        switch schedule.wrappedValue! {
        case .anyDay: menuText = "Any Day"
        case .cyclic(_): ASSERT(false, "sub-schedule cannot be cyclic")
        case .days(_): menuText = "Days"
        case .weeks(_, _): ASSERT(false, "sub-schedule cannot be weeks")
        }

        let button = Menu(menuText) {
            Button("Any Day", action: {schedule.wrappedValue = .anyDay; text.wrappedValue = ""; label.wrappedValue = ""})
            Button("Week Days", action: {schedule.wrappedValue = .days([.monday, .wednesday, .friday]); text.wrappedValue = "Mon Wed Fri"; label.wrappedValue = ""})
            Button("Cancel", action: {})
        }.font(.callout)
        return AnyView(button)
    }

    func hasScheduleText(_ schedule: Schedule) -> Bool {
        switch schedule {
        case .anyDay: return false
        case .cyclic(_): return true
        case .days(_): return true
        case .weeks(_, _): return true
        }
    }

    func addButton() -> AnyView {
        let button = Menu("Add") {
            Button("Cancel", action: {})
            ForEach(self.program.exercises.reversed()) {exercise in
                if self.instances.firstIndex(where: {$0.name == exercise.name}) == nil {
                    let exercise = exercise.exercise(self.workout)
                    Button(exercise.name, action: {self.append(exercise)})
                }
            }
        }.font(.callout)
        return AnyView(button)
    }

    func label(_ instance: InstanceVM) -> String {
        return instance.name
    }

    func subLabel(_ instance: InstanceVM) -> String {
        let (sets, trailer, limit) = instance.workoutLabel()
        
        if sets.count == 0 {
            return ""
        } else if sets.count == 1 {
            return sets[0] + trailer
        } else {
            let sets = dedupe(sets)
            let prefix = sets.prefix(limit)
            let result = prefix.joined(separator: ", ")
            if prefix.count < sets.count {
                return result + ", ..."
            } else {
                return result + trailer
            }
        }
    }

    func color(_ instance: InstanceVM) -> Color {
        if self.recentlyCompleted(instance) || self.isResting(instance) {
            return .gray
        } else if instance.started {
            return .blue
        } else {
            return .black
        }
    }
    
    private func isResting(_ instance: InstanceVM) -> Bool {
        let currentWeek = self.program.getWeek()
        if self.program.restWeeks.contains(currentWeek) {
            if let exercise = self.program.exercises.first(where: {$0.name == instance.name}) {
                return exercise.allowRest
            }
        }
        return false
    }
}

// Editing
extension WorkoutVM {
    func render() -> (schedule: Schedule, text: String, label: String, subSchedule: Schedule?, subText: String, subLabel: String, nextCyclic: Date?) {
        switch self.workout.schedule {
        case .anyDay:
            return (schedule: self.workout.schedule,
                    text: "",
                    label: "",
                    subSchedule: nil,
                    subText: "",
                    subLabel: "",
                    nextCyclic: nil)
            
        case .cyclic(let n):
            var next = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
            if let date = self.workout.nextCyclic {
                next = date
            }
            return (schedule: self.workout.schedule,
                    text: n.description,
                    label: "days",
                    subSchedule: nil,
                    subText: "",
                    subLabel: "",
                    nextCyclic: next)
            
        case .days(let days):
            return (schedule: self.workout.schedule,
                    text: self.renderWeekDays(days),
                    label: "",
                    subSchedule: nil,
                    subText: "",
                    subLabel: "",
                    nextCyclic: nil)
            
        case .weeks(let weeks, let subSchedule):
            let w = weeks.map({$0.description})
            switch subSchedule {
            case .anyDay:
                return (schedule: self.workout.schedule,
                        text: w.joined(separator: " "),
                        label: "",
                        subSchedule: subSchedule,
                        subText: "",
                        subLabel: "",
                        nextCyclic: nil)
                
            case .cyclic(let n):
                var next = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
                if let date = self.workout.nextCyclic {
                    next = date
                }
                return (schedule: self.workout.schedule,
                        text: w.joined(separator: " "),
                        label: "",
                        subSchedule: subSchedule,
                        subText: n.description,
                        subLabel: "days",
                        nextCyclic: next)
                
            case .days(let days):
                return (schedule: self.workout.schedule,
                        text: w.joined(separator: " "),
                        label: "",
                        subSchedule: subSchedule,
                        subText: self.renderWeekDays(days),
                        subLabel: "",
                        nextCyclic: nil)
                
            case .weeks(_, let subSchedule):
                ASSERT(false, "sub-schedule can't be weeks")
                return (schedule: self.workout.schedule,
                        text: "",
                        label: "",
                        subSchedule,
                        subText: "",
                        subLabel: "",
                        nextCyclic: nil)
            }
        }
    }

    func parse(_ name: String, _ schedule: Schedule, _ scheduleText: String, _ subSchedule: Schedule?, _ subScheduleText: String) -> Either<String, Schedule> {
        var errors: [String] = []
        
        if name.isBlankOrEmpty() {
            errors.append("Name cannot be empty.")
        } else {
            for w in self.program.workouts {
                if w.workout !== self.workout {
                    if w.name == name {
                        errors.append("Workout names must be unique.")
                        break
                    }
                }
            }
        }
        
        var result = Schedule.anyDay
        switch schedule {
        case .anyDay:
            ASSERT(subSchedule == nil, "anyDay shouldn't have a sub-schedule")
            result = .anyDay
        case .cyclic(_):
            ASSERT(subSchedule == nil, "cyclic shouldn't have a sub-schedule")
            if let n = Int(scheduleText) {
                result = .cyclic(n)
            } else {
                errors.append("Days must be a number.")
            }
        case .days(_):
            ASSERT(subSchedule == nil, "days shouldn't have a sub-schedule")
            if let days = parseWeekDays(scheduleText) {
                if days.isEmpty {
                    errors.append("Days must be space separated (abreviated) day names.")
                } else {
                    result = .days(days)
                }
            } else {
                errors.append("Days must be space separated (abreviated) day names.")
            }
        case .weeks(_, _):
            ASSERT(subSchedule != nil, "weeks should have a sub-schedule")
            switch parseIntList(scheduleText, label: "Weeks", zeroOK: false, emptyOK: false) {
            case .right(let weeks):
                switch subSchedule! {
                case .anyDay:
                    result = .weeks(weeks, .anyDay)
                case .cyclic(_):
                    if let n = Int(subScheduleText) {
                        result = .weeks(weeks, .cyclic(n))
                    } else {
                        errors.append("Days must be a number.")
                    }
                case .days(_):
                    if let days = parseWeekDays(subScheduleText) {
                        result = .weeks(weeks, .days(days))
                    } else {
                        errors.append("Days must be space separated (abreviated) day names.")
                    }
                case .weeks(_, _):
                    ASSERT(false, "weeks should not have a weeks sub-schedule")
                }
            case .left(let err):
                errors.append(err)
            }
        }
        
        if !errors.isEmpty {
            return .left(errors.joined(separator: " "))
        } else {
            return .right(result)
        }
    }
                
    private func parseWeekDays(_ text: String) -> [WeekDay]? {
        var result: [WeekDay] = []
        
        let parts = text.split(separator: " ")
        for part in parts {
            if let day = parseWeekDay(part.lowercased()) {
                result.append(day)
            } else {
                return nil
            }
        }
        
        return result
    }
    
    private func parseWeekDay(_ text: String) -> WeekDay? {
        let days = ["sunday", "monday", "tuesday", "wednesday", "thursday", "friday", "saturday"]

        var result: WeekDay? = nil
        for (i, day) in days.enumerated() {
            if day.hasPrefix(text) {
                if result == nil {
                    result = WeekDay(rawValue: i)
                } else {
                    return nil
                }
            }
        }
        
        return result
    }
    
    private func renderWeekDays(_ days: [WeekDay]) -> String {
        var result: [String] = []
        
        if days.contains(.sunday) {
            result.append("Sun")
        }
        if days.contains(.monday) {
            result.append("Mon")
        }
        if days.contains(.tuesday) {
            result.append("Tues")
        }
        if days.contains(.wednesday) {
            result.append("Wed")
        }
        if days.contains(.thursday) {
            result.append("Thur")
        }
        if days.contains(.friday) {
            result.append("Fri")
        }
        if days.contains(.saturday) {
            result.append("Sat")
        }

        return result.joined(separator: " ")
    }
}

// View Model internals (views can't call these because they don't have direct access
// to model classes).
extension WorkoutVM {
    func workout(_ model: Model) -> Workout {
        return self.workout
    }

    func workout(_ instance: Exercise) -> Workout {
        return self.workout
    }

    func model(_ instance: Exercise) -> Model {
        return self.program.model(self.workout)
    }

    func append(_ exercise: Exercise) {
        if self.instances.firstIndex(where: {$0.name == exercise.name}) == nil {
            self.willChange()
            self.workout.exercises.append(exercise.clone())
        }
    }
}

/// Replaces consecutive duplicate strings, e.g. ["alpha", "alpha", "beta"]
/// becomes ["2xalpha", "beta"].
func dedupe(_ sets: [String]) -> [String] {
    func numDupes(_ i: Int) -> Int {
        var count = 1
        while i+count < sets.count && sets[i] == sets[i+count] {
            count += 1
        }
        return count
    }
                
    var i = 0
    var result: [String] = []
    while i < sets.count {
        let count = numDupes(i)
        if count > 1 {
            result.append("\(count)x\(sets[i])")
            i += count
            
        } else {
            result.append(sets[i])
            i += 1
        }
    }
    
    return result
}

// TODO: move this into Weights.swift?
func weightSuffix(_ percent: WeightPercent, _ maxWeight: Double) -> String {
    let weight = maxWeight * percent
    return percent.value >= 0.01 && weight > epsilonWeight ? " @ " + friendlyUnitsWeight(weight) : ""
}

func friendlyFloat(_ str: String) -> String {
    var result = str
    while result.hasSuffix("0") {
        let start = result.index(result.endIndex, offsetBy: -1)
        let end = result.endIndex
        result.removeSubrange(start..<end)
    }
    if result.hasSuffix(".") {
        let start = result.index(result.endIndex, offsetBy: -1)
        let end = result.endIndex
        result.removeSubrange(start..<end)
    }
    
    return result
}

func friendlyPercent(_ percent: Double) -> String {
    let p = Int(percent*100.0)
    return p.description
}

func friendlyWeight(_ weight: Double) -> String {
    var result: String
    
    // Note that weights are always stored as lbs internally.
    //        let app = UIApplication.shared.delegate as! AppDelegate
    //        switch app.units()
    //        {
    //        case .imperial:
    //            // Kind of annoying to use three decimal places but people
    //            // sometimes use 0.625 fractional plates (5/8 lb).
    result = String(format: "%.3f", weight)
    //
    //        case .metric:
    //            result = String(format: "%.2f", arguments: [weight*Double.lbToKg])
    //        }
    
    return friendlyFloat(result)
}

func friendlyUnitsWeight(_ weight: Double, plural: Bool = true) -> String {
    if plural && weight != 1.0 {
        return friendlyWeight(weight) + " lbs"  // TODO: also kg
    } else {
        return friendlyWeight(weight) + " lb"
    }
}
