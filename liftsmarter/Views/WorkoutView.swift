//  Created by Jesse Vorisek on 9/12/21.
import SwiftUI

struct WorkoutView: View {
    let model: Model
    @ObservedObject var program: Program
    @ObservedObject var workout: Workout

    init(_ model: Model, _ workout: Workout) {
        // TODO: we need to reset current if needed, in getView? or maybe in WorkoutView?
        self.model = model
        self.program = model.program
        self.workout = workout
    }

    var body: some View {
        VStack {
            List(self.workout.instances) {instance in
                NavigationLink(destination: ExerciseView(self.model, self.workout, instance)) {
                    VStack(alignment: .leading) {
                        Text(instance.name).font(.headline) //.foregroundColor(entry.color)
                        let (label, color) = getLabel(model.program, instance)
                        if !label.isEmpty {
                            Text(label).font(.subheadline).foregroundColor(color)
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

    static var previews: some View {
        WorkoutView(model, model.program.workouts[0])
    }
}
