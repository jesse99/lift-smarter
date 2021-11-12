//  Created by Jesse Vorisek on 10/24/21.
import SwiftUI

struct EditMaxRepsView: View {
    let exerciseName: String
    let info: Binding<ExerciseInfo>
    @State var rest: String
    @State var targetReps: String
    @State var expected: String
    @State var showHelp = false
    @State var helpText = ""
    @State var error = ""
    @Environment(\.presentationMode) var presentation

    init(_ exerciseName: String, _ info: Binding<ExerciseInfo>) {
        self.exerciseName = exerciseName
        self.info = info

        let table = info.wrappedValue.render()
        self._rest = State(initialValue: table["rest"]!)
        self._targetReps = State(initialValue: table["target"]!)
        self._expected = State(initialValue: table["expected"]!)
    }
    
    var body: some View {
        VStack() {
            Text("Edit " + self.exerciseName).font(.largeTitle)

            VStack(alignment: .leading) {
                numericishField("Rest", self.$rest, self.onEditedInfo, self.onRestHelp)
                intField("Target Reps", self.$targetReps, self.onEditedInfo, self.onTargetHelp)
                numericishField("Expected Reps", self.$expected, self.onEditedInfo, self.onExpectedHelp)
            }
            Spacer()
            Text(self.error).foregroundColor(.red).font(.callout)

            Divider()
            HStack {
                Button("Cancel", action: onCancel).font(.callout)
                Spacer()
                Spacer()
                Button("OK", action: onOK).font(.callout).disabled(!self.error.isEmpty)
            }
            .padding()
        }
        .alert(isPresented: $showHelp) {
            return Alert(
                title: Text("Help"),
                message: Text(self.helpText),
                dismissButton: .default(Text("OK")))
        }
    }

    private func onCancel() {
        self.presentation.wrappedValue.dismiss()
    }

    private func onOK() {
        let table = ["rest": self.rest, "target": self.targetReps, "expected": self.expected]
        switch info.wrappedValue.parse(table) {
        case .right(let newInfo):
            self.info.wrappedValue = newInfo
        case .left(_):
            ASSERT(false, "validate should have prevented this from executing")
        }
        
        app.saveState()
        self.presentation.wrappedValue.dismiss()
    }

    private func onEditedInfo(_ text: String) {
        let table = ["rest": self.rest, "target": self.targetReps, "expected": self.expected]
        switch info.wrappedValue.parse(table) {
        case .right(_):
            self.error = ""
        case .left(let err):
            self.error = err
        }
    }
    
    private func onTargetHelp() {
        self.helpText = "The goal for this particular exercise. Often when the goal is reached weight is increased or a harder variant of the exercise is used. Empty means that there is no target."
        self.showHelp = true
    }

    private func onRestHelp() {
        self.helpText = restHelpText
        self.showHelp = true
    }
    
    private func onExpectedHelp() {
        self.helpText = "The number of reps you expect to do for each set. Can be empty."
        self.showHelp = true
    }
}

struct EditMaxRepsView_Previews: PreviewProvider {
    static let model = mockModel()
    static let program = ProgramVM(model)
    static let exercise = model.program.exercises.first(where: {$0.name == "Curls"})!
    static var info = Binding.constant(exercise.info)

    static var previews: some View {
        EditMaxRepsView(exercise.name, info)
    }
}
