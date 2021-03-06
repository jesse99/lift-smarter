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
        get {
            switch self.exercise.info {
            case .percentage(let info):
                if let base = self.program.exercises.first(where: {$0.name == info.baseName}) {
                    return base.apparatus
                }
                return self.exercise.apparatus
            default:
                return self.exercise.apparatus
            }
        }
    }

    func getClosest(_ target: Double) -> Either<String, ActualWeights> {
        let model = self.program.model(self.exercise)
        switch self.apparatus {
        case .dualPlates(barWeight: let bar, let name):
            if let name = name {
                if let plates = model.platesSet[name] {
                    let actuals = plates.getClosest(target - bar, dual: true)
                    return .right(ActualWeights(total: actuals.total + bar, weights: actuals.weights))
                } else {
                    return .left("There are no plates named \(name)")
                }
            } else {
                return .left("No plates activated")
            }
        case .bells(name: let name):
            if let name = name {
                if let bells = model.bellsSet[name] {
                    return .right(bells.getClosest(target))
                } else {
                    return .left("There is no bells named \(name)")
                }
            } else {
                return .left("No bells activated")
            }
        case .singlePlates(let name):
            if let name = name {
                if let plates = model.platesSet[name] {
                    return .right(plates.getClosest(target, dual: false))
                } else {
                    return .left("There are no plates named \(name)")
                }
            } else {
                return .left("No plates activated")
            }
        default:
            return .right(ActualWeights(total: target, weights: [ActualWeight(weight: target, label: "")]))
        }
    }

    func getClosestBelow(_ target: Double) -> Either<String, ActualWeights> {
        let model = self.program.model(self.exercise)
        switch self.apparatus {
        case .dualPlates(barWeight: let bar, let name):
            if let name = name {
                if let plates = model.platesSet[name] {
                    let actuals = plates.getClosestBelow(target - bar, dual: true)
                    return .right(ActualWeights(total: actuals.total + bar, weights: actuals.weights))
                } else {
                    return .left("There are no plates named \(name)")
                }
            } else {
                return .left("No plates activated")
            }
        case .bells(name: let name):
            if let name = name {
                if let bells = model.bellsSet[name] {
                    return .right(bells.getClosestBelow(target))
                } else {
                    return .left("There are no bells named \(name)")
                }
            } else {
                return .left("No bells activated")
            }
        case .singlePlates(let name):
            if let name = name {
                if let plates = model.platesSet[name] {
                    return .right(plates.getClosestBelow(target, dual: false))
                } else {
                    return .left("There are no plates named \(name)")
                }
            } else {
                return .left("No plates activated")
            }
        default:
            return .right(ActualWeights(total: target, weights: [ActualWeight(weight: target, label: "")]))
        }
    }

    var info: ExerciseInfo {
        get {return self.exercise.info}
    }

    func numSets() -> Int {
        switch self.exercise.info {
        case .durations(let info):
            return info.sets.count
        case .fixedReps(let info):
            return info.sets.count
        case .maxReps(let info):
            return info.restSecs.count
        case .percentage(let info):
            if let base = self.program.exercises.first(where: {$0.name == info.baseName}) {
                return base.numSets()
            }
            return 0
        case .repRanges(let info):
            return info.sets.count
        case .repTotal:
            return 0
        }
    }

    // Usually the expectedReps method in InstanceVM is used instead.
    func expectedReps(setIndex: Int) -> Int {
        switch self.exercise.info {
        case .fixedReps(let info):
            return info.sets.at(setIndex)?.reps.reps ?? info.sets.last?.reps.reps ?? 1
        case .maxReps(let info):
            return info.expectedReps.at(setIndex) ?? info.expectedReps.last ?? 1
        case .percentage(let info):
            if let base = self.program.exercises.first(where: {$0.name == info.baseName}) {
                return base.expectedReps(setIndex: setIndex)
            }
            return 0
        case .repRanges(let info):
            return info.expectedReps.at(setIndex)?.reps ?? info.sets.at(setIndex)?.reps.min ?? 1
        case .repTotal(let info):
            return info.expectedReps.at(setIndex) ?? info.expectedReps.last ?? 1
        case .durations:
            return 0
        }
    }
        
    var baseExpectedWeight: Double {
        switch self.exercise.info {
        case .durations(let info):
            return info.expectedWeight
        case .fixedReps(let info):
            return info.expectedWeight
        case .maxReps(let info):
            return info.expectedWeight
        case .percentage(let info):
            if let base = self.program.exercises.first(where: {$0.name == info.baseName}) {
                return info.percent*base.baseExpectedWeight
            }
            return 0.0
        case .repRanges(let info):
            return info.expectedWeight
        case .repTotal(let info):
            return info.expectedWeight
        }
    }
    
    func expectedWeight(_ setIndex: Int) -> Double {
        switch self.exercise.info {
        case .percentage(let info):
            if let base = self.program.exercises.first(where: {$0.name == info.baseName}) {
                return info.percent*base.expectedWeight(setIndex)
            }
            return 0.0
        case .repRanges(let info):
            return self.baseExpectedWeight * (info.sets.at(setIndex)?.percent ?? WeightPercent(0.0))
        default:
            return self.baseExpectedWeight
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
        
    func advancedWeight() -> Double? {
        switch self.apparatus {
        case .bodyWeight:
            return nil
            
        case .dualPlates(barWeight: let bar, let name):
            if let name = name, let plates = self.program.getPlatesSet()[name], let weight = plates.getAbove(self.baseExpectedWeight - bar, dual: true) {
                return weight.total + bar
            }
            return nil

        case .bells(name: let name):
            if let name = name, let bells = self.program.getBellsSet()[name], let weight = bells.getAbove(self.baseExpectedWeight) {
                return weight.total
            }
            return nil
            
        case .singlePlates(let name):
            if let name = name, let plates = self.program.getPlatesSet()[name] {
                let weight = plates.getAbove(self.baseExpectedWeight, dual: false)
                return weight?.total
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
        for workout in self.program.workouts {
            workout.renamed(oldExercise: self.exercise.name, newExercise: name)
        }
        
        self.program.model(self.exercise).history.renamed(oldExercise: self.exercise.name, newExercise: name)

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
            case .percentage(let info):
                info.resetExpected()
            case .repRanges(let info):
                info.resetExpected()
            case .repTotal(let info):
                info.resetExpected()
            }
            $0.apparatus = apparatus
        })
    }

    func setInfo(_ info: ExerciseInfo) { 
        self.program.modify(self.exercise, callback: {$0.info = info.clone()})
        
        let exercise = self.program.model(exercise).program.exercises.first(where: {$0.name == self.name})!
        exercise.info.resetCurrent(0.0)    // validate expects program exercies to have default current
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
            case .percentage:
                ASSERT(false, "no advancing for percentage")
            case .repRanges(let info):
                info.expectedWeight = weight
                if info.sets.any({$0.reps.min < ($0.reps.max ?? $0.reps.min)}) {
                    info.expectedReps = []
                }
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
            case .percentage:
                break
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

    func weightPicker(_ apparatus: Apparatus, _ text: Binding<String>, _ modal: Binding<Bool>, _ onEdit: @escaping (String) -> Void, _ onHelp: @escaping HelpFunc) -> AnyView {
        // Some apparatus can have large jumps (10 lbs is common for dumbbells, 15 can happen on cable machines).
        // But if the weight the user wants to use is way off what they can do then we'll highlight that.
        let badWeight = 20.0
        
        func populate(_ text: String, _ bells: Bells) -> [(String, Color)] {
            if let desired = Double(text) {
                let actual = bells.getClosestBelow(desired)    // for worksets we use closest below
                return bells.getAll().map({
                    if sameWeight($0.total, actual.total) {
                        if abs(desired - actual.total) > badWeight {
                            return (friendlyWeight($0.total), .red)
                        } else {
                            return (friendlyWeight($0.total), .blue)
                        }
                    } else {
                        return (friendlyWeight($0.total), .black)
                    }
                })
            } else {
                return bells.getAll().map({return (friendlyWeight($0.total), .black)})
            }
        }
        
        func populate(_ bar: Double, _ text: String, _ plates: Plates, dual: Bool) -> [(String, Color)] {
            if var desired = Double(text) {
                desired -= bar
                let actual = plates.getClosestBelow(desired, dual: dual)    // for worksets we use closest below
                return plates.getAll(dual: dual).map({
                    if sameWeight($0.total, actual.total) {
                        if abs(desired - actual.total) > badWeight {
                            return (friendlyWeight($0.total + bar), .red)
                        } else {
                            return (friendlyWeight($0.total + bar), .blue)
                        }
                    } else {
                        return (friendlyWeight($0.total + bar), .black)
                    }
                })
            } else {
                return plates.getAll(dual: dual).map({return (friendlyWeight($0.total + bar), .black)})
            }
        }
        
        func select(_ text: String, _ bells: Bells) -> Int? {
            if let desired = Double(text) {
                let actual = bells.getClosestBelow(desired)
                let entries = bells.getAll()
                for i in 0..<entries.count {
                    let candidate = entries[i]
                    if sameWeight(candidate.total, actual.total) {
                        if abs(desired - actual.total) < badWeight {
                            return i
                        }
                    }
                }
                if let biggest = entries.last?.total, desired > biggest {
                    return entries.count - 1
                }
            }
            return nil
        }
        
        func select(_ bar: Double, _ text: String, _ plates: Plates, dual: Bool) -> Int? {
            if var desired = Double(text) {
                desired -= bar
                let actual = plates.getClosestBelow(desired, dual: dual)
                let entries = plates.getAll(dual: dual)
                for i in 0..<entries.count {
                    let candidate = entries[i]
                    if sameWeight(candidate.total, actual.total) {
                        if abs(desired - actual.total) < badWeight {
                            return i
                        }
                    }
                }
                if let biggest = entries.last?.total, desired > biggest {
                    return entries.count - 1
                }
            }
            return nil
        }
        
        func buttonColor(_ bells: Bells) -> Color {
            if let weight = Double(text.wrappedValue) {
                let actual = bells.getClosestBelow(weight)
                if weight > 0.0 && abs(actual.total - weight) > badWeight {
                    return .red
                } else {
                    return .black
                }
            } else {
                return .red
            }
        }
        
        func shouldDisable() -> Bool {
            switch self.info {
            case .percentage:
                return true
            default:
                return false
            }
        }
        
        func buttonColor(_ bar: Double, _ plates: Plates, dual: Bool) -> Color {
            if shouldDisable() {    // kinda lame, shouldn't even call this function if it should be disabled
                return .gray
            }
            if var weight = Double(text.wrappedValue) {
                weight -= bar
                let actual = plates.getClosestBelow(weight, dual: dual)
                if weight > 0.0 && abs(actual.total - weight) > badWeight {
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
        switch apparatus {
        case .bodyWeight:
            return weightField()

        case .dualPlates(barWeight: let bar, let name):
            if let name = name, let plates = self.program.getPlatesSet()[name] {
                return AnyView(
                    HStack {
                        Text("Weight:").font(.headline)
                        Button(text.wrappedValue, action: {modal.wrappedValue = true})
                            .font(.body)
                            .foregroundColor(buttonColor(bar, plates, dual: true))
                            .disabled(shouldDisable())
                            .sheet(isPresented: modal) {
                                PickerView(title: "Weight", prompt: "Value:", initial: text.wrappedValue, populate: {populate(bar, $0, plates, dual: true)}, confirm: confirm, selected: {text in select(bar, text, plates, dual: true)}, type: .decimalPad)
                            }
                        Spacer()
                        Button("?", action: onHelp).font(.callout).padding(.trailing)
                    }.padding(.leading)
                )
            } else {
                return weightField()
            }

        case .bells(let theName):
            if let name = theName, let bells = self.program.getBells(name) {
                return AnyView(
                    HStack {
                        Text("Weight:").font(.headline)
                        Button(text.wrappedValue, action: {modal.wrappedValue = true})
                            .font(.body)
                            .foregroundColor(buttonColor(bells))
                            .disabled(shouldDisable())
                            .sheet(isPresented: modal) {
                                PickerView(title: name, prompt: "Value:", initial: text.wrappedValue, populate: {populate($0, bells)}, confirm: confirm, selected: {text in select(text, bells)}, type: .decimalPad)
                            }
                        Spacer()
                        Button("?", action: onHelp).font(.callout).padding(.trailing)
                    }.padding(.leading)
                )
            } else {
                return weightField()
            }

        case .singlePlates(let name):
            if let name = name, let plates = self.program.getPlatesSet()[name] {
                return AnyView(
                    HStack {
                        Text("Weight:").font(.headline)
                        Button(text.wrappedValue, action: {modal.wrappedValue = true})
                            .font(.body)
                            .foregroundColor(buttonColor(0.0, plates, dual: false))
                            .disabled(shouldDisable())
                            .sheet(isPresented: modal) {
                                PickerView(title: "Weight", prompt: "Value:", initial: text.wrappedValue, populate: {populate(0.0, $0, plates, dual: false)}, confirm: confirm, selected: {text in select(0.0, text, plates, dual: false)}, type: .decimalPad)
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
        case .durations:
            return AnyView(
                HStack {
                    Button("Edit", action: {modal.wrappedValue = true})
                        .font(.callout)
                        .sheet(isPresented: modal) {EditDurationsView(exerciseName, einfo)}
                    Spacer()
                    Menu("Durations") {     // TODO: should this (and apparatus) omit the menu item for the current selection
                        // TODO: usually these items will be displayed in the reverse order but that is actually context dependent, see https://stackoverflow.com/questions/67124144/is-there-any-option-to-set-order-for-menu-items-in-swiftui
                        Button("Cancel", action: {})
                        Button("Rep Total", action: {change(defaultRepTotal())})
                        Button("Rep Ranges", action: {change(defaultRepRanges())})
                        Button("Percentage", action: {change(defaultPercentage())})
                        Button("Max Reps", action: {change(defaultMaxReps())})
                        Button("Fixed Reps", action:   {change(defaultFixedReps())})
                        Button("Durations", action: {change(defaultDurations())})
                    }.font(.callout).padding(.leading)
                    Spacer()
                    Button("?", action: {onHelp("Each set is done for a time interval.")}).font(.callout)
                }.padding()
            )
            
        case .fixedReps:
            return AnyView(
                HStack {
                    Button("Edit", action: {modal.wrappedValue = true})
                        .font(.callout)
                        .sheet(isPresented: modal) {EditFixedRepsView(exerciseName, einfo)}
                    Spacer()
                    Menu("Fixed Reps") {
                        Button("Cancel", action: {})
                        Button("Rep Total", action: {change(defaultRepTotal())})
                        Button("Rep Ranges", action: {change(defaultRepRanges())})
                        Button("Percentage", action: {change(defaultPercentage())})
                        Button("Max Reps", action: {change(defaultMaxReps())})
                        Button("Fixed Reps", action:   {change(defaultFixedReps())})
                        Button("Durations", action: {change(defaultDurations())})
                    }.font(.callout).padding(.leading)
                    Spacer()
                    Button("?", action: {onHelp("Sets and reps are both fixed. No support for weight percentages.")}).font(.callout)
                }.padding()
            )

        case .maxReps:
            return AnyView(
                HStack {
                    Button("Edit", action: {modal.wrappedValue = true})
                        .font(.callout)
                        .sheet(isPresented: modal) {EditMaxRepsView(exerciseName, einfo)}
                    Spacer()
                    Menu("Max Reps") {
                        Button("Cancel", action: {})
                        Button("Rep Total", action: {change(defaultRepTotal())})
                        Button("Rep Ranges", action: {change(defaultRepRanges())})
                        Button("Percentage", action: {change(defaultPercentage())})
                        Button("Max Reps", action: {change(defaultMaxReps())})
                        Button("Fixed Reps", action:   {change(defaultFixedReps())})
                        Button("Durations", action: {change(defaultDurations())})
                    }.font(.callout).padding(.leading)
                    Spacer()
                    Button("?", action: {onHelp("As many reps as possible for each set.")}).font(.callout)
                }.padding()
            )

        case .percentage:
            return AnyView(
                HStack {
                    Button("Edit", action: {modal.wrappedValue = true})
                        .font(.callout)
                        .sheet(isPresented: modal) {EditPercentageView(self, einfo)}
                    Spacer()
                    Menu("Percentage") {
                        Button("Cancel", action: {})
                        Button("Rep Total", action: {change(defaultRepTotal())})
                        Button("Rep Ranges", action: {change(defaultRepRanges())})
                        Button("Percentage", action: {change(defaultPercentage())})
                        Button("Max Reps", action: {change(defaultMaxReps())})
                        Button("Fixed Reps", action:   {change(defaultFixedReps())})
                        Button("Durations", action: {change(defaultDurations())})
                    }.font(.callout).padding(.leading)
                    Spacer()
                    Button("?", action: {onHelp("Do what is expected for another exercise but scale weight by a percentage.")}).font(.callout)
                }.padding()
            )

        case .repRanges:
            return AnyView(
                HStack {
                    Button("Edit", action: {modal.wrappedValue = true})
                        .font(.callout)
                        .sheet(isPresented: modal) {EditRepRangesView(exerciseName, einfo)}
                    Spacer()
                    Menu("Rep Ranges") {
                        Button("Cancel", action: {})
                        Button("Rep Total", action: {change(defaultRepTotal())})
                        Button("Rep Ranges", action: {change(defaultRepRanges())})
                        Button("Percentage", action: {change(defaultPercentage())})
                        Button("Max Reps", action: {change(defaultMaxReps())})
                        Button("Fixed Reps", action:   {change(defaultFixedReps())})
                        Button("Durations", action: {change(defaultDurations())})
                    }.font(.callout).padding(.leading)
                    Spacer()
                    Button("?", action: {onHelp("Has optional warmup and backoff sets. Reps are within a specified range and weight percentages can be used.")}).font(.callout)
                }.padding()
            )
            
        case .repTotal:
            return AnyView(
                HStack {
                    Button("Edit", action: {modal.wrappedValue = true})
                        .font(.callout)
                        .sheet(isPresented: modal) {EditRepTotalView(exerciseName, einfo)}
                    Spacer()
                    Menu("Rep Total") {
                        Button("Cancel", action: {})
                        Button("Rep Total", action: {change(defaultRepTotal())})
                        Button("Rep Ranges", action: {change(defaultRepRanges())})
                        Button("Percentage", action: {change(defaultPercentage())})
                        Button("Max Reps", action: {change(defaultMaxReps())})
                        Button("Fixed Reps", action:   {change(defaultFixedReps())})
                        Button("Durations", action: {change(defaultDurations())})
                    }.font(.callout).padding(.leading)
                    Spacer()
                    Button("?", action: {onHelp("As many sets as required to do total reps.")}).font(.callout)
                }.padding()
            )
        }
    }

    func apparatusView(_ apparatus: Binding<Apparatus>, _ modal: Binding<Bool>, _ onHelp: @escaping Help2Func) -> AnyView {
        func change(_ newValue: Apparatus) {
            self.program.willChange()
            if newValue.caseIndex() != self.apparatus.caseIndex() {
                apparatus.wrappedValue = newValue
            } else {
                // If the user is swtching back to the original apparatus then use the original settings.
                apparatus.wrappedValue = self.apparatus
            }
        }
        
        func fixedApparatus() -> Bool {
            switch self.info {
            case .percentage:
                return true
            default:
                return false
            }
        }
        
        func buildMenu(_ title: String) -> AnyView {
            if fixedApparatus() {
                return AnyView(
                    Button(title, action: {})
                        .font(.callout).padding(.leading).disabled(true))
            } else {
                return AnyView(
                    Menu(title) {
                        Button("Body Weight", action:   {change(.bodyWeight)})
                        Button("Dual Plates", action:   {change(.dualPlates(barWeight: 45, nil))})
                        Button("Other Weights", action: {change(.bells(name: nil))})
                        Button("Single Plates", action: {change(.singlePlates(nil))})
                        Button("Cancel", action: {})
                    }.font(.callout).padding(.leading))
            }
        }
        
        switch apparatus.wrappedValue {
        case .bodyWeight:
            return AnyView(
                HStack {
                    Button("Edit", action: {modal.wrappedValue = true})
                        .font(.callout).disabled(true)
                    Spacer()
                
                    buildMenu("Body Weight")
                    Spacer()
                    
                    Button("?", action: {onHelp("Includes an optional arbitrary weight.")}).font(.callout)
                }.padding()
            )

        case .dualPlates(barWeight: _, _):
            return AnyView(
                HStack {
                    Button("Edit", action: {modal.wrappedValue = true})
                        .font(.callout)
                        .sheet(isPresented: modal) {EditPlatesSetView(self.program, apparatus)}
                    Spacer()
                
                    buildMenu("Dual Plates")
                    Spacer()
                    
                    Button("?", action: {onHelp("Barbells, leg press, etc.")}).font(.callout)
                }.padding()
            )

        case .bells:
            return AnyView(
                HStack {
                    Button("Edit", action: {modal.wrappedValue = true})
                        .font(.callout)
                        .sheet(isPresented: modal) {EditBellsSetView(self.program, apparatus)}
                    Spacer()
                
                    buildMenu("Other Weights")
                    Spacer()
                    
                    Button("?", action: {onHelp("Dumbbells, kettlebells, cable machines, etc.")}).font(.callout)
                }.padding()
            )

        case .singlePlates:
            return AnyView(
                HStack {
                    Button("Edit", action: {modal.wrappedValue = true})
                        .font(.callout)
                        .sheet(isPresented: modal) {EditPlatesSetView(self.program, apparatus)}
                    Spacer()
                
                    buildMenu("Single Plates")
                    Spacer()
                    
                    Button("?", action: {onHelp("T-Bar rows, landmines, etc.")}).font(.callout)
                }.padding()
            )
        }
    }
    
    // EditPercentageView
    func baseNamePicker(_ baseName: Binding<String>, _ onHelp: @escaping HelpFunc) -> AnyView {
        func menuColor() -> Color {
            if let base = self.program.instances.first(where: {$0.name == baseName.wrappedValue}) {
                switch base.exercise.info {
                case .durations, .percentage, .repTotal:
                    return .red
                default:
                    return .blue
                }
            } else {
                return .red
            }
        }
        
        func entries() -> [ListEntry] {
            let candidates = self.program.instances.filter({
                switch $0.exercise.info {
                case .durations, .percentage, .repTotal:
                    return false
                default:
                    return $0.name != baseName.wrappedValue
                }
            })
            var entries: [ListEntry] = []
            for (i, candidate) in candidates.enumerated() {
                if entries.first(where: {$0.name == candidate.name}) == nil {
                    entries.append(ListEntry(candidate.name, .black, i))
                }
            }
            return entries.sorted(by: {$0.name < $1.name})
        }
        
        return AnyView(
            HStack {
                Text("Base Bame:").font(.headline)
                Menu(baseName.wrappedValue) {
                    ForEach(entries()) {entry in
                        Button(entry.name, action: {baseName.wrappedValue = entry.name})
                    }
                    Button("Cancel", action: {})
                }.font(.callout).foregroundColor(menuColor())
                Spacer()
                Button("?", action: onHelp).font(.callout).padding(.trailing)
            }.padding(.leading)
        )
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

