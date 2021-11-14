//  Created by Jesse Vorisek on 11/14/21.
import SwiftUI

struct EditPercentageView: View {
    let exercise: ExerciseVM
    let info: Binding<ExerciseInfo>
    @State var percent: String
    @State var rest: String
    @State var baseName: String
    @State var showHelp = false
    @State var helpText = ""
    @State var error = ""
    @Environment(\.presentationMode) var presentation

    init(_ exercise: ExerciseVM, _ info: Binding<ExerciseInfo>) {
        self.exercise = exercise
        self.info = info

        let table = info.wrappedValue.render()
        self._percent = State(initialValue: table["percent"]!)
        self._rest = State(initialValue: table["rest"]!)
        self._baseName = State(initialValue: table["baseName"]!)
    }
    
    var body: some View {
        VStack() {
            Text("Edit " + self.exercise.name).font(.largeTitle)

            VStack(alignment: .leading) {
                intField("Percent", self.$percent, self.onEditedInfo, self.onPercentHelp)
                numericishField("Rest", self.$rest, self.onEditedInfo, self.onRestHelp)
                self.exercise.baseNamePicker(self.$baseName, self.onBaseNameHelp).font(.callout)
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
        let table = ["percent": self.percent, "rest": self.rest, "baseName": self.baseName]
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
        let table = ["percent": self.percent, "rest": self.rest, "baseName": self.baseName]
        switch info.wrappedValue.parse(table) {
        case .right(_):
            self.error = ""
        case .left(let err):
            self.error = err
        }
    }
    
    private func onPercentHelp() {
        self.helpText = "Percentage of the base exercise to use."
        self.showHelp = true
    }

    private func onRestHelp() {
        self.helpText = restHelpText
        self.showHelp = true
    }
    
    private func onBaseNameHelp() {
        self.helpText = "The name of the other exercise."
        self.showHelp = true
    }
}

struct EditPercentageView_Previews: PreviewProvider {
    static let model = mockModel()
    static let program = ProgramVM(ModelVM(model), model)
    static let exercise = ExerciseVM(program, model.program.exercises.first(where: {$0.name == "Light Squat"})!)
    static var info = Binding.constant(exercise.info)

    static var previews: some View {
        EditPercentageView(exercise, info)
    }
}
