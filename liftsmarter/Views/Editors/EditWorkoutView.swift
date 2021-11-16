//  Created by Jesse Vorisek on 9/19/21.
import SwiftUI

struct EditWorkoutView: View {
    @ObservedObject var workout: WorkoutVM
    @State var name: String
    @State var oldExercises: [InstanceVM]
    @State var selection: InstanceVM? = nil
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

    @State var nextCyclic: Date
    @State var hasDatePicker: Bool

    init(_ workout: WorkoutVM) {
        self.workout = workout
        self._name = State(initialValue: workout.name)
        self._oldExercises = State(initialValue: workout.instances)

        let tuple = workout.render()
        self._schedule = State(initialValue: tuple.schedule)
        self._scheduleText = State(initialValue: tuple.text)
        self._scheduleLabel = State(initialValue: tuple.label)

        self._subSchedule = State(initialValue: tuple.subSchedule)
        self._subScheduleText = State(initialValue: tuple.subText)
        self._subScheduleLabel = State(initialValue: tuple.subLabel)

        if let date = tuple.nextCyclic {
            self._nextCyclic = State(initialValue: date)
            self._hasDatePicker = State(initialValue: true)
        } else {
            self._nextCyclic = State(initialValue: Date.distantFuture)
            self._hasDatePicker = State(initialValue: false)
        }
    }
    
    var body: some View {
        VStack() {
            Text("Edit Workout").font(.largeTitle)

            VStack(alignment: .leading) {
                wordsField("Name", self.$name, self.onEdited)

                HStack {
                    self.workout.scheduleButton(self.$schedule, self.$scheduleText, self.$scheduleLabel, self.$subSchedule, self.$subScheduleText, self.$subScheduleLabel, self.$nextCyclic, self.$hasDatePicker)
                    if self.workout.hasScheduleText(self.schedule) {
                        TextField("", text: self.$scheduleText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.default)
                            .autocapitalization(.words)
                            .disableAutocorrection(true)
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
                
                if self.hasDatePicker {
                    // Not scheduled will be mapped to yesterday (makes the picker a lot nicer to use).
                    let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
                    DatePicker(selection: $nextCyclic, in: yesterday..., displayedComponents: .date) {
                        Text("Next on").font(.headline)
                    }.padding(.leading).padding(.trailing)
                }

                List(self.workout.instances) {exercise in
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
        if self.oldExercises != self.workout.instances {
            self.workout.setInstances(self.oldExercises)
        }
        self.presentation.wrappedValue.dismiss()
    }

    private func onOK() {
        switch self.workout.parse(self.name, self.schedule, self.scheduleText, self.subSchedule, self.subScheduleText) {
        case .right(let schedule):
            self.workout.setName(self.name)
            self.workout.setSchedule(schedule)
            
            if self.hasDatePicker {
                if self.nextCyclic != self.workout.nextCyclic() {
                    self.workout.setNextCyclic(self.nextCyclic)
                }
            }
        case .left(let err):
            ASSERT(false, "validate should have prevented this from executing: \(err)")
        }

        app.saveState()
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
    static let program = ProgramVM(ModelVM(model), model)
    static let workout = model.program.workouts[0]

    static var previews: some View {
        EditWorkoutView(WorkoutVM(program, workout))
    }
}
