//  Created by Jesse Vorisek on 10/5/21.
import SwiftUI

struct FixedRepsView: View {
    @ObservedObject var program: ProgramVM
    let timer = RestartableTimer(every: TimeInterval.hours(RecentHours/2))
    @ObservedObject var instance: InstanceVM
    @State var editModal = false
    @State var noteModal = false
    @State var rest = RestState(id: "", restSecs: 60, callback: nil)
    @State var recentModal = false
    @Environment(\.presentationMode) var presentation

    init(_ program: ProgramVM, _ instance: InstanceVM) {
        self.program = program
        self.instance = instance
        self._rest = State(initialValue: RestState(id: instance.id, restSecs: 60, callback: nil))
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
                    if case .exercising = self.rest.state {
                        Button(instance.nextLabel(), action: self.onNext)
                            .font(.system(size: 40.0))
                        Spacer().frame(height: 50)

                        Button("Start Timer", action: {self.rest.restart(.timing, self.instance.restDuration(implicit: false))})
                            .font(.system(size: 20.0))
                    } else {
                        Text(self.rest.label).font(.system(size: 40)).foregroundColor(self.rest.color)
                        Spacer().frame(height: 50)
                        if case .resting = self.rest.state {
                            Button("Stop Resting", action: {self.self.rest.stop()})
                                .font(.system(size: 20.0))
                                .onReceive(rest.timer.timer) {_ in self.rest.onTimer()}
                        } else {
                            Button("Stop Timer", action: {self.self.rest.stop()})
                                .font(.system(size: 20.0))
                                .onReceive(rest.timer.timer) {_ in self.rest.onTimer()}
                        }
                    }
                    Spacer()
                    Button(instance.notesLabel(), action: {self.recentModal = true})
                        .font(.callout)
                        .sheet(isPresented: self.$recentModal) {RecentView(self.program, self.instance.name)}
                }
            }

            Divider()
            HStack {
                Button("Reset", action: self.onReset)
                    .font(.callout)
                    .disabled(!self.instance.started || self.rest.timer.running)
                Spacer()
                Button("Note", action: self.onStartNote)
                    .font(.callout)
                    .disabled(self.rest.timer.running)
                    .sheet(isPresented: self.$noteModal) {NoteView(self.program, formalName: self.instance.formalName)}
                Button("Edit", action: self.onEdit)
                    .font(.callout)
                    .disabled(self.rest.timer.running)
                    .sheet(isPresented: self.$editModal, onDismiss: self.onEdited) {EditExerciseView(self.program, self.instance)}
            }
            .padding()
            .onReceive(timer.timer) {_ in self.resetIfNeeded()}
            .onAppear {self.onAppear()}
            .onDisappear() {self.timer.stop()}
        }
    }
    
    private func onAppear() {
        self.instance.workout.updateStarted(self.instance, Date())
        self.resetIfNeeded()
        self.timer.restart()
        self.rest.restore()
    }

    private func onNext() {
        if instance.finished {
            instance.resetCurrent()
            app.saveState()
            self.presentation.wrappedValue.dismiss()
        } else {
            let restSecs = self.instance.restDuration(implicit: true)
            if restSecs > 0 {
                self.rest.restart(.resting, restSecs)
            }
            instance.appendCurrent()
        }
    }
    
    private func onReset() {
        self.instance.resetCurrent()
    }
    
    private func onEdit() {
        self.editModal = true
    }
    
    private func onEdited() {
        if self.instance.exercise.info.caseIndex() != 1 {
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

struct FixedRepsView_Previews: PreviewProvider {
    static let model = mockModel()
    static let program = ProgramVM(ModelVM(model), model)
    static let workout = WorkoutVM(program, model.program.workouts[1])
    static let instance = workout.instances.first(where: {$0.name == "Foam Rolling"})!

    static var previews: some View {
        FixedRepsView(program, instance)
    }
}
