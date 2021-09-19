//  Created by Jesse Vorisek on 9/12/21.
import SwiftUI

struct ExerciseView: View {
    @ObservedObject var exercise: ExerciseVM

    init(_ exercise: ExerciseVM) {
        self.exercise = exercise
    }

    var body: some View {
        self.exercise.view()
    }
}

struct ExerciseView_Previews: PreviewProvider {
    static let model = mockModel()
    static let workout = model.program.workouts[0]
    static let exercise = model.program.exercises.first(where: {$0.name == "Sleeper Stretch"})!
    static let instance = workout.instances.first(where: {$0.name == "Sleeper Stretch"})!
    static let vm = WorkoutVM(ProgramVM(model), workout)
    
    static var previews: some View {
        ExerciseView(ExerciseVM(vm, exercise, instance))
    }
}
