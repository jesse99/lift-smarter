//  Created by Jesse Vorisek on 9/12/21.
import SwiftUI

struct DurationsView: View {
    @ObservedObject var program: ProgramVM
    let timer = RestartableTimer(every: TimeInterval.hours(RecentHours/2))
    @ObservedObject var instance: InstanceVM
    @State var editModal = false
    @State var noteModal = false
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
                        .sheet(isPresented: self.$implicitTimerModal, onDismiss: self.onNextCompleted) {instance.implicitTimer()}
                    Spacer().frame(height: 50)

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
                    .sheet(isPresented: self.$editModal) {EditExerciseView(self.instance)}
            }
            .padding()
            .onReceive(timer.timer) {_ in self.resetIfNeeded()}
            .onAppear {self.resetIfNeeded(); self.timer.restart()}
            .onDisappear() {self.timer.stop()}
        }
    }

    private func onNext() {
        if instance.finished {
            instance.resetCurrent()
            self.presentation.wrappedValue.dismiss()
        } else {
            self.implicitTimerModal = true
        }
    }
    
    func onNextCompleted() {
        instance.appendCurrent()
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
//        return getPreviouslabel(self.display, workout(), exercise())
        return "a note"
    }
}

struct DurationsView_Previews: PreviewProvider {
    static let model = mockModel()
    static let program = ProgramVM(model)
    static let workout = WorkoutVM(program, model.program.workouts[0])
    static let instance = workout.instances.first(where: {$0.name == "Sleeper Stretch"})!

    static var previews: some View {
        DurationsView(program, instance)
    }
}
