//  Created by Jesse Vorisek on 9/12/21.
import SwiftUI

struct WorkoutView: View {
    @ObservedObject var vm: WorkoutVM

    init(_ vm: WorkoutVM) {
        self.vm = vm
    }

    var body: some View {
        VStack {
            List(self.vm.workout.instances) {instance in
                if instance.enabled {
                    NavigationLink(destination: ExerciseView(self.vm, instance)) {
                        VStack(alignment: .leading) {
                            Text(instance.name).font(.headline) //.foregroundColor(entry.color)
                            let (label, color) = self.vm.label(instance)
                            if !label.isEmpty {
                                Text(label).font(.subheadline).foregroundColor(color)
                            }
                        }
                    }
                }
            }
            .navigationBarTitle(Text(self.vm.name + " Exercises"))

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
    static let vm = WorkoutVM(model, model.program.workouts[0])

    static var previews: some View {
        WorkoutView(vm)
    }
}
