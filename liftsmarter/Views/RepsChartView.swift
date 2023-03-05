//  Created by Jesse Vorisek on 3/4/23.
import Charts
import SwiftUI

func actualToCount(_ set: ActualSet) -> Int {
    switch set {
    case .reps(count: let count, percent: _):
        return count
    case .duration(secs: let secs, percent: _):
        return secs
    }
}

struct RepsEntry: Identifiable {
    let count: Int          // total reps or total duration
    let minWeight: Double   // min and max are used with Barmark to show the rep ranges
    let maxWeight: Double
    let weight: Double
    let date: Date
    let id = UUID()
    
    init(_ record: History.Record) {
        self.count = record.sets.reduce(0, {$0 + actualToCount($1)})
        self.minWeight = record.weight
        self.maxWeight = record.weight
        self.weight = record.weight
        self.date = record.completed
    }

    init(_ record: History.Record, _ maxCount: Int) {
        self.count = record.sets.reduce(0, {$0 + actualToCount($1)})
        
        let delta = 6.0*Double(count)/Double(maxCount)
        self.minWeight = record.weight - delta
        self.maxWeight = record.weight + delta
        self.weight = record.weight
        self.date = record.completed
    }
}

/// Chart for completed exercises for rep based exercises.
@available(iOS 16, *)
struct RepsChartView: View {
    let program: ProgramVM
    let exerciseName: String
    let entries: [RepsEntry]
    let yValues: [Double]
    @Environment(\.presentationMode) private var presentation

    init(_ program: ProgramVM, _ exerciseName: String) {
        self.program = program
        self.exerciseName = exerciseName
        
        let records = self.program.history().records(self.exerciseName)
        let counts = records.map({$0.sets.reduce(0, {$0 + actualToCount($1)})})
        let maxCount = counts.reduce(Int.min, {max($0, $1)})
        let minCount = counts.reduce(Int.max, {min($0, $1)})
        if minCount < maxCount {
            self.entries = self.program.history().records(self.exerciseName).map({RepsEntry($0, maxCount)})
        } else {
            self.entries = self.program.history().records(self.exerciseName).map({RepsEntry($0)})
        }
        self.yValues = records.map({$0.weight}).unique()
    }

    var body: some View {
        VStack {
            Text(self.exerciseName).font(.largeTitle)
            Chart(self.entries) {
                BarMark(x: .value("Date", $0.date), yStart: .value("Weight", $0.minWeight), yEnd: .value("Weight", $0.maxWeight), width: 3)
                PointMark(
                    x: .value("Date", $0.date),
                    y: .value("Weight", $0.weight)
                )
            }
            .chartYAxis{AxisMarks(values: self.yValues)}
            .padding(.leading).padding(.trailing)

            Divider()
            HStack {
                Spacer()
                Button("OK", action: {self.presentation.wrappedValue.dismiss()}).font(.callout)
            }
            .padding()
        }
    }
}

@available(iOS 16, *)
struct RepsChartView_Previews: PreviewProvider {
    static let model = mockModel()
    static let program = ProgramVM(ModelVM(model), model)

    static var previews: some View {
        RepsChartView(program, "Light Squat")
//        RepsChartView(program, "Deadlift")
    }
}
