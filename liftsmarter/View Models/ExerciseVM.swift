//  Created by Jesse Vorisek on 10/2/21.
import Foundation
import SwiftUI

// Typically InstanceVM is used instead of this.
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
    
    var expectedWeight: Double {
        get {return self.exercise.expected.weight}
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

// Misc Logic
extension ExerciseVM {
    func setName(_ name: String) {
        self.willChange()
        
        for workout in self.program.workouts {
            for instance in workout.instances {
                if instance.name == self.exercise.name {
                    instance.setName(name)
                }
            }
        }

        self.exercise.name = name
    }
    
    func setFormalName(_ name: String) {
        self.willChange()
        self.exercise.formalName = name
    }
    
    func setWeight(_ weight: Double) {
        self.willChange()
        self.exercise.expected.weight = weight
    }
    
    func setAllowRest(_ allow: Bool) {
        self.willChange()
        self.exercise.allowRest = allow
    }
}

// UI
extension ExerciseVM {
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
        func populate(_ text: String, _ fws: FixedWeightSet) -> [String] {
            var weights: [Double] = []
            
            if let weight = Double(text) {
                let middle = fws.getClosest(weight)
                if let below = fws.getBelow(middle) {
                    weights.append(below)
                }
                weights.append(middle)
                if let above = fws.getAbove(middle) {
                    weights.append(above)
                }
            } else {
                weights = fws.getAll()
            }

            return weights.map({friendlyWeight($0)})
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
        switch self.exercise.modality.apparatus {
        case .bodyWeight:
            return weightField()
            
        case .fixedWeights(let theName):
            if let name = theName, let fws = self.program.getFWS(name) {
                return AnyView(
                    HStack {
                        Text("Weight:").font(.headline)
                        Button(text.wrappedValue, action: {modal.wrappedValue = true})
                            .font(.callout)
                            .sheet(isPresented: modal) {
                                PickerView(title: name, prompt: "Value:", initial: text.wrappedValue, populate: {populate($0, fws)}, confirm: confirm, type: .decimalPad)
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

//    func instance(_ model: Model) -> ExerciseInstance {
//        return self.instance
//    }
//
//    func instance(_ workout: Workout) -> ExerciseInstance {
//        return self.instance
//    }
}

