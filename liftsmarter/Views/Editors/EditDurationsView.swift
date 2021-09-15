//  Created by Jesse Vorisek on 9/12/21.
import SwiftUI

let restHelpText = "The amount of time to rest after each set. Time units may be omitted so '1.5m 60s 30 0' is a minute and a half, 60 seconds, 30 seconds, and no rest time."

struct EditDurationsView: View {
    let model: Model
    var exercise: Exercise
    @State var durations: String
    @State var target: String
    @State var rest: String
    @State var showHelp = false
    @State var helpText = ""
    @State var error = ""
    @Environment(\.presentationMode) var presentation

    init(_ model: Model, _ exercise: Exercise) {
        self.model = model
        self.exercise = exercise

        let strings = renderDurations(exercise.modality.sets)
        self._durations = State(initialValue: strings.0)
        self._rest = State(initialValue: strings.1)
        self._target = State(initialValue: strings.2)
    }
    
    var body: some View {
        VStack() {
            Text("Edit " + self.exercise.name).font(.largeTitle)

            VStack(alignment: .leading) {
                HStack {
                    Text("Durations:").font(.headline)
                    TextField("", text: self.$durations)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.default)
                        .disableAutocorrection(true)
                        .onChange(of: self.durations, perform: self.onEditedSets)
                    Button("?", action: self.onDurationsHelp).font(.callout).padding(.trailing)
                }.padding(.leading)
                HStack {
                    Text("Target:").font(.headline)
                    TextField("", text: self.$target)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.default)
                        .disableAutocorrection(true)
                        .onChange(of: self.target, perform: self.onEditedSets)
                    Button("?", action: self.onTargetHelp).font(.callout).padding(.trailing)
                }.padding(.leading)
                HStack {
                    Text("Rest:").font(.headline)
                    TextField("", text: self.$rest)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.default)
                        .disableAutocorrection(true)
                        .onChange(of: self.rest, perform: self.onEditedSets)
                    Button("?", action: self.onRestHelp).font(.callout).padding(.trailing)
                }.padding(.leading)
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
        switch parseDurations(durations: self.durations, rest: self.rest, target: self.target) {
        case .right(let sets):
            self.model.program.objectWillChange.send()
            self.exercise.modality.sets = sets
        case .left(_):
            ASSERT(false, "validate should have prevented this from executing")
        }
        
        self.presentation.wrappedValue.dismiss()
    }

    private func onEditedSets(_ text: String) {
        switch parseDurations(durations: self.durations, rest: self.rest, target: self.target) {
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

    // TODO: reset expected?
}

struct EditDurationsView_Previews: PreviewProvider {
    static let model = mockModel()
    static let exercise = model.program.exercises.first(where: {$0.name == "Sleeper Stretch"})!

    static var previews: some View {
        EditDurationsView(model, exercise)
    }
}
