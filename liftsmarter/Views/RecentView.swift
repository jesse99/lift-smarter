//  Created by Jesse Vorisek on 11/11/21.
import SwiftUI

/// Recently completed workouts for an exercise.
struct RecentView: View {       // TODO: should turn this into a HistoryView (no limit and editing at least the latest)
    let program: ProgramVM
    let exerciseName: String
    @State var chartModal = false
    @Environment(\.presentationMode) private var presentation

    init(_ program: ProgramVM, _ exerciseName: String) {
        self.program = program
        self.exerciseName = exerciseName
    }

    var body: some View {
        VStack {
            Text("Recently Completed").font(.largeTitle) 

            List(self.program.recentlyCompleted(self.exerciseName)) {entry in
                HStack {
                    Text(entry.lhs).font(.subheadline)
                    Spacer()
                    Text(entry.rhs).font(.subheadline)
                }
            }

            Divider()
            HStack {
                if #available(iOS 16, *) {
                    // TODO: need at least one completion
                    Button("Chart", action: {self.chartModal = true})
                        .font(.callout)
                        .sheet(isPresented: self.$chartModal) {RepsChartView(self.program, self.exerciseName)}
                } else {
                    Button("Chart", action: {})
                        .font(.callout)
                        .disabled(true)
                }
            
                Spacer()
                Button("OK", action: {self.presentation.wrappedValue.dismiss()}).font(.callout)
            }
            .padding()
        }
    }
}

struct RecentView_Previews: PreviewProvider {
    static let model = mockModel()
    static let program = ProgramVM(ModelVM(model), model)

    static var previews: some View {
        RecentView(program, "Curls")
    }
}
