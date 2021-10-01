//  Created by Jesse Vorisek on 9/26/21.
import SwiftUI

struct EditProgramView: View {
    let program: ProgramVM
    @State var name: String
    @State var currentWeek: String
    @State var restWeeks: String
    @State var oldWorkouts: [WorkoutVM]
    @State var selection: WorkoutVM? = nil
    @State var showEditActions = false
    @State var confirm: Confirmation? = nil
    @State var error = ""
    @Environment(\.presentationMode) private var presentation

    init(_ program: ProgramVM) {
        self.program = program
        self._name = State(initialValue: program.name)
        self._oldWorkouts = State(initialValue: program.workouts)

        let (current, rest) = program.render()
        self._currentWeek = State(initialValue: current.description)
        self._restWeeks = State(initialValue: rest)
    }
    
    var body: some View {
        VStack() {
            Text("Edit Workout").font(.largeTitle)

            VStack(alignment: .leading) {
                HStack {
                    Text("Name:").font(.headline)
                    TextField("", text: self.$name)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.default)
                        .autocapitalization(.words)
                        .disableAutocorrection(false)
                        .onChange(of: self.name, perform: self.onEdited)
                }.padding(.leading).padding(.trailing)

                HStack {
                    Text("Current Week:").font(.headline)
                    TextField("", text: self.$currentWeek)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.numberPad)
                        .onChange(of: self.currentWeek, perform: self.onEdited)
                }.padding(.leading).padding(.trailing)

                HStack {
                    Text("Rest Weeks:").font(.headline)
                    TextField("", text: self.$restWeeks)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.default)
                        .onChange(of: self.restWeeks, perform: self.onEdited)
                }.padding(.leading).padding(.trailing)

                List(self.program.workouts) {workout in
                    VStack() {
                        if workout.enabled {
                            Text(workout.name).font(.headline)
                        } else {
                            Text(workout.name).font(.headline).strikethrough(color: .red)
                        }
                    }
                    .contentShape(Rectangle())  // so we can click within spacer
                        .onTapGesture {
                            self.selection = workout
                            self.showEditActions = true
                        }
                }
            }
            Spacer()
            Text(self.error).foregroundColor(.red).font(.callout)

            Divider()
            HStack {
                Button("Cancel", action: self.onCancel).font(.callout)
                Spacer()
                Spacer()
                Button("Add", action: self.onAdd).font(.callout)
                Button("Exercises", action: self.onExercises).font(.callout)
                Button("OK", action: self.onOK).font(.callout).disabled(!self.error.isEmpty)
            }
            .padding()
        }
        .actionSheet(isPresented: $showEditActions) {
            ActionSheet(title: Text(self.selection!.name), buttons: self.program.editButtons(self.$selection, self.$confirm))}
        .alert(item: self.$confirm) {confirm in
            Alert(
                title: Text(confirm.title),
                message: Text(confirm.message),
                primaryButton: .destructive(Text(confirm.button)) {confirm.callback()},
                secondaryButton: .default(Text("Cancel")))
        }
    }
    
    private func onAdd() {
        print("not implemented")
    }

    private func onExercises() {
        print("not implemented")
    }

    private func onEdited(_ text: String) {
        switch self.program.parse(self.name, self.currentWeek, self.restWeeks) {
        case .right(_):
            self.error = ""
        case .left(let err):
            self.error = err
        }
    }

    private func onCancel() {
        if self.oldWorkouts != self.program.workouts {
            self.program.setWorkouts(self.oldWorkouts)
        }
        self.presentation.wrappedValue.dismiss()
    }

    private func onOK() {
        self.program.setName(self.name)

        switch self.program.parse(self.name, self.currentWeek, self.restWeeks) {
        case .right(let (week, rest)):
            self.program.setWeek(week)
            self.program.setRest(rest)
        case .left(_):
            break
        }

        self.presentation.wrappedValue.dismiss()
    }
}

struct EditProgramView_Previews: PreviewProvider {
    static let model = mockModel()
    static let program = ProgramVM(model)

    static var previews: some View {
        EditProgramView(program)
    }
}
