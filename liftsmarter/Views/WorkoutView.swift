//  Created by Jesse Vorisek on 9/12/21.
import SwiftUI

struct WorkoutView: View {
    @ObservedObject var workout: WorkoutVM

    init(_ workout: WorkoutVM) {
        self.workout = workout
    }

    var body: some View {
        VStack {
            List(self.workout.exercises) {exercise in
                if exercise.enabled {
                    NavigationLink(destination: ExerciseView(exercise)) {
                        VStack(alignment: .leading) {
                            let label = self.workout.label(exercise)
                            let color = self.workout.color(exercise)
                            Text(label).font(.headline).foregroundColor(color)

                            let sub = self.workout.subLabel(exercise)
                            if !sub.isEmpty {
                                Text(sub).font(.subheadline).foregroundColor(color)
                            }
                        }
                    }
                }
            }
            .navigationBarTitle(Text(self.workout.name + " Exercises"))

            Divider()
            HStack {
                Spacer()
                Button("Edit", action: onEdit)
                    .font(.callout)
//                    .sheet(isPresented: self.$editModal) {EditWorkoutView(self.display, self.workout())}
            }
            .padding()
        }
    }
    
    private func onEdit() {
//        self.editModal = true
    }
}

struct WorkoutView_Previews: PreviewProvider {
    static let model = mockModel()
    static let program = ProgramVM(model)
    static let vm = WorkoutVM(program, model.program.workouts[0])

    static var previews: some View {
        WorkoutView(vm)
    }
}
