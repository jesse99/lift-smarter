//  Created by Jesse Vorisek on 9/12/21.
import SwiftUI

struct DurationsView: View {
    let model: Model
    @ObservedObject var exercise: Exercise
    @ObservedObject var instance: ExerciseInstance
    @State var underway: Bool
    @State var editModal = false
    @State var explicitTimerModal = false
    @Environment(\.presentationMode) var presentation

    init(_ model: Model, _ workout: Workout, _ instance: ExerciseInstance) {
        self.model = model
        self.exercise = model.program.exercises.first(where: {$0.name == instance.name})!
        self.instance = instance
        self._underway = State(initialValue: instance.current.setIndex > 0)
    }
    
    var body: some View {
        VStack {
            Group {     // we're using groups to work around the 10 item limit in VStacks
                Text(exercise.name).font(.largeTitle)   // Burpees
                Spacer()
            
                Text(getTitle(self.exercise, self.instance)).font(.title)          // Set 1 of 1
                Text(getSubTitle(self.exercise, self.instance)).font(.headline)    // 60s
                Text(getSubSubTitle(self.exercise, self.instance)).font(.headline) // 10 lbs
                Spacer()

                Group {
                    Button(self.getNextLabel(), action: onNext)
                        .font(.system(size: 40.0))
//                        .sheet(isPresented: self.$startModal, onDismiss: self.onNextCompleted) {TimerView(title: self.getTimerTitle(), duration: self.startDuration(), secondDuration: self.restSecs())}
                    Spacer().frame(height: 50)

                    Button("Start Timer", action: onStartTimer)
                        .font(.system(size: 20.0))
                        .sheet(isPresented: self.$explicitTimerModal) {TimerView(title: getExplicitTimerTitle(self.exercise, self.instance), duration: explicitTimerDuration(self.exercise, self.instance))}
                    Spacer()
                    Text(self.getNoteLabel()).font(.callout)   // Same previous x3
                }
            }

            Divider()
            HStack {
                Button("Reset", action: {self.onReset()}).font(.callout).disabled(!self.underway)
                Button("History", action: onStartHistory)
                    .font(.callout)
//                    .sheet(isPresented: self.$historyModal) {HistoryView(self.display, self.workoutIndex, self.exerciseID)}
                Spacer()
                Button("Note", action: onStartNote)
                    .font(.callout)
//                    .sheet(isPresented: self.$noteModal) {NoteView(self.display, formalName: self.exercise().formalName)}
                Button("Edit", action: onEdit)
                    .font(.callout)
                    .sheet(isPresented: self.$editModal) {EditDurationsView(self.model,  self.exercise)}
            }
            .padding()
//            .onReceive(timer.timer) {_ in self.onTimer()} // TODO: implement
            .onAppear {self.resetIfNeeded() /*self.timer.restart()*/}
//            .onDisappear() {self.timer.stop()}
        }
    }

    private func onNext() {
        let durations = self.durations()
        if instance.current.setIndex < durations.count {
//            self.startModal = true
        } else {
            self.presentation.wrappedValue.dismiss()
//            self.display.send(.AppendHistory(self.workout(), self.exercise()))
//            self.display.send(.ResetCurrent(self.exercise()))
        }
    }
    
    func onReset() {
//        self.display.send(.ResetCurrent(self.exercise()))
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
//        self.noteModal = true
    }
    
    private func resetIfNeeded() {   // TODO: use shouldReset
        instance.current = Current(weight: exercise.expected.weight)
    }

    private func getNextLabel() -> String {
        let durations = self.durations()
        if (instance.current.setIndex == durations.count) {
            return "Done"
        } else {
            return "Start"
        }
    }
    
    private func getNoteLabel() -> String {
//        return getPreviouslabel(self.display, workout(), exercise())
        return "a note"
    }

    private func durations() -> [DurationSet] {
        switch exercise.modality.sets {
        case .durations(let d, targetSecs: _):
            return d
        default:
            ASSERT(false, "exercise is not durations")
            return []
        }
    }
}

struct DurationsView_Previews: PreviewProvider {
    static let model = mockModel()
    static let workout = model.program.workouts[0]
    static let instance = workout.instances.first(where: {$0.name == "Sleeper Stretch"})!

    static var previews: some View {
        DurationsView(model, workout, instance)
    }
}
