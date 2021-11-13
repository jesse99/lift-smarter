//  Created by Jesse Vorisek on 9/9/21.
import SwiftUI

struct ContentView: View {
    @State private var selection = 0
    @ObservedObject var program: ProgramVM
    @ObservedObject var logs: LogsVM
    
    init(_ program: ProgramVM, _ logs: LogsVM) {
        self.program = program
        self.logs = logs
    }

    var body: some View {
        TabView(selection: $selection){
            ProgramView(self.program)
                .font(.title)
                .tabItem {
                    VStack {
                        Image(systemName: "figure.walk")    // these are from SF Symbols.app
                        Text("Workouts")
                    }
                }
                .tag(0)
            ProgramsView()
                .font(.title)
                .tabItem {
                    VStack {
                        Image(systemName: "menucard")
                        Text("Programs")
                    }
                }
                .tag(1)
            LogView(self.logs)
                .font(.title)
                .tabItem {
                    VStack {
                        // TODO: Would be great if this was color coded when not selected but that seems to require
                        // some work, see https://stackoverflow.com/questions/60803755/change-color-of-image-icon-in-tabitems-in-swiftui
                        Image(systemName: self.logs.tabImage())
                        Text("Logs")
                    }
                }
                .tag(2)
            Text("Settings")
                .font(.title)
                .tabItem {
                    VStack {
                        Image(systemName: "gearshape.fill")
                        Text("Settings")
                    }
                }
                .tag(3)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static let model = mockModel()
    static let program = ProgramVM(model)
    static let logs = LogsVM(model)
    
    static var previews: some View {
        ContentView(program, logs)
    }
}
