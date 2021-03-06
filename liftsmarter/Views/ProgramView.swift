//  Created by Jesse Vorisek on 9/11/21.
import SwiftUI

struct ProgramView: View {
    let timer = RestartableTimer(every: TimeInterval.minutes(30)) // subLabel can change after a low number of hours so we'll force updates fairly often
    @ObservedObject var program: ProgramVM
    @State var editModal = false

    init(_ program: ProgramVM) {
        self.program = program
    }
    
    var body: some View {
        NavigationView {
            VStack {
                List(self.program.workouts) {workout in
                    if workout.enabled {
                        NavigationLink(destination: WorkoutView(self.program, workout)) {
                            VStack(alignment: .leading) {
                                Text(program.label(workout)).font(.title)
                                
                                let (sub, color) = program.subLabel(workout)
                                if !sub.isEmpty {
                                    Text(sub).foregroundColor(color).font(.headline)
                                }
                            }
                        }
                    }
                }
                .navigationBarTitle(Text("\(self.program.name) Workouts"))
                .onAppear {self.timer.restart(); self.program.willChange(); self.program.validate()}
                .onDisappear {self.timer.stop()}
                .onReceive(self.timer.timer) {_ in self.program.willChange()}

                Divider()
                HStack {
                    // Would be nice to make this a tab but then switching programs completely hoses all
                    // existing views. TODO: maybe that'll work better now?
                    Button("Programs", action: onPrograms)  // TODO: implement this
                        .font(.callout).disabled(true)
//                        .sheet(isPresented: self.$programsModal) {ProgramsView(self.display)}
                    Spacer()
                    Button("Edit", action: onEdit)
                        .font(.callout)
                        .sheet(isPresented: self.$editModal) {EditProgramView(self.program)}
                }
                .padding()
            }
        }.navigationViewStyle(StackNavigationViewStyle())
        // TODO: have a text view saying how long this program has been run for
        // and also how many times the user has worked out
    }
    
    private func onEdit() {
        self.editModal = true
    }
    
    private func onPrograms() {
//        self.programsModal = true
    }
}

struct ProgramView_Previews: PreviewProvider {
    static let model = mockModel()
    static let vm = ProgramVM(ModelVM(model), model)
    
    static var previews: some View {
        ProgramView(vm)
    }
}
