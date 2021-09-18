//  Created by Jesse Vorisek on 9/11/21.
import SwiftUI

struct ProgramView: View {
    let model: Model
    @ObservedObject var program: Program

    init(_ model: Model) {
        self.model = model
        self.program = model.program
    }
    
    var body: some View {
        NavigationView {
            VStack {
                List(self.program.workouts) {workout in
                    NavigationLink(destination: WorkoutView(WorkoutVM(self.model, workout))) {
                        VStack(alignment: .leading) {
                            Text(workout.name).font(.title)
//                            Text(entry.subLabel).foregroundColor(entry.subColor).font(.headline) // 10+ Reps or As Many Reps As Possible
                        }
                    }
                }
                .navigationBarTitle(Text(getTitle()))
//                .onAppear {self.timer.restart(); self.display.send(.TimePassed)}
//                .onDisappear {self.timer.stop()}
//                .onReceive(self.timer.timer) {_ in self.display.send(.TimePassed)}

                Divider()
                HStack {
                    // Would be nice to make this a tab but then switching programs completely hoses all
                    // existing views.
                    Button("Programs", action: onPrograms)
                        .font(.callout).labelStyle(/*@START_MENU_TOKEN@*/DefaultLabelStyle()/*@END_MENU_TOKEN@*/)
//                        .sheet(isPresented: self.$programsModal) {ProgramsView(self.display)}
                    Spacer()
                    Button("Edit", action: onEdit)
                        .font(.callout).labelStyle(/*@START_MENU_TOKEN@*/DefaultLabelStyle()/*@END_MENU_TOKEN@*/)
//                        .sheet(isPresented: self.$editModal) {EditProgramView(self.display)}
                }
                .padding()
            }
        }.navigationViewStyle(StackNavigationViewStyle())
        // TODO: have a text view saying how long this program has been run for
        // and also how many times the user has worked out
    }
    
    private func onEdit() {
//        self.editModal = true
    }
    
    private func onPrograms() {
//        self.programsModal = true
    }

    private func getTitle() -> String {
//        if let start = display.program.blockStart, let num = display.program.numWeeks() {
//            let todaysWeek = currentWeek(blockStart: start, currentDate: now(), numWeeks: num)
//            return "\(self.display.program.name) Workouts \(todaysWeek)"
//        } else {
            return "\(self.program.name) Workouts"
//        }
    }
}

struct ProgramView_Previews: PreviewProvider {
    static let model = mockModel()
    
    static var previews: some View {
        ProgramView(model)
    }
}
