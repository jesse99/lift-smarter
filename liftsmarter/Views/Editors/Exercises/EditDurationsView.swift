//  Created by Jesse Vorisek on 9/12/21.
import SwiftUI

let restHelpText = "The amount of time to rest after each set. Time units may be omitted so '1.5m 60s 30 0' is a minute and a half, 60 seconds, 30 seconds, and no rest time."

struct EditDurationsView: View {
    let exerciseName: String
    let info: Binding<ExerciseInfo>
    @State var durations: String
    @State var target: String
    @State var rest: String
    @State var showHelp = false
    @State var helpText = ""
    @State var error = ""
    @Environment(\.presentationMode) var presentation

    init(_ exerciseName: String, _ info: Binding<ExerciseInfo>) {
        self.exerciseName = exerciseName
        self.info = info

        let table = info.wrappedValue.render()
        self._durations = State(initialValue: table["durations"]!)
        self._rest = State(initialValue: table["rest"]!)
        self._target = State(initialValue: table["target"]!)
    }
    
    var body: some View {
        VStack() {
            Text("Edit " + self.exerciseName).font(.largeTitle)

            VStack(alignment: .leading) {
                numericishField("Durations", self.$durations, self.onEditedInfo, self.onDurationsHelp)
                numericishField("Target", self.$target, self.onEditedInfo, self.onTargetHelp)
                numericishField("Rest", self.$rest, self.onEditedInfo, self.onRestHelp)
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
        let table = ["durations": self.durations, "rest": self.rest, "target": self.target]
        switch info.wrappedValue.parse(table) {
        case .right(let newInfo):
            self.info.wrappedValue = newInfo
        case .left(_):
            ASSERT(false, "validate should have prevented this from executing")
        }
        
        self.presentation.wrappedValue.dismiss()
    }

    private func onEditedInfo(_ text: String) {
        let table = ["durations": self.durations, "rest": self.rest, "target": self.target]
        switch info.wrappedValue.parse(table) {
        case .right(_):
            self.error = ""
        case .left(let err):
            self.error = err
        }
    }
    
    func onDurationsHelp() {
        self.helpText = "The amount of time to perform each set. Time units may be omitted so '1.5m 60s 30 0' is a minute and a half, 60 seconds, 30 seconds, and no rest time."
        self.showHelp = true
    }

    private func onRestHelp() {
        self.helpText = restHelpText
        self.showHelp = true
    }

    func onTargetHelp() {
        self.helpText = "Optional goal time for each set. Often when reaching the target a harder variation of the exercise is used."
        self.showHelp = true
    }
}

struct EditDurationsView_Previews: PreviewProvider {
    static let model = mockModel()
    static let program = ProgramVM(model)
    static let exercise = model.program.exercises.first(where: {$0.name == "Sleeper Stretch"})!
    static var info = Binding.constant(exercise.info)

    static var previews: some View {
        EditDurationsView(exercise.name, info)
    }
}
