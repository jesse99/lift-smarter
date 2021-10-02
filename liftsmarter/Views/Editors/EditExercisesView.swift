//  Created by Jesse Vorisek on 10/2/21.
import SwiftUI

struct EditExercisesView: View {
    let program: ProgramVM
    @State var oldExercises: [String]
    @State var selection: String? = nil
    @State var showEditActions = false

    init(_ program: ProgramVM) {
        self.program = program
//        self._name = State(initialValue: program.name)
        self._oldExercises = State(initialValue: program.exercises)
//
//        let (current, rest) = program.render()
//        self._currentWeek = State(initialValue: current.description)
//        self._restWeeks = State(initialValue: rest)
    }
    
    var body: some View {
        VStack() {
            Text("Edit Exercises").font(.largeTitle)

//            List(self.program.exercises) {name in
//                VStack() {
//                    Text(name).font(.headline)
//                }
//                .contentShape(Rectangle())  // so we can click within spacer
//                    .onTapGesture {
//                        self.selection = name
//                        self.showEditActions = true
//                    }
//            }
        }
    }
}

struct EditExercisesView_Previews: PreviewProvider {
    static let model = mockModel()
    static let program = ProgramVM(model)

    static var previews: some View {
        EditExercisesView(program)
    }
}
