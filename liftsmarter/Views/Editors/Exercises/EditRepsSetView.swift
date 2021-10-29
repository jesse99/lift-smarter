//  Created by Jesse Vorisek on 10/27/21.
import SwiftUI

struct EditRepsSetView: View {
    let exerciseName: String
    let info: Binding<ExerciseInfo>

    init(_ exerciseName: String, _ info: Binding<ExerciseInfo>) {
        self.exerciseName = exerciseName
        self.info = info

//        let table = info.wrappedValue.render()
//        self._total = State(initialValue: table["total"]!)
//        self._rest = State(initialValue: table["rest"]!)
//        self._expected = State(initialValue: table["expected"]!)
    }
    
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

struct EditRepsSetView_Previews: PreviewProvider {
    static let model = mockModel()
    static let program = ProgramVM(model)
    static let exercise = model.program.exercises.first(where: {$0.name == "Split Squat"})!
    static var info = Binding.constant(exercise.info)

    static var previews: some View {
        EditRepsSetView(exercise.name, info)
    }
}
