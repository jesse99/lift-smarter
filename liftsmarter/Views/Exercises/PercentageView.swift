//  Created by Jesse Vorisek on 11/13/21.
import SwiftUI

struct PercentageView: View {
    @ObservedObject var program: ProgramVM
//    let timer = RestartableTimer(every: TimeInterval.hours(RecentHours/2))
    @ObservedObject var instance: InstanceVM

    init(_ program: ProgramVM, _ instance: InstanceVM) {
        self.program = program
        self.instance = instance
    }

    var body: some View {
        Text("hello")
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
