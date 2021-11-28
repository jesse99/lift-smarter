//  Created by Jesse Vorisek on 11/13/21.
import SwiftUI

struct PercentageView: View {
    @ObservedObject var program: ProgramVM
    let timer = RestartableTimer(every: TimeInterval.hours(RecentHours/2))
    @ObservedObject var instance: InstanceVM
    @State var editModal = false
    @State var noteModal = false
    @State var implicitTimerModal = false
    @State var explicitTimerModal = false
    @State var recentModal = false
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
                    Button(instance.notesLabel(), action: {self.recentModal = true})
                        .font(.callout)
                        .sheet(isPresented: self.$recentModal) {RecentView(self.program, self.instance.name)}
                }
            }

            Divider()
            HStack {
                Button("Reset", action: {self.onReset()}).font(.callout).disabled(!self.instance.started)
                Spacer()
                Button("Note", action: onStartNote)
                    .font(.callout)
                    .sheet(isPresented: self.$noteModal) {NoteView(self.program, formalName: self.instance.formalName)}
                Button("Edit", action: onEdit)
                    .font(.callout)
                    .sheet(isPresented: self.$editModal, onDismiss: self.onEdited) {EditExerciseView(self.program, self.instance)}
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
            app.saveState()
            self.presentation.wrappedValue.dismiss()
        } else if self.instance.restDuration(implicit: true) > 0 {
            self.implicitTimerModal = true
        } else {
            self.onNextCompleted()
        }
    }
    
    private func onNextCompleted() {
        instance.appendCurrent()
    }
    
    private func onReset() {
        self.instance.resetCurrent()
    }
    
    private func onStartTimer() {
        self.explicitTimerModal = true
    }
    
    private func onEdit() {
        self.editModal = true
    }
    
    private func onEdited() {
        if self.instance.exercise.info.caseIndex() != 5 {
            self.presentation.wrappedValue.dismiss()
        }
    }

    private func onStartNote() {
        self.noteModal = true
    }
    
    private func resetIfNeeded() {
        if instance.shouldReset() {
            instance.resetCurrent()
        }
    }
}

struct PercentageView_Previews: PreviewProvider {
    static let model = mockModel()
    static let program = ProgramVM(ModelVM(model), model)
    static let workout = WorkoutVM(program, model.program.workouts[2])
    static let instance = workout.instances.first(where: {$0.name == "Light Squat"})!

    static var previews: some View {
        PercentageView(program, instance)
    }
}
