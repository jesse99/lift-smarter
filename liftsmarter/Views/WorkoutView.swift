//  Created by Jesse Vorisek on 9/12/21.
import SwiftUI

struct WorkoutView: View {  // TODO: might want a timer here (if time advances enough can fall into a rest week)
    @ObservedObject var workout: WorkoutVM
    @State var editModal = false

    init(_ workout: WorkoutVM) {
        self.workout = workout
    }

    var body: some View {
        VStack {
            List(self.workout.instances) {instance in
                if instance.enabled {
                    NavigationLink(destination: ExerciseView(instance)) {
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
            .navigationBarTitle(Text(self.workout.name + " Exercises"))
            .onAppear {self.workout.willChange()}   // something goofy going on with changes inside the sheet that prevents this view from updating unless we have this extra willChange call

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
    
    private func onEdit() {
        self.editModal = true
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
