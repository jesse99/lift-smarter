//  Created by Jesse Vorisek on 10/6/21.
import SwiftUI

struct EditFixedRepsView: View {
    let exerciseName: String
    let sets: Binding<Sets>
    @State var reps: String
    @State var rest: String
    @State var showHelp = false
    @State var helpText = ""
    @State var error = ""
    @Environment(\.presentationMode) var presentation

    init(_ exerciseName: String, _ sets: Binding<Sets>) {
        self.exerciseName = exerciseName
        self.sets = sets

        let table = sets.wrappedValue.render()
        self._reps = State(initialValue: table["reps"]!)
        self._rest = State(initialValue: table["rest"]!)
    }
    
    var body: some View {
        VStack() {
            Text("Edit " + self.exerciseName).font(.largeTitle)

            VStack(alignment: .leading) {
                numericishField("Reps", self.$reps, self.onEditedSets, self.onRepsHelp)
                numericishField("Rest", self.$rest, self.onEditedSets, self.onRestHelp)
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
        .alert(isPresented: $showHelp) {   // and views can only have one alert
            return Alert(
                title: Text("Help"),
                message: Text(self.helpText),
                dismissButton: .default(Text("OK")))
        }
    }

    func onCancel() {
        self.presentation.wrappedValue.dismiss()
    }

    func onOK() {
        let table = ["reps": self.reps, "rest": self.rest]
        switch sets.wrappedValue.parse(table) {
        case .right(let sets):
            self.sets.wrappedValue = sets
        case .left(_):
            ASSERT(false, "validate should have prevented this from executing")
        }
        
        self.presentation.wrappedValue.dismiss()
    }

    private func onEditedSets(_ text: String) {
        let table = ["reps": self.reps, "rest": self.rest]
        switch sets.wrappedValue.parse(table) {
        case .right(_):
            self.error = ""
        case .left(let err):
            self.error = err
        }
    }
    
    func onRepsHelp() {
        self.helpText = "The number of reps to do for each set."
        self.showHelp = true
    }

    private func onRestHelp() {
        self.helpText = restHelpText
        self.showHelp = true
    }
}

struct EditFixedRepsView_Previews: PreviewProvider {
    static let model = mockModel()
    static let program = ProgramVM(model)
    static let workout = model.program.workouts[1]
    static let exercise = model.program.exercises.first(where: {$0.name == "Foam Rolling"})!
    static var sets = Binding.constant(exercise.modality.sets)

    static var previews: some View {
        EditFixedRepsView(exercise.name, sets)
    }
}
