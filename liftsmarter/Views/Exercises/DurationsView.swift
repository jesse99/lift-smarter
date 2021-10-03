//  Created by Jesse Vorisek on 9/12/21.
import SwiftUI

struct DurationsView: View {
    let timer = RestartableTimer(every: TimeInterval.hours(RecentHours/2))
    @ObservedObject var exercise: InstanceVM
    @State var editModal = false
    @State var implicitTimerModal = false
    @State var explicitTimerModal = false
    @Environment(\.presentationMode) var presentation

    init(_ exercise: InstanceVM) {
        self.exercise = exercise
    }
    
    var body: some View {
        VStack {
            Group {     // we're using groups to work around the 10 item limit in VStacks
                Text(exercise.name).font(.largeTitle)   // Burpees
                Spacer()
            
                Text(exercise.title()).font(.title)          // Set 1 of 1
                Text(exercise.subTitle()).font(.headline)    // 60s
                Text(exercise.subSubTitle()).font(.headline) // 10 lbs
                Spacer()

                Group {
                    Button(exercise.nextLabel(), action: onNext)
                        .font(.system(size: 40.0))
                        .sheet(isPresented: self.$implicitTimerModal, onDismiss: self.onNextCompleted) {exercise.implicitTimer()}
                    Spacer().frame(height: 50)

                    Button("Start Timer", action: onStartTimer)
                        .font(.system(size: 20.0))
                        .sheet(isPresented: self.$explicitTimerModal) {exercise.explicitTimer()}
                    Spacer()
                    Text(self.getNoteLabel()).font(.callout)   // Same previous x3
                }
            }

            Divider()
            HStack {
                Button("Reset", action: {self.onReset()}).font(.callout).disabled(!self.exercise.inProgress())
                Button("History", action: onStartHistory)
                    .font(.callout)
//                    .sheet(isPresented: self.$historyModal) {HistoryView(self.display, self.workoutIndex, self.exerciseID)}
                Spacer()
                Button("Note", action: onStartNote)
                    .font(.callout)
//                    .sheet(isPresented: self.$noteModal) {NoteView(self.display, formalName: self.exercise().formalName)}
                Button("Edit", action: onEdit)
                    .font(.callout)
                    .sheet(isPresented: self.$editModal) {EditDurationsView(self.exercise)}
            }
            .padding()
            .onReceive(timer.timer) {_ in self.resetIfNeeded()}
            .onAppear {self.resetIfNeeded(); self.timer.restart()}
            .onDisappear() {self.timer.stop()}
        }
    }

    private func onNext() {
        if exercise.incomplete() {
            self.implicitTimerModal = true
        } else {
            exercise.reset()
//            self.display.send(.AppendHistory(self.workout(), self.exercise()))

            self.presentation.wrappedValue.dismiss()
        }
    }
    
    func onNextCompleted() {
        exercise.appendCurrent()
    }
    
    func onReset() {
        self.exercise.reset()
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
    
    private func resetIfNeeded() {
        if exercise.shouldReset() {
            exercise.reset()
        }
    }

    private func getNoteLabel() -> String {
//        return getPreviouslabel(self.display, workout(), exercise())
        return "a note"
    }
}

struct DurationsView_Previews: PreviewProvider {
    static let model = mockModel()
    static let program = ProgramVM(model)
    static let workout = model.program.workouts[0]
    static let exercise = model.program.exercises.first(where: {$0.name == "Sleeper Stretch"})!
    static let instance = workout.instances.first(where: {$0.name == "Sleeper Stretch"})!
    static let vm = InstanceVM(WorkoutVM(program, workout), exercise, instance)

    static var previews: some View {
        DurationsView(vm)
    }
}
