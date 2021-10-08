//  Created by Jesse Vorisek on 10/7/21.
import SwiftUI

struct EditExerciseView: View {
    let exercise: ExerciseVM
    @State var name: String
    @State var formalName: String
    @State var weight: String
    @State var allowRest: Bool
    @State var formalNameModal = false
    @State var showHelp = false
    @State var helpText = ""
    @State var error = ""
    @Environment(\.presentationMode) var presentation

    init(_ exercise: ExerciseVM) {
        self.exercise = exercise

        self._name = State(initialValue: exercise.name)
        self._formalName = State(initialValue: exercise.formalName)
        self._weight = State(initialValue: friendlyWeight(exercise.expectedWeight))
        self._allowRest = State(initialValue: exercise.allowRest)
    }

    // TODO:
    // make sure that name and weight work
    // get formal name working
    // add a picker for weight?
    // get some sort of allow rest checkbox working
    // get sets editing working
    //    be sure to reset expected.sets
    // get aparatus editing working
    var body: some View {
        VStack() {
            Text("Edit Exercise").font(.largeTitle).padding()

            VStack(alignment: .leading) {
                HStack {
                    Text("Name:").font(.headline)
                    TextField("", text: self.$name)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.default)
                        .disableAutocorrection(true)
                        .autocapitalization(.words)
                        .onChange(of: self.name, perform: self.onEdited)
                    Button("?", action: self.onNameHelp).font(.callout).padding(.trailing)
                }.padding(.leading)

                HStack {
                    Text("Formal Name:").font(.headline)
                    Button(self.formalName, action: {self.formalNameModal = true})
                        .font(.callout)
//                        .sheet(isPresented: self.$formalNameModal) {PickerView(title: "Formal Name", prompt: "Name: ", initial: self.formalName, populate: matchFormalName, confirm: self.onEditedFormalName)}
                    Spacer()
                    Button("?", action: self.onFormalNameHelp).font(.callout).padding(.trailing)
                }.padding(.leading)

                // TODO: Probably want to handle weight differently for different apparatus. For example, for barbell
                // could use a picker like formal name uses: user can type in a weight and then is able to see
                // all the nearby weights and select one if he wants.
                HStack {
                    Text("Weight:").font(.headline)
                    TextField("", text: self.$weight)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.decimalPad)
                        .onChange(of: self.weight, perform: self.onEdited)
                    Button("?", action: self.onWeightHelp).font(.callout).padding(.trailing)
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
        .alert(isPresented: $showHelp) {
            return Alert(
                title: Text("Help"),
                message: Text(self.helpText),
                dismissButton: .default(Text("OK")))
        }
    }

    private func onEdited(_ text: String) {
        switch exercise.parseExercise(self.name, self.weight) {
        case .right(_):
            self.error = ""
        case .left(let err):
            self.error = err
        }
    }

    func onCancel() {
        self.presentation.wrappedValue.dismiss()
    }

    func onOK() {
        switch exercise.parseExercise(self.name, self.weight) {
        case .right(let weight):
            if self.name != self.exercise.name {
                self.exercise.setName(self.name)
            }
            if self.formalName != self.exercise.formalName {
                self.exercise.setFormalName(self.formalName)
            }
            if weight != self.exercise.expectedWeight {
                self.exercise.setWeight(weight)
            }
        case .left(_):
            ASSERT(false, "onEdited should have caught this")
        }

        self.presentation.wrappedValue.dismiss()
    }

    private func onNameHelp() {
        self.helpText = "Your name for the exercise, e.g. 'Light OHP'."
        self.showHelp = true
    }

    private func onFormalNameHelp() {
        self.helpText = "The actual name for the exercise, e.g. 'Overhead Press'. This is used to lookup notes for the exercise."
        self.showHelp = true
    }

    private func onWeightHelp() {
        self.helpText = "An arbitrary weight. For stuff like barbells the app will use the closest supported weight below this weight."
        self.showHelp = true
    }
}

struct EditExerciseView_Previews: PreviewProvider {
    static let model = mockModel()
    static let program = ProgramVM(model)
    static let workout = model.program.workouts[1]
    static let exercise = model.program.exercises.first(where: {$0.name == "Foam Rolling"})!
    static let vm = ExerciseVM(ProgramVM(model), exercise)

    static var previews: some View {
        EditExerciseView(vm)
    }
}
