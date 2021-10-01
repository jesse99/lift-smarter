//  Created by Jesse Vorisek on 9/19/21.
import SwiftUI

struct EditWorkoutView: View {
    let workout: WorkoutVM
    @State var name: String
    @State var oldExercises: [ExerciseVM]
    @State var selection: ExerciseVM? = nil
    @State var clipboard: [String] = []
    @State var showEditActions = false
    @State var confirm: Confirmation? = nil
    @State var error = ""
    @Environment(\.presentationMode) private var presentation

    @State var schedule: Schedule
    @State var scheduleText: String
    @State var scheduleLabel: String

    @State var subSchedule: Schedule?
    @State var subScheduleText: String
    @State var subScheduleLabel: String

    init(_ workout: WorkoutVM) {
        self.workout = workout
        self._name = State(initialValue: workout.name)
        self._oldExercises = State(initialValue: workout.exercises)

        let tuple = workout.render()
        self._schedule = State(initialValue: tuple.0)
        self._scheduleText = State(initialValue: tuple.1)
        self._scheduleLabel = State(initialValue: tuple.2)

        self._subSchedule = State(initialValue: tuple.3)
        self._subScheduleText = State(initialValue: tuple.4)
        self._subScheduleLabel = State(initialValue: tuple.5)
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
                    self.workout.scheduleButton(self.$schedule, self.$scheduleText, self.$scheduleLabel, self.$subSchedule, self.$subScheduleText, self.$subScheduleLabel)
                    if self.workout.hasScheduleText(self.schedule) {
                        TextField("", text: self.$scheduleText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.default)
                            .autocapitalization(.words)
                            .disableAutocorrection(false)
                            .onChange(of: self.scheduleText, perform: self.onEdited)
                    }
                    if !self.scheduleLabel.isEmpty {
                        Text(self.scheduleLabel).font(.headline)
                    }
                }.padding(.leading).padding(.trailing)

                if self.subSchedule != nil {
                    HStack {
                        self.workout.subScheduleButton(self.$subSchedule, self.$subScheduleText, self.$subScheduleLabel)
                        if self.workout.hasScheduleText(self.subSchedule!) {
                            TextField("", text: self.$subScheduleText)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.default)
                                .autocapitalization(.words)
                                .disableAutocorrection(false)
                                .onChange(of: self.subScheduleText, perform: self.onEdited)
                        }
                        if !self.subScheduleLabel.isEmpty {
                            Text(self.subScheduleLabel).font(.headline)
                        }
                    }.padding(.leading).padding(.trailing)
                }

                List(self.workout.exercises) {exercise in
                    VStack() {
                        if exercise.enabled {
                            Text(exercise.name).font(.headline)
                        } else {
                            Text(exercise.name).font(.headline).strikethrough(color: .red)
                        }
                    }
                    .contentShape(Rectangle())  // so we can click within spacer
                        .onTapGesture {
                            self.selection = exercise
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
                Button("Paste", action: self.onPaste).font(.callout).disabled(!self.workout.canPaste())
                self.workout.addButton()
                Button("OK", action: self.onOK).font(.callout).disabled(!self.error.isEmpty)
            }
            .padding()
        }
        .actionSheet(isPresented: $showEditActions) {
            ActionSheet(title: Text(self.selection!.name), buttons: self.workout.editButtons(self.$selection, self.$confirm))}
        .alert(item: self.$confirm) {confirm in
            Alert(
                title: Text(confirm.title),
                message: Text(confirm.message),
                primaryButton: .destructive(Text(confirm.button)) {confirm.callback()},
                secondaryButton: .default(Text("Cancel")))
        }
    }
    
    private func onPaste() {
        self.workout.paste()
    }

    private func onCancel() {
        if self.oldExercises != self.workout.exercises {
            self.workout.setInstances(self.oldExercises)
        }
        self.presentation.wrappedValue.dismiss()
    }

    private func onOK() {
        self.workout.setName(self.name)
        switch self.workout.parse(self.name, self.schedule, self.scheduleText, self.subSchedule, self.subScheduleText) {
        case .right(let schedule):
            self.workout.setSchedule(schedule)
        case .left(_):
            ASSERT(false, "validate should have prevented this from executing")
        }

        self.presentation.wrappedValue.dismiss()
    }

    private func onEdited(_ text: String) {
        switch self.workout.parse(self.name, self.schedule, self.scheduleText, self.subSchedule, self.subScheduleText) {
        case .right(_):
            self.error = ""
        case .left(let err):
            self.error = err
        }
    }
}

struct EditWorkoutView_Previews: PreviewProvider {
    static let model = mockModel()
    static let program = ProgramVM(model)
    static let workout = model.program.workouts[0]

    static var previews: some View {
        EditWorkoutView(WorkoutVM(program, workout))
    }
}
