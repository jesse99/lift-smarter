//  Created by Jesse Vorisek on 10/27/21.
import SwiftUI

struct EditRepsSetView: View {
    let exerciseName: String
    let info: Binding<ExerciseInfo>
    let stage: RepRangeStage
    @State var reps: String
    @State var percents: String
    @State var rest: String
    @State var expected: String
    @State var showHelp = false
    @State var helpText = ""
    @State var error = ""
    @Environment(\.presentationMode) var presentation

    init(_ exerciseName: String, _ info: Binding<ExerciseInfo>, _ stage: RepRangeStage) {
        self.exerciseName = exerciseName
        self.info = info
        self.stage = stage
        
        let tuple = info.wrappedValue.render(stage)
        self._reps = State(initialValue: tuple.reps)
        self._percents = State(initialValue: tuple.percents)
        self._rest = State(initialValue: tuple.rest)
        self._expected = State(initialValue: tuple.expected)
    }
    
    var body: some View {
        VStack() {
            Text(self.getTitle()).font(.largeTitle)

            VStack(alignment: .leading) {
                numericishField("Reps", self.$reps, self.onEditedInfo)
                numericishField("Percents", self.$percents, self.onEditedInfo)
                numericishField("Rest", self.$rest, self.onEditedInfo)
                numericishField("Expected Reps", self.$expected, self.onEditedInfo)
            }
            Spacer()
            Text(self.error).foregroundColor(.red).font(.callout)

            Divider()
            HStack {
                Button("Cancel", action: onCancel).font(.callout)
                Spacer()
                Spacer()
                Button("OK", action: onOK).font(.callout).disabled(!self.error.isEmpty)
            }
            .padding()
        }
        .alert(isPresented: $showHelp) {
            return Alert(
                title: Text("Help"),
                message: Text(self.helpText),
                dismissButton: .default(Text("OK")))
        }
    }
    
    private func getTitle() -> String {
        switch self.stage {
        case .warmup: return "Edit \(self.exerciseName) Warmups"
        case .workset: return "Edit \(self.exerciseName) Worksets"
        case .backoff: return "Edit \(self.exerciseName) Backoffs"
        }
    }

    private func onCancel() {
        self.presentation.wrappedValue.dismiss()
    }

    private func onOK() {
        if case let .repRanges(rInfo) = self.info.wrappedValue {
            let warmupSets = rInfo.sets.filter({$0.stage == .warmup})
            let worksetSets = rInfo.sets.filter({$0.stage == .workset})
            let backoffSets = rInfo.sets.filter({$0.stage == .backoff})

            let warmupExp = rInfo.expectedReps.filter({$0.stage == .warmup})
            let worksetExp = rInfo.expectedReps.filter({$0.stage == .workset})
            let backoffExp = rInfo.expectedReps.filter({$0.stage == .backoff})
            
            switch self.stage {
            case .warmup:
                switch info.wrappedValue.parse(self.reps, self.percents, self.rest, self.expected, self.stage, emptyRepsOK: true) {
                case .right((let sets, let expected)):
                    let newInfo = RepRangesInfo(sets: sets + worksetSets + backoffSets)
                    newInfo.expectedReps = expected + worksetExp + backoffExp
                    info.wrappedValue = .repRanges(newInfo)
                case .left(_):
                    ASSERT(false, "validate should have prevented this from executing")
                }
                
            case .workset:
                switch info.wrappedValue.parse(self.reps, self.percents, self.rest, self.expected, self.stage, emptyRepsOK: false) {
                case .right((let sets, let expected)):
                    let newInfo = RepRangesInfo(sets: warmupSets + sets + backoffSets)
                    newInfo.expectedReps = warmupExp + expected + backoffExp
                    info.wrappedValue = .repRanges(newInfo)
                case .left(_):
                    ASSERT(false, "validate should have prevented this from executing")
                }
                
            case .backoff:
                switch info.wrappedValue.parse(self.reps, self.percents, self.rest, self.expected, self.stage, emptyRepsOK: true) {
                case .right((let sets, let expected)):
                    let newInfo = RepRangesInfo(sets: warmupSets + worksetSets + sets)
                    newInfo.expectedReps = warmupExp + worksetExp + expected
                    info.wrappedValue = .repRanges(newInfo)
                case .left(_):
                    ASSERT(false, "validate should have prevented this from executing")
                }
            }
        } else {
            ASSERT(false, "expected repRanges")
        }

        self.presentation.wrappedValue.dismiss()
    }

    private func onEditedInfo(_ text: String) {
        switch info.wrappedValue.parse(self.reps, self.percents, self.rest, self.expected, self.stage, emptyRepsOK: true) {
        case .right(_):
            self.error = ""
        case .left(let err):
            self.error = err
        }
    }
}

struct EditRepsSetView_Previews: PreviewProvider {
    static let model = mockModel()
    static let program = ProgramVM(model)
    static let exercise = model.program.exercises.first(where: {$0.name == "Split Squat"})!
    static var info = Binding.constant(exercise.info)

    static var previews: some View {
        EditRepsSetView(exercise.name, info, .workset)
    }
}
