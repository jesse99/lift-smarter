//  Created by Jesse Vorisek on 10/2/21.
import Foundation

// Typically InstanceVM is used instead of this.
class ExerciseVM: Equatable, Identifiable {
    let program: ProgramVM
    private let exercise: Exercise
    
    init(_ program: ProgramVM, _ exercise: Exercise) {
        self.program = program
        self.exercise = exercise
    }
    
    func willChange() {
        self.program.willChange()
    }

    var name: String {
        get {return self.exercise.name}
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
// If we ever support editing the exercise itself then we'll need to make ExerciseVM ObservableObject.
extension ExerciseVM {
}

// UI Labels
extension ExerciseVM {
    func label() -> String {
        return self.name
    }

    func subLabel() -> String {
        var enabled: [String] = []
        var disabled: [String] = []
        
        for workout in self.program.workouts {
            for instance in workout.exercises {
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
            for instance in workout.exercises {
                if instance.name == self.name {
                    return false
                }
            }
        }
        return true
    }
}

// Editing
extension ExerciseVM {
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

