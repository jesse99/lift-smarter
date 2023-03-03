//  Created by Jesse Vorisek on 9/12/21.
import SwiftUI

struct WorkoutView: View {
    let program: ProgramVM
    let timer = RestartableTimer(every: TimeInterval.minutes(30))
    @ObservedObject var workout: WorkoutVM
    @State var editModal = false

    init(_ program: ProgramVM, _ workout: WorkoutVM) {
        self.program = program
        self.workout = workout
        self.resetTimer()
    }

    var body: some View {
        VStack {
            List(self.workout.instances) {instance in
                if instance.enabled {
                    NavigationLink(destination: ExerciseView(program, instance)) {
                        VStack(alignment: .leading) {
                            let label = self.workout.label(instance)
                            let color = self.workout.color(instance)
                            Text(label).font(.headline).foregroundColor(color)

                            let sub = self.workout.subLabel(instance)
                            if !sub.isEmpty {
                                Text(sub).font(.subheadline).foregroundColor(color)
                            }
                        }
                    }
                }
            }
            Text(self.workout.duration()).font(.headline)
            .navigationBarTitle(Text("\(self.workout.name) Exercises"))
            .onAppear {self.onAppear()}
            .onReceive(timer.timer) {_ in self.onTimer()}

            Divider()
            HStack {
                Spacer()
                Button("Edit", action: onEdit)
                    .font(.callout)
                    .sheet(isPresented: self.$editModal) {EditWorkoutView(self.workout)}
            }
            .padding()
        }
    }
    
    private func onAppear() {
        // something goofy is going on with changes inside the sheet that prevents this view
        // from updating unless we have this extra willChange call
        self.workout.willChange()
        self.resetTimer()
        self.program.validate()     // TODO: get rid of this
    }
    
    private func onTimer() {
        self.workout.willChange()
        self.resetTimer()   // rest timer may finish
    }
    
    private func resetTimer() {
        var period: TimeInterval
        if self.workout.instances.any({restTime($0.id) != nil}) {
            // We'll update the subtitles for instances that are resting with the time.
            period = TimeInterval.seconds(1)
        } else {
            // Can enter a rest week.
            period = TimeInterval.minutes(30)
        }
        
        if self.timer.every != period {
            self.timer.restart(every: period)
        }
    }

    private func onEdit() {
        self.editModal = true
    }
}

struct WorkoutView_Previews: PreviewProvider {
    static let model = mockModel()
    static let program = ProgramVM(ModelVM(model), model)
    static let vm = WorkoutVM(program, model.program.workouts[0])

    static var previews: some View {
        WorkoutView(program, vm)
    }
}
