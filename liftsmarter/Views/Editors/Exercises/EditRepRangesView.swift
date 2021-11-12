//  Created by Jesse Vorisek on 10/27/21.
import SwiftUI

struct EditRepRangesView: View {
    let exerciseName: String
    let info: Binding<ExerciseInfo>
    @State var showHelp = false
    @State var helpText = ""
    @State var warmupModal = false
    @State var worksetModal = false
    @State var backoffModal = false
    @Environment(\.presentationMode) private var presentation

    init(_ exerciseName: String, _ info: Binding<ExerciseInfo>) {
        self.exerciseName = exerciseName
        self.info = info
    }
    
    var body: some View {
        VStack() {
            Text("Edit " + self.exerciseName).font(.largeTitle).padding()

            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Button("Warmups", action: {self.warmupModal = true}).font(.callout)
                    Spacer()
                    Button("?", action: {
                        self.helpText = "Optional sets to be done with a lighter weight."
                        self.showHelp = true
                    }).font(.callout).padding(.trailing)
                }.padding(.leading)
                Divider()
                HStack {
                    Button("Work Sets", action: {self.worksetModal = true}).font(.callout)
                    Spacer()
                    Button("?", action: {
                        self.helpText = "Sets to be done with 100% or so of the weight."
                        self.showHelp = true
                    }).font(.callout).padding(.trailing)
                }.padding(.leading)
                Divider()
                HStack {
                    Button("Backoff", action: {self.backoffModal = true}).font(.callout)
                    Spacer()
                    Button("?", action: {
                        self.helpText = "Optional sets to be done with a reduced weight."
                        self.showHelp = true
                    }).font(.callout).padding(.trailing)
                }.padding(.leading)
                    .sheet(isPresented: self.$warmupModal) {EditRepsSetView(self.exerciseName, self.info, .warmup)}
                    .sheet(isPresented: self.$worksetModal) {EditRepsSetView(self.exerciseName, self.info, .workset)}
                    .sheet(isPresented: self.$backoffModal) {EditRepsSetView(self.exerciseName, self.info, .backoff)}
            }
            Spacer()

            Divider()
            HStack {
                Button("Cancel", action: onCancel).font(.callout)
                Spacer()
                Spacer()
                Button("OK", action: onOK).font(.callout)
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
    
    private func onCancel() {
        self.presentation.wrappedValue.dismiss()
    }

    private func onOK() {
        app.saveState()
        self.presentation.wrappedValue.dismiss()
    }
}

struct EditRepRangesView_Previews: PreviewProvider {
    static let model = mockModel()
    static let program = ProgramVM(model)
    static let exercise = model.program.exercises.first(where: {$0.name == "Split Squat"})!
    static var info = Binding.constant(exercise.info)

    static var previews: some View {
        EditRepRangesView(exercise.name, info)
    }
}
