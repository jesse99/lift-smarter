//  Created by Jesse Vorisek on 10/7/21.
import SwiftUI

struct EditExerciseView: View {
    let exercise: ExerciseVM
    let instance: InstanceVM
    @State var name: String
    @State var formalName: String
    @State var weight: String
    @State var allowRest: Bool
    @State var formalNameModal = false
    @State var showHelp = false
    @State var helpText = ""
    @State var error = ""
    @Environment(\.presentationMode) var presentation

    init(_ instance: InstanceVM) {
        self.exercise = instance.exerciseVM
        self.instance = instance

        self._name = State(initialValue: exercise.name)
        self._formalName = State(initialValue: exercise.formalName)
        self._weight = State(initialValue: friendlyWeight(exercise.expectedWeight))
        self._allowRest = State(initialValue: exercise.allowRest)
    }

    // TODO:
    // add a picker for weight?
    // get some sort of allow rest checkbox working
    // get sets editing working
    //    be sure to reset expected.sets
    // get aparatus editing working
    var body: some View {
        VStack() {
            Text("Edit Exercise").font(.largeTitle).padding()

            VStack(alignment: .leading) {
                wordsField("Name", self.$name, self.onEdited, onHelp: self.onNameHelp)

                HStack {
                    Text("Formal Name:").font(.headline)
                    Button(self.formalName, action: {self.formalNameModal = true})
                        .font(.callout)
                        .sheet(isPresented: self.$formalNameModal) {PickerView(title: "Formal Name", prompt: "Name: ", initial: self.formalName, populate: matchFormalName, confirm: self.onEditedFormalName)}
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
    
    private func onEditedFormalName(_ text: String) {
        self.formalName = text      // no need for validation here
    }

    private func matchFormalName(_ inText: String) -> [String] {
        var names: [String] = []
        
        // TODO: better to do a proper fuzzy search
        let needle = inText.filter({!$0.isWhitespace}).filter({!$0.isPunctuation}).lowercased()

        // First match any custom names defined by the user.
        for candidate in self.exercise.userNoteKeys {
            if defaultNotes[candidate] == nil {
                let haystack = candidate.filter({!$0.isWhitespace}).filter({!$0.isPunctuation}).lowercased()
                if haystack.contains(needle) {
                    names.append(candidate)
                }
            }
        }
        
        // Then match the standard names.
        for candidate in defaultNotes.keys {
            let haystack = candidate.filter({!$0.isWhitespace}).filter({!$0.isPunctuation}).lowercased()
            if haystack.contains(needle) {
                names.append(candidate)
            }
            
            // Not much point in showing the user a huge list of names.
            if names.count >= 100 {
                break
            }
        }

        return names
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
    static let instance = workout.instances.first(where: {$0.name == "Foam Rolling"})!
    static let vm = InstanceVM(WorkoutVM(program, workout), exercise, instance)

    static var previews: some View {
        EditExerciseView(vm)
    }
}
