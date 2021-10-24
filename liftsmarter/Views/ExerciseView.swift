//  Created by Jesse Vorisek on 9/12/21.
import SwiftUI

struct ExerciseView: View {
    let program: ProgramVM
    @ObservedObject var instance: InstanceVM

    init(_ program: ProgramVM, _ instance: InstanceVM) {
        self.program = program
        self.instance = instance
    }

    var body: some View {
        self.instance.view(self.program)
    }
}

struct ExerciseView_Previews: PreviewProvider {
    static let model = mockModel()
    static let program = ProgramVM(model)
    static let workout = WorkoutVM(program, model.program.workouts[0])
    static let exercise = model.program.exercises.first(where: {$0.name == "Sleeper Stretch"})!
    static let instance = workout.instances.first(where: {$0.name == "Sleeper Stretch"})!
    
    static var previews: some View {
        ExerciseView(program, instance)
    }
}
