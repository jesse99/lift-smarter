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
    let weight: Double
    let size: Double        // symvol scaling based on total reps
    let date: Date
    let id = UUID()
    
    init(_ record: History.Record, _ minCount: Int, _ maxCount: Int) {
        let count = record.sets.reduce(0, {$0 + actualToCount($1)})
        
        self.weight = record.weight
        self.date = record.completed
        if minCount < maxCount {
            self.size = 20 + 60*Double(count - minCount)/Double(maxCount - minCount)
        } else {
            self.size = 80.0
        }
    }
}

/// Chart for completed exercises for rep based exercises.
@available(iOS 16, *)
struct RepsChartView: View {    // TODO: probably should rename this
    let program: ProgramVM
    let exerciseName: String
    @State var subLabel = ""
    @State var afterDate = Date.distantPast
    @State var entries: [RepsEntry] = []
    @State var yValues: [Double] = []
    @State var maxCount: Int = 1
    @State var minCount: Int = 1
    @Environment(\.presentationMode) private var presentation

    init(_ program: ProgramVM, _ exerciseName: String) {
        self.program = program
        self.exerciseName = exerciseName
//        self.rebuild(afterDate: Date.distantPast)
    }

    var body: some View {
        VStack {
            Text(self.exerciseName).font(.largeTitle)
            Text(self.subLabel).font(.callout)
            Chart(self.entries) {
                PointMark(
                    x: .value("Date", $0.date),
                    y: .value("Weight", $0.weight)
                )
                .symbol(Circle().strokeBorder(lineWidth: 2.0))
                .symbolSize($0.size)
            }
            .chartYAxis{AxisMarks(values: self.yValues)}
            .chartYScale(domain: (self.yValues.min() ?? 0)...(self.yValues.max() ?? 100))
            .padding(.leading).padding(.trailing)

            Divider()
            HStack {
                Menu("Dates") {
                    Button("Cancel", action: {})
                    Button("All", action: {self.dontFilterDates()})
                    Button("Last year", action: {self.filterDates(12)})
                    Button("Last 6 months", action: {self.filterDates(6)})
                    Button("Last 3 months", action: {self.filterDates(3)})
                    Button("Last 2 months", action:   {self.filterDates(2)})
                    Button("Last month", action: {self.filterDates(1)})
                }.font(.callout).padding(.leading)
                Spacer()
                Button("OK", action: {self.presentation.wrappedValue.dismiss()}).font(.callout)
            }
            .padding()
        }
        .onAppear(perform: {self.rebuild()})
    }
    
    private func dontFilterDates() {
        self.subLabel = ""
        self.afterDate = Date.distantPast
        self.rebuild()
    }
    
    private func filterDates(_ months: Int) {
        if months == 12 {
            self.subLabel = "last year"
        } else if months == 1 {
                self.subLabel = "last month"
        } else {
            self.subLabel = "last \(months) months"
        }
        self.afterDate = Calendar.current.date(byAdding: .month, value: -months, to: Date())!
        self.rebuild()
    }
    
    private func rebuild() {
        let records = self.program.history().records(self.exerciseName).filter({$0.completed.compare(self.afterDate) == .orderedDescending})
        let counts = records.map({$0.sets.reduce(0, {$0 + actualToCount($1)})})
        let maxCount = counts.reduce(Int.min, {max($0, $1)})
        let minCount = counts.reduce(Int.max, {min($0, $1)})
        
        self.entries = records.map({RepsEntry($0, minCount, maxCount)})
        self.yValues = records.map({$0.weight}).unique()
        self.maxCount = maxCount
        self.minCount = minCount
    }
}

@available(iOS 16, *)
struct RepsChartView_Previews: PreviewProvider {
    static let model = mockModel()
    static let program = ProgramVM(ModelVM(model), model)

    static var previews: some View {
//        RepsChartView(program, "Light Squat")
        RepsChartView(program, "Deadlift")
    }
}
