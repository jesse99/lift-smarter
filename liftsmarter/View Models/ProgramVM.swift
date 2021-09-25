//  Created by Jesse Vorisek on 9/18/21.
import Foundation

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
    
    var instanceClipboard: [ExerciseInstance] {
        get {return self.model.program.instanceClipboard}
    }
    
    func willChange() {
        self.objectWillChange.send()
    }
}

// Misc logic
extension ProgramVM {
    func log(_ level: LogLevel, _ message: String) {
        let vm = LogsVM(model)
        vm.log(level, message)
    }
    
    func copyInstances(_ exercises: [ExerciseVM]) {
        self.willChange()
        self.model.program.instanceClipboard = exercises.map({$0.instance(self.model)})
    }
}

// View Model internals (views can't call these because they don't have direct access
// to model classes).
extension ProgramVM {
    func exercices(_ workout: Workout) -> [ExerciseVM] {
        let vm = WorkoutVM(self, workout)
        return self.model.program.exercises.map({
            return ExerciseVM(vm, $0, ExerciseInstance($0.name))
        })
    }

    func instances(_ workout: Workout) -> [ExerciseVM] {
        let vm = WorkoutVM(self, workout)
        return workout.instances.map({
            let name = $0.name
            let exercise = self.model.program.exercises.first(where: {$0.name == name})!
            return ExerciseVM(vm, exercise, $0)
        })
    }
}
