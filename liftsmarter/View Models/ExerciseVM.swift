//  Created by Jesse Vorisek on 10/2/21.
import Foundation
import SwiftUI

enum Progress {
    case notStarted
    case started
    case finished
}

// This is used with exercises in a global context, i.e. for exercise state that isn't associated with a workout.
class ExerciseVM: Equatable, Identifiable, ObservableObject {
    let program: ProgramVM
    private let exercise: Exercise
    
    init(_ program: ProgramVM, _ exercise: Exercise) {
        self.program = program
        self.exercise = exercise
    }
    
    func willChange() {
        self.objectWillChange.send()
        self.program.willChange()
    }

    var name: String {
        get {return self.exercise.name}
    }
    
    var formalName: String {
        get {return self.exercise.formalName}
    }
    
    var userNoteKeys: [String] {
        get {return self.program.userNoteKeys}
    }
    
    var allowRest: Bool {
        get {return self.exercise.allowRest}
    }
    
    var apparatus: Apparatus {
        get {return self.exercise.apparatus}
    }

    func getClosestBelow(_ target: Double) -> Either<String, Double> {
        switch self.exercise.apparatus {
        case .fixedWeights(name: let name):
            if let name = name {
                let model = self.program.model(self.exercise)
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

    var activeFWSName: String {
        get {
            if case .fixedWeights(let name) = self.exercise.apparatus {
                return name ?? ""
            } else {
                ASSERT(false, "should only be called for fixedWeights")
                return ""
            }
        }
    }
    
    var info: ExerciseInfo {
        get {return self.exercise.info}
    }

    func numSets() -> Int? {
        switch self.exercise.info {
        case .durations(let info):
            return info.sets.count
        case .fixedReps(let info):
            return info.sets.count
        case .maxReps(let info):
            return info.restSecs.count
        case .repRanges(let info):
            return info.sets.count
        case .repTotal(_):
            return nil
        }
    }

    func fixedRep() -> Int? {
        switch self.exercise.info {
        case .repRanges(let info):
            let set = info.currentSet()
            if let max = set.reps.max, set.reps.min == max {
                return set.reps.min
            } else {
                return nil  // m-n or m+
            }
        default:
            return nil
        }
    }
        
    var expectedWeight: Double {
        switch self.exercise.info {
        case .durations(let info):
            return info.expectedWeight
        case .fixedReps(let info):
            return info.expectedWeight
        case .maxReps(let info):
            return info.expectedWeight
        case .repRanges(let info):
            return info.expectedWeight
        case .repTotal(let info):
            return info.expectedWeight
        }
    }

    func advancedWeight() -> Double? {
        switch self.exercise.apparatus {
        case .bodyWeight:
            return nil
            
        case .fixedWeights(name: let name):
            if let name = name, let fws = self.program.getFixedWeights()[name] {
                return fws.getClosestAbove(self.expectedWeight)
            }
            return nil
        }
    }

    static func ==(lhs: ExerciseVM, rhs: ExerciseVM) -> Bool {
        return lhs.name == rhs.name
    }
    
    var id: String {
        get {
            return self.name
        }
    }
}

// Mutators
extension ExerciseVM {
    func setName(_ name: String) {
        self.program.modify(self.exercise, callback: {$0.name = name})
    }
    
    func setFormalName(_ name: String) {
        self.program.modify(self.exercise, callback: {$0.formalName = name})
    }
    
    func setAllowRest(_ allow: Bool) {
        self.program.modify(self.exercise, callback: {$0.allowRest = allow})
    }

    func setApparatus(_ apparatus: Apparatus) {
        self.program.modify(self.exercise, callback: {
            switch $0.info {
            case .durations(let info):
                info.resetExpected()        // TODO: don't reset expected for minor edits (like adding a magnet)
            case .fixedReps(let info):
                info.resetExpected()
            case .maxReps(let info):
                info.resetExpected()
            case .repRanges(let info):
                info.resetExpected()
            case .repTotal(let info):
                info.resetExpected()
            }
            $0.apparatus = apparatus
        })
    }

    func setActiveFixedWeight(_ name: String?) {
        self.program.modify(self.exercise, callback: {$0.apparatus = .fixedWeights(name: name)})
    }
    
    func setInfo(_ info: ExerciseInfo) { 
        self.program.modify(self.exercise, callback: {$0.info = info})
    }
    
    func advanceWeight() {
        let weight = self.advancedWeight()!
        self.program.modify(self.exercise, callback: {
            switch $0.info {
            case .durations(let info):
                info.expectedWeight = weight
            case .fixedReps(let info):
                info.expectedWeight = weight
            case .maxReps(let info):
                info.expectedWeight = weight
            case .repRanges(let info):
                info.expectedWeight = weight
                info.expectedReps = []
            case .repTotal(let info):
                info.expectedWeight = weight
            }
        })
    }

    func setWeight(_ weight: Double) {
        self.program.modify(self.exercise, callback: {
            switch $0.info {
            case .durations(let info):
                info.expectedWeight = weight
            case .fixedReps(let info):
                info.expectedWeight = weight
            case .maxReps(let info):
                info.expectedWeight = weight
            case .repRanges(let info):
                info.expectedWeight = weight
            case .repTotal(let info):
                info.expectedWeight = weight
            }
        })
    }
}

// UI
extension ExerciseVM {
    // EditExerciseView
    func label() -> String {
        return self.name
    }

    func subLabel() -> String {
        var enabled: [String] = []
        var disabled: [String] = []
        
        for workout in self.program.workouts {
            for instance in workout.instances {
                if instance.name == self.name {
                    if instance.enabled {
                        enabled.append(workout.name)
                    } else {
                        disabled.append(workout.name)
                    }
                }
            }
        }
        
        if disabled.isEmpty {
            enabled.sort()
            return enabled.joined(separator: ", ")
            
        } else if enabled.isEmpty {
            disabled.sort()
            let text2 = disabled.joined(separator: ", ")
            return "[\(text2)]"

        } else {
            enabled.sort()
            disabled.sort()

            let text1 = enabled.joined(separator: ", ")
            let text2 = disabled.joined(separator: ", ")
            return "\(text1) [\(text2)]"
        }
    }

    func canDelete() -> Bool {
        for workout in self.program.workouts {
            for instance in workout.instances {
                if instance.name == self.name {
                    return false
                }
            }
        }
        return true
    }

    func weightPicker(_ text: Binding<String>, _ modal: Binding<Bool>, _ onEdit: @escaping (String) -> Void, _ onHelp: @escaping HelpFunc) -> AnyView {
        // Some apparatus can have large jumps (10 lbs is common for dumbbells, 15 can happen on cable machines).
        // But if the weight the user wants to use is way off what they can do then we'll highlight that.
        let badWeight = 20.0
        
        func populate(_ text: String, _ fws: FixedWeightSet) -> [(String, Color)] {
            if let desired = Double(text) {
                let actual = fws.getClosestBelow(desired)    // for worksets we use closest below
                return fws.getAll().map({
                    if abs($0 - actual) < 0.01 {
                        if abs(desired - actual) > badWeight {
                            return (friendlyWeight($0), .red)
                        } else {
                            return (friendlyWeight($0), .blue)
                        }
                    } else {
                        return (friendlyWeight($0), .black)
                    }
                })
            } else {
                return fws.getAll().map({return (friendlyWeight($0), .black)})
            }
        }
        
        func select(_ text: String, _ fws: FixedWeightSet) -> Int? {
            if let desired = Double(text) {
                let actual = fws.getClosestBelow(desired)
                let entries = fws.getAll()
                for i in 0..<entries.count {
                    let candidate = entries[i]
                    if abs(candidate - actual) < 0.01 {
                        if abs(desired - actual) < badWeight {
                            return i
                        }
                    }
                }
                if let biggest = entries.last, desired > biggest {
                    return entries.count - 1
                }
            }
            return nil
        }
        
        func buttonColor(_ fws: FixedWeightSet) -> Color {
            if let weight = Double(text.wrappedValue) {
                let actual = fws.getClosestBelow(weight)
                if weight > 0.0 && abs(actual - weight) > badWeight {
                    return .red
                } else {
                    return .black
                }
            } else {
                return .red
            }
        }
        
        func confirm(_ newText: String) {
            text.wrappedValue = newText
            onEdit(newText)
        }
        
        func weightField() -> AnyView {
            return AnyView(
                HStack {
                    Text("Weight:").font(.headline)
                    TextField("", text: text)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.decimalPad)
                        .disableAutocorrection(true)
                        .onChange(of: text.wrappedValue, perform: onEdit)
                    Button("?", action: onHelp).font(.callout).padding(.trailing)
                }.padding(.leading)
            )
        }
        
        // This isn't currently shared but it's complex enough that we define it here to hide it away.
        switch self.exercise.apparatus {
        case .bodyWeight:
            return weightField()
            
        case .fixedWeights(let theName):
            if let name = theName, let fws = self.program.getFWS(name) {
                return AnyView(
                    HStack {
                        Text("Weight:").font(.headline)
                        Button(text.wrappedValue, action: {modal.wrappedValue = true})
                            .font(.callout)
                            .foregroundColor(buttonColor(fws))
                            .sheet(isPresented: modal) {
                                PickerView(title: name, prompt: "Value:", initial: text.wrappedValue, populate: {populate($0, fws)}, confirm: confirm, selected: {text in select(text, fws)}, type: .decimalPad)
                            }
                        Spacer()
                        Button("?", action: onHelp).font(.callout).padding(.trailing)
                    }.padding(.leading)
                )
            } else {
                return weightField()
            }
        }
    }

    func infoView(_ exerciseName: String, _ einfo: Binding<ExerciseInfo>, _ modal: Binding<Bool>, _ onHelp: @escaping Help2Func) -> AnyView {
        func change(_ newValue: ExerciseInfo) {
            if newValue.caseIndex() != self.exercise.info.caseIndex() {
                einfo.wrappedValue = newValue
            } else {
                // If the user is swtching back to the original sets then use the original settings.
                einfo.wrappedValue = self.exercise.info
            }
        }
        
        switch einfo.wrappedValue {
        case .durations(_):
            return AnyView(
                HStack {
                    Button("Edit", action: {modal.wrappedValue = true})
                        .font(.callout)
                        .sheet(isPresented: modal) {EditDurationsView(exerciseName, einfo)}
                    Spacer()
                    Menu("Durations") {     // TODO: should this (and apparatus) omit the menu item for the current selection
                        Button("Durations", action: {change(defaultDurations())})
                        Button("Fixed Reps", action:   {change(defaultFixedReps())})
                        Button("Max Reps", action: {change(defaultMaxReps())})
                        Button("Rep Ranges", action: {change(defaultRepRanges())})
                        Button("Rep Total", action: {change(defaultRepTotal())})
                        Button("Cancel", action: {})
                    }.font(.callout).padding(.leading)
                    Spacer()
                    Button("?", action: {onHelp("Each set is done for a time interval.")}).font(.callout)
                }.padding()
            )
            
        case .fixedReps(_):
            return AnyView(
                HStack {
                    Button("Edit", action: {modal.wrappedValue = true})
                        .font(.callout)
                        .sheet(isPresented: modal) {EditFixedRepsView(exerciseName, einfo)}
                    Spacer()
                    Menu("Fixed Reps") {
                        Button("Durations", action: {change(defaultDurations())})
                        Button("Fixed Reps", action:   {change(defaultFixedReps())})
                        Button("Max Reps", action: {change(defaultMaxReps())})
                        Button("Rep Ranges", action: {change(defaultRepRanges())})
                        Button("Rep Total", action: {change(defaultRepTotal())})
                        Button("Cancel", action: {})
                    }.font(.callout).padding(.leading)
                    Spacer()
                    Button("?", action: {onHelp("Sets and reps are both fixed. No support for weight percentages.")}).font(.callout)
                }.padding()
            )

        case .maxReps(_):
            return AnyView(
                HStack {
                    Button("Edit", action: {modal.wrappedValue = true})
                        .font(.callout)
                        .sheet(isPresented: modal) {EditMaxRepsView(exerciseName, einfo)}
                    Spacer()
                    Menu("Max Reps") {
                        Button("Durations", action: {change(defaultDurations())})
                        Button("Fixed Reps", action:   {change(defaultFixedReps())})
                        Button("Max Reps", action: {change(defaultMaxReps())})
                        Button("Rep Ranges", action: {change(defaultRepRanges())})
                        Button("Rep Total", action: {change(defaultRepTotal())})
                        Button("Cancel", action: {})
                    }.font(.callout).padding(.leading)
                    Spacer()
                    Button("?", action: {onHelp("As many reps as possible for each set.")}).font(.callout)
                }.padding()
            )

        case .repRanges(_):
            return AnyView(
                HStack {
                    Button("Edit", action: {modal.wrappedValue = true})
                        .font(.callout)
                        .sheet(isPresented: modal) {EditRepRangesView(exerciseName, einfo)}
                    Spacer()
                    Menu("Rep Ranges") {
                        Button("Durations", action: {change(defaultDurations())})
                        Button("Fixed Reps", action:   {change(defaultFixedReps())})
                        Button("Max Reps", action: {change(defaultMaxReps())})
                        Button("Rep Ranges", action: {change(defaultRepRanges())})
                        Button("Rep Total", action: {change(defaultRepTotal())})
                        Button("Cancel", action: {})
                    }.font(.callout).padding(.leading)
                    Spacer()
                    Button("?", action: {onHelp("Has optional warmup and backoff sets. Reps are within a specified range and weight percentages can be used.")}).font(.callout)
                }.padding()
            )
            
        case .repTotal(_):
            return AnyView(
                HStack {
                    Button("Edit", action: {modal.wrappedValue = true})
                        .font(.callout)
                        .sheet(isPresented: modal) {EditRepTotalView(exerciseName, einfo)}
                    Spacer()
                    Menu("Rep Total") {
                        Button("Durations", action: {change(defaultDurations())})
                        Button("Fixed Reps", action:   {change(defaultFixedReps())})
                        Button("Max Reps", action: {change(defaultMaxReps())})
                        Button("Rep Ranges", action: {change(defaultRepRanges())})
                        Button("Rep Total", action: {change(defaultRepTotal())})
                        Button("Cancel", action: {})
                    }.font(.callout).padding(.leading)
                    Spacer()
                    Button("?", action: {onHelp("As many sets as required to do total reps.")}).font(.callout)
                }.padding()
            )
        }
    }

    func apparatusView(_ apparatus: Binding<Apparatus>, _ modal: Binding<Bool>, _ onHelp: @escaping Help2Func) -> AnyView {
        func change(_ newValue: Apparatus) {
            if newValue.caseIndex() != self.exercise.apparatus.caseIndex() {
                apparatus.wrappedValue = newValue
            } else {
                // If the user is swtching back to the original apparatus then use the original settings.
                apparatus.wrappedValue = self.exercise.apparatus
            }
        }
        
        switch apparatus.wrappedValue {
        case .bodyWeight:
            return AnyView(
                HStack {
                    Button("Edit", action: {modal.wrappedValue = true})
                        .font(.callout).disabled(true)
                    Spacer()
                
                    Menu("Body Weight") {
                        Button("Body Weight", action:   {change(.bodyWeight)})
                        Button("Fixed Weights", action: {change(.fixedWeights(name: nil))})
                        Button("Cancel", action: {})
                    }.font(.callout).padding(.leading)
                    Spacer()
                    
                    Button("?", action: {onHelp("Includes an optional arbitrary weight.")}).font(.callout)
                }.padding()
            )

        case .fixedWeights(_):
            return AnyView(
                HStack {
                    Button("Edit", action: {modal.wrappedValue = true})
                        .font(.callout)
                        .sheet(isPresented: modal) {EditFWSsView(self.program, apparatus)}
                    Spacer()
                
                    Menu("Fixed Weights") {
                        Button("Body Weight", action:   {change(.bodyWeight)})
                        Button("Fixed Weights", action: {change(.fixedWeights(name: nil))})
                        Button("Cancel", action: {})
                    }.font(.callout).padding(.leading)
                    Spacer()
                    
                    Button("?", action: {onHelp("Dumbbells, kettlebells, cable machines, etc.")}).font(.callout)
                }.padding()
            )
        }
    }
}

// Editing
extension ExerciseVM {
    func parseExercise(_ name: String, _ weightStr: String) -> Either<String, Double> {
        var errors: [String] = []
        
        if name.isBlankOrEmpty() {
            errors.append("Name cannot be empty.")
        } else if name != self.name {
            if self.program.exercises.any({$0.name == name}) {
                errors.append("Name must be unique.")
            }
        }
        
        let weight = Double(weightStr)
        if let w = weight {
            if w < 0.0 {
                errors.append("Weight cannot be negative.")
            }
        } else {
            errors.append("Weight should be a number.")
        }
        
        if !errors.isEmpty {
            return .left(errors.joined(separator: " "))
        } else {
            return .right(weight!)
        }
    }
}

// View Model internals (views can't call these because they don't have direct access
// to model classes).
extension ExerciseVM {
    func exercise(_ model: Model) -> Exercise {
        return self.exercise
    }

    func exercise(_ workout: Workout) -> Exercise {
        return self.exercise
    }
}

