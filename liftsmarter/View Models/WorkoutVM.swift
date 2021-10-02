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
    
    var exercises: [InstanceVM] {
        get {return self.program.instances(self.workout)}
    }
    
    func lastCompleted(_ exercise: InstanceVM) -> Date? {
        return self.workout.completed[exercise.name]
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

// Misc logic
extension WorkoutVM {
    func setName(_ name: String) {
        // Note that we don't update History records because it is supposed to be a historical record.
        if name != self.workout.name {
            self.willChange()
            self.workout.name = name
        }
    }
    
    func setInstances(_ exercises: [InstanceVM]) {
        self.willChange()
        self.workout.instances = exercises.map({$0.instance(self.workout)})
    }
    
    func setSchedule(_ schedule: Schedule) {
        self.willChange()
        self.workout.schedule = schedule
    }

    func move(_ exercise: InstanceVM, by: Int) {
        self.willChange()

        let index = self.exercises.firstIndex(where: {$0.name == exercise.name})!
        let instance = self.workout.instances.remove(at: index)
        self.workout.instances.insert(instance, at: index + by)
    }

    func delete(_ exercise: InstanceVM) {
        self.willChange()

        let index = self.exercises.firstIndex(where: {$0.name == exercise.name})!
        self.workout.instances.remove(at: index)
    }

    func deleteAll() {
        self.willChange()
        self.workout.instances.removeAll()
    }

    func copy(_ exercise: InstanceVM) {
        self.program.copyInstances([exercise])
    }

    func copyAll() {
        self.program.copyInstances(self.exercises)
    }

    func cut(_ exercise: InstanceVM) {
        self.program.copyInstances([exercise])
        self.delete(exercise)
    }
    
    func canPaste() -> Bool {
        for candidate in self.program.instanceClipboard {
            if self.exercises.firstIndex(where: {$0.name == candidate.name}) == nil {
                return true
            }
        }
        return false
    }

    func append(_ instance: ExerciseInstance) {
        if self.exercises.firstIndex(where: {$0.name == instance.name}) == nil {
            self.willChange()
            self.workout.instances.append(instance)
        }
    }

    func paste() {
        for candidate in self.program.instanceClipboard {
            self.append(candidate)
        }
    }

    func log(_ level: LogLevel, _ message: String) {
        self.program.log(level, message)
    }

    func recentlyCompleted(_ exercise: InstanceVM) -> Bool {
        if let completed = self.lastCompleted(exercise) {
            return Date().hoursSinceDate(completed) < RecentHours
        } else {
            return false
        }
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
        if self.exercises.first != selection.wrappedValue {
            buttons.append(.default(Text("Move Up"), action: {self.move(selection.wrappedValue!, by: -1)}))
        }
        if self.exercises.last != selection.wrappedValue {
            buttons.append(.default(Text("Move Down"), action: {self.move(selection.wrappedValue!, by: 1)}))
        }

        buttons.append(.cancel(Text("Cancel"), action: {}))

        return buttons
    }

    func scheduleButton(_ schedule: Binding<Schedule>, _ text: Binding<String>, _ label: Binding<String>,
                        _ subSchedule: Binding<Schedule?>, _ subText: Binding<String>, _ subLabel: Binding<String>) -> AnyView {
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
            })
            Button("Every N Days", action: {
                schedule.wrappedValue = .cyclic(2)
                text.wrappedValue = "2"
                label.wrappedValue = " days"
                
                subSchedule.wrappedValue = nil
                subText.wrappedValue = ""
                subLabel.wrappedValue = ""
            })
            Button("Week Days", action: {
                schedule.wrappedValue = .days([.monday, .wednesday, .friday])
                text.wrappedValue = "Mon Wed Fri"
                label.wrappedValue = ""
                
                subSchedule.wrappedValue = nil
                subText.wrappedValue = ""
                subLabel.wrappedValue = ""
            })
            Button("Weeks", action: {
                subSchedule.wrappedValue = .days([.monday, .wednesday, .friday])
                subText.wrappedValue = "Mon Wed Fri"
                subLabel.wrappedValue = ""

                schedule.wrappedValue = .weeks([1, 3], subSchedule.wrappedValue!)
                text.wrappedValue = "1 3"
                label.wrappedValue = ""
                
            })
            Button("Cancel", action: {})
        }.font(.callout)
        return AnyView(button)
    }

    func subScheduleButton(_ schedule: Binding<Schedule?>, _ text: Binding<String>, _ label: Binding<String>) -> AnyView {
        var menuText = ""
        switch schedule.wrappedValue! {
        case .anyDay: menuText = "Any Day"
        case .cyclic(_): menuText = "Every"
        case .days(_): menuText = "Days"
        case .weeks(_, _): ASSERT(false, "sub-schedule cannot be weeks")
        }

        let button = Menu(menuText) {
            Button("Any Day", action: {schedule.wrappedValue = .anyDay; text.wrappedValue = ""; label.wrappedValue = ""})
            Button("Every N Days", action: {schedule.wrappedValue = .cyclic(2); text.wrappedValue = "2"; label.wrappedValue = " days"})
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
            ForEach(self.program.exercises(self.workout).reversed()) {exercise in
                if self.exercises.firstIndex(where: {$0.name == exercise.name}) == nil {
                    Button(exercise.name, action: {self.append(exercise.instance(self.workout))})
                }
            }
        }.font(.callout)
        return AnyView(button)
    }

    func label(_ exercise: InstanceVM) -> String {
        return exercise.name
    }

    func subLabel(_ exercise: InstanceVM) -> String {
        let tuple = exercise.workoutLabel()
        let sets = tuple.0
        let trailer = tuple.1
        let limit = 8
        
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

    func color(_ exercise: InstanceVM) -> Color {
        if self.recentlyCompleted(exercise) {
            return .gray
        } else if exercise.inProgress() {
            return .blue
        } else {
            return .black
        }
    }
}

// Editing
extension WorkoutVM {
    func render() -> (Schedule, String, String, Schedule?, String, String) {
        switch self.workout.schedule {
        case .anyDay:
            return (self.workout.schedule, "", "", nil, "", "")
        case .cyclic(let n):
            return (self.workout.schedule, n.description, "days", nil, "", "")
        case .days(let days):
            return (self.workout.schedule, self.renderWeekDays(days), "", nil, "", "")
        case .weeks(let weeks, let subSchedule):
            let w = weeks.map({$0.description})
            switch subSchedule {
            case .anyDay:
                return (self.workout.schedule, w.joined(separator: " "), "", subSchedule, "", "")
            case .cyclic(let n):
                return (self.workout.schedule, w.joined(separator: " "), "", subSchedule, n.description, "days")
            case .days(let days):
                return (self.workout.schedule, w.joined(separator: " "), "", subSchedule, self.renderWeekDays(days), "")
            case .weeks(_, let subSchedule):
                ASSERT(false, "sub-schedule can't be weeks")
                return (self.workout.schedule, "", "", subSchedule, "", "")
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
                result = .days(days)
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
    return percent.value >= 0.01 && weight >= 0.1 ? " @ " + friendlyUnitsWeight(weight) : ""
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
