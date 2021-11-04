//  Created by Jesse Vorisek on 10/24/21.
import SwiftUI

struct RepRangesView: View {
    @ObservedObject var program: ProgramVM
    let timer = RestartableTimer(every: TimeInterval.hours(RecentHours/2))
    @ObservedObject var instance: InstanceVM
    @State var editModal = false
    @State var noteModal = false
    @State var updateRepsModal = false
    @State var updateExpectedAlert = false
    @State var advanceWeightAlert = false
    @State var implicitTimerModal = false
    @State var explicitTimerModal = false
    @Environment(\.presentationMode) var presentation

    init(_ program: ProgramVM, _ instance: InstanceVM) {
        self.program = program
        self.instance = instance
    }
    
    var body: some View {
        VStack {
            Group {     // we're using groups to work around the 10 item limit in VStacks
                Text(instance.name).font(.largeTitle)   // Burpees
                Spacer()
            
                Text(instance.title()).font(.title)          // Set 1 of 1
                Text(instance.subTitle()).font(.headline)    // 60s
                Text(instance.subSubTitle()).font(.headline) // 10 lbs
                Spacer()

                Group {
                    Button(instance.nextLabel(), action: onNext)
                        .font(.system(size: 40.0))
                        .sheet(isPresented: $updateRepsModal) {
                            let expected = self.instance.expectedReps()!
                            RepsPickerView(initial: expected, min: 1, dismissed: self.onRepsPressed)
                        }
                        .alert(isPresented: $updateExpectedAlert) { () -> Alert in
                            Alert(title: Text("Do you want to update expected reps?"),
                                primaryButton:   .default(Text("Yes"), action: self.onUpdateExpected),
                                secondaryButton: .default(Text("No"),  action: self.popView))}
                        .sheet(isPresented: self.$implicitTimerModal) {instance.implicitTimer(delta: -1)}
                    Spacer().frame(height: 50)
                        .alert(isPresented: $advanceWeightAlert) { () -> Alert in
                            Alert(title: Text("Do you want to advance the weight?"),
                                primaryButton: .default(Text("Yes"), action: self.doAdvanceWeight),
                                secondaryButton: .default(Text("No"), action: self.popView)
                            )}

                    Button("Start Timer", action: onStartTimer)
                        .font(.system(size: 20.0))
                        .sheet(isPresented: self.$explicitTimerModal) {instance.explicitTimer()}
                    Spacer()
                    Text(self.getNoteLabel()).font(.callout)   // Same previous x3
                }
            }

            Divider()
            HStack {
                Button("Reset", action: {self.onReset()}).font(.callout).disabled(!self.instance.started)
                Button("History", action: onStartHistory)
                    .font(.callout)
//                    .sheet(isPresented: self.$historyModal) {HistoryView(self.display, self.workoutIndex, self.exerciseID)}
                Spacer()
                Button("Note", action: onStartNote)
                    .font(.callout)
                    .sheet(isPresented: self.$noteModal) {NoteView(self.program, formalName: self.instance.formalName)}
                Button("Edit", action: onEdit)
                    .font(.callout)
                    .sheet(isPresented: self.$editModal) {EditExerciseView(self.program, self.instance)}
            }
            .padding()
            .onReceive(timer.timer) {_ in self.resetIfNeeded()}
            .onAppear {self.resetIfNeeded(); self.timer.restart()}
            .onDisappear() {self.timer.stop()}
        }
    }

    private func onNext() {
        switch self.instance.progress() {
        case .notStarted, .started:
            if let reps = self.instance.exercise.fixedRep() {
                self.onRepsPressed(reps)
            } else {
                self.updateRepsModal = true
            }
        case .finished:
            if self.instance.currentIsUnexpected() {
                self.updateExpectedAlert = true
                
            } else if self.instance.canAdvanceWeight() {
                self.advanceWeightAlert = true

            } else {
                self.popView()
            }
        }
    }
    
    private func popView() {
        instance.resetCurrent()
        app.saveState()
        self.presentation.wrappedValue.dismiss()
    }
    
    private func onRepsPressed(_ reps: Int) {
        self.implicitTimerModal = self.instance.restDuration() > 0
        self.instance.appendCurrent(reps)
    }
    
    private func onUpdateExpected() {
        if self.instance.canAdvanceWeight() {
            self.instance.updateExpected()
        } else {
            self.instance.updateExpected()
            self.popView()
        }
    }
    
    private func doAdvanceWeight() {
        self.instance.exercise.advanceWeight()
        self.popView()
    }

    func onReset() {
        self.instance.resetCurrent()
    }
    
    private func onStartTimer() {
        self.explicitTimerModal = true
    }
    
    private func onEdit() {
        self.editModal = true
    }

    private func onStartHistory() {
//        self.historyModal = true
    }
    
    private func onStartNote() {
        self.noteModal = true
    }
    
    private func resetIfNeeded() {
        if instance.shouldReset() {
            instance.resetCurrent()
        }
    }

    private func getNoteLabel() -> String {
//        return getPreviouslabel(self.display, workout(), instance())
        return "a note"
    }
}

struct RepRangesView_Previews: PreviewProvider {
    static let model = mockModel()
    static let program = ProgramVM(model)
    static let workout = WorkoutVM(program, model.program.workouts[2])
    static let instance = workout.instances.first(where: {$0.name == "Split Squat"})!

    static var previews: some View {
        RepRangesView(program, instance)
    }
}
