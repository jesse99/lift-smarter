//  Created by Jesse Vorisek on 10/2/21.
import SwiftUI

struct EditExercisesView: View {
    let program: ProgramVM
    @State var oldExercises: [ExerciseVM]
    @State var showAddSheet: Bool = false
    @State var selection: ExerciseVM? = nil
    @State var showEditActions = false
    @Environment(\.presentationMode) private var presentation

    init(_ program: ProgramVM) {
        self.program = program
        self._oldExercises = State(initialValue: program.exercises)
    }
    
    var body: some View {
        VStack() {
            Text("Edit Exercises").font(.largeTitle)

            List(self.program.exercises) {exercise in
                VStack(alignment: .leading) {
                    Text(exercise.label()).font(.title)
                    
                    let sub = exercise.subLabel()
                    if !sub.isEmpty {
                        Text(sub).font(.headline)
                    }
                }
                .contentShape(Rectangle())  // so we can click within spacer
                    .onTapGesture {
                        self.selection = exercise
                        self.showEditActions = true
                    }
            }

            Divider()
            HStack {
                Button("Cancel", action: self.onCancel).font(.callout)
                Spacer()
                Spacer()
                Button("Add", action: self.onAdd).font(.callout)
                Button("OK", action: self.onOK).font(.callout)
            }
            .padding()
        }
        .actionSheet(isPresented: $showEditActions) {
            ActionSheet(title: Text(self.selection!.name), buttons: self.program.editExerciseButtons(self.$selection))}
        .sheet(isPresented: self.$showAddSheet) {EditTextView(title: "Exercise Name", content: "", caps: .words, validator: self.onValidateAdd, sender: self.doAdd)}
    }
    
    private func onAdd() {
        self.showAddSheet = true
    }
    
    private func onValidateAdd(_ text: String) -> String {
        if text.isBlankOrEmpty() {
            return "Exercise name cannot be empty."
        }
        for exercise in self.program.exercises {
            if exercise.name == text {
                return "Exercise names must be unique."
            }
        }
        return ""
    }

    private func doAdd(_ text: String) {
        self.program.addExercise(text)
    }

    private func onCancel() {
        if self.oldExercises != self.program.exercises {
            self.program.setExercises(self.oldExercises)
        }
        self.presentation.wrappedValue.dismiss()
    }

    private func onOK() {
        self.presentation.wrappedValue.dismiss()
    }
}

struct EditExercisesView_Previews: PreviewProvider {
    static let model = mockModel()
    static let program = ProgramVM(model)

    static var previews: some View {
        EditExercisesView(program)
    }
}
