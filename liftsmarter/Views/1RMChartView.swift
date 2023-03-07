//  Created by Jesse Vorisek on 3/6/23.
import Charts
import SwiftUI

// Table is based on Baechle TR, Earle RW, Wathen D (2000). Essentials of Strength Training and Conditioning
// by way of https://exrx.net/Calculators/OneRepMax.
func get1RM(_ weight: Double, _ reps: Int) -> Double? {
    //  reps                    1   2   3   4   5   6   7   8   9  10  11  12  13  14  15
    let percents: [Double] = [100, 95, 93, 90, 87, 85, 83, 80, 77, 75, 72, 67, 66, 66, 65]
    if reps > 0 && reps - 1 < percents.count {
        let percent = percents[reps - 1]/100.0
        let max = weight*(2.0 - percent)
        return max.rounded(.toNearestOrEven)
    }
    return nil
}

struct OneRepMaxEntry: Identifiable {
    let weight: Double
    let size = 80.0        
    let date: Date
    let id = UUID()
}

/// Chart for completed exercises for rep based exercises showing estimated 1RM.
@available(iOS 16, *)
struct OneRepMaxChartView: View {  
    let program: ProgramVM
    let exerciseName: String
    @State var subLabel = ""
    @State var afterDate = Date.distantPast
    @State var entries: [OneRepMaxEntry] = []
    @State var yValues: [Double] = []
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
        
        self.entries = records.mapFilter({
            if let weight = self.find1RM($0) {
                return OneRepMaxEntry(weight: weight, date: $0.completed)
            } else {
                return nil
            }
        })
        self.yValues = self.entries.map({$0.weight}).unique()
    }
    
    private func find1RM(_ record: History.Record) -> Double? {
        if let set = record.sets.first {    // we'll use first set because the user may be fatigued on the later sets
            switch set {
            case .reps(count: let count, percent: let percent):
                return get1RM(percent*record.weight, count)
            case .duration(secs: _, percent: _):
                return nil
            }
        } else {
            return nil
        }
    }
}

@available(iOS 16, *)
struct OneRepMaxChartView_Previews: PreviewProvider {
    static let model = mockModel()
    static let program = ProgramVM(ModelVM(model), model)

    static var previews: some View {
//        OneRepMaxChartView(program, "Light Squat")
        OneRepMaxChartView(program, "Deadlift")
    }
}
