//  Created by Jesse Vorisek on 9/12/21.
import SwiftUI

struct ExerciseView: View {
    let model: Model
    let workout: Workout
    @ObservedObject var exercise: Exercise
    @ObservedObject var instance: ExerciseInstance

    init(_ model: Model, _ workout: Workout, _ instance: ExerciseInstance) {
        // TODO: we need to reset current if needed, in getView? or maybe in WorkoutView?
        self.model = model
        self.workout = workout
        self.exercise = model.program.exercises.first(where: {$0.name == instance.name})!
        self.instance = instance
    }

    var body: some View {
        getView()
    }

    private func getView() -> AnyView {
        switch exercise.modality.sets {
        case .durations(_, _):
            return AnyView(DurationsView(model, workout, instance))

        case .fixedReps(_):
            return AnyView(Text("not implemented"))
//            return AnyView(FixedRepsView(model, workout, instance))

        case .maxReps(_, _):
            return AnyView(Text("not implemented"))
//            return AnyView(MaxRepsView(model, workout, instance))

        case .repRanges(_, _, _):
            return AnyView(Text("not implemented"))
//            return AnyView(RepRangesView(model, workout, instance))

        case .repTotal(total: _, rest: _):
            return AnyView(Text("not implemented"))
//            return AnyView(RepTotalView(model, workout, instance))

//      case .untimed(restSecs: let secs):
//          sets = Array(repeating: "untimed", count: secs.count)
        }
    }
}

struct ExerciseView_Previews: PreviewProvider {
    static let model = mockModel()
    static let workout = model.program.workouts[0]
    static let instance = workout.instances.first(where: {$0.name == "Sleeper Stretch"})!

    static var previews: some View {
        ExerciseView(model, workout, instance)
    }
}
