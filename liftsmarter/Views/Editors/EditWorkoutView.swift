//  Created by Jesse Vorisek on 9/19/21.
import SwiftUI

struct EditWorkoutView: View {
    let workout: WorkoutVM
    @State var name: String
    @State var clipboard: [String] = []
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
//                    .contentShape(Rectangle())  // so we can click within spacer
//                        .onTapGesture {
//                            self.selection = exercise
//                            self.showEditActions = true
//                        }
                }
            }
            Spacer()
            Text(self.error).foregroundColor(.red).font(.callout)

            Divider()
            HStack {
                Button("Cancel", action: onCancel).font(.callout)
                Spacer()
                Spacer()
                Button("Paste", action: self.onPaste).font(.callout).disabled(self.clipboard.isEmpty)
                Button("Add", action: self.onAdd).font(.callout)
                Button("OK", action: onOK).font(.callout).disabled(!self.error.isEmpty)
            }
            .padding()
        }
    }
    
    private func onAdd() {
//        self.showSheet = true
    }

    private func onPaste() {
//        self.display.send(.PasteExercise(self.workout))
    }

    private func onCancel() {
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
