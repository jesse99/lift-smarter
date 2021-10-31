//  Created by Jesse Vorisek on 10/24/21.
import SwiftUI

struct EditRepTotalView: View {
    let exerciseName: String
    let info: Binding<ExerciseInfo>
    @State var total: String
    @State var rest: String
    @State var expected: String
    @State var showHelp = false
    @State var helpText = ""
    @State var error = ""
    @Environment(\.presentationMode) var presentation

    init(_ exerciseName: String, _ info: Binding<ExerciseInfo>) {
        self.exerciseName = exerciseName
        self.info = info

        let table = info.wrappedValue.render()
        self._total = State(initialValue: table["total"]!)
        self._rest = State(initialValue: table["rest"]!)
        self._expected = State(initialValue: table["expected"]!)
    }
    
    var body: some View {
        VStack() {
            Text("Edit " + self.exerciseName).font(.largeTitle)

            VStack(alignment: .leading) {
                intField("Total Reps", self.$total, self.onEditedInfo, self.onTotalHelp)
                numericishField("Rest", self.$rest, self.onEditedInfo, self.onRestHelp)
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
        .alert(isPresented: $showHelp) {   // and views can only have one alert
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
        let table = ["total": self.total, "rest": self.rest, "expected": self.expected]
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
        let table = ["total": self.total, "rest": self.rest, "expected": self.expected]
        switch info.wrappedValue.parse(table) {
        case .right(_):
            self.error = ""
        case .left(let err):
            self.error = err
        }
    }
    
    private func onTotalHelp() {
        self.helpText = "Number of reps to do across arbitrary number of sets."
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

struct EditRepTotalView_Previews: PreviewProvider {
    static let model = mockModel()
    static let program = ProgramVM(model)
    static let exercise = model.program.exercises.first(where: {$0.name == "Pushup"})!
    static var info = Binding.constant(exercise.info)

    static var previews: some View {
        EditRepTotalView(exercise.name, info)
    }
}
