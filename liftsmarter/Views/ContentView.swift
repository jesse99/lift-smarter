//  Created by Jesse Vorisek on 9/9/21.
import SwiftUI

struct ContentView: View {
    let model: Model
    @State private var selection = 0
    @ObservedObject var logs: Logs
    
    init(_ model: Model) {
        self.model = model
        self.logs = model.logs
    }

    var body: some View {
        TabView(selection: $selection){
            ProgramView(self.model)
                .font(.title)
                .tabItem {
                    VStack {
                        Image(systemName: "figure.walk")
                        Text("Workouts")
                    }
                }
                .tag(0)
            LogView(model)
                .font(.title)
                .tabItem {
                    VStack {
                        // TODO: Would be great if this was color coded when not selected but that seems to require
                        // some work, see https://stackoverflow.com/questions/60803755/change-color-of-image-icon-in-tabitems-in-swiftui
                        Image(systemName: self.logsName())
                        Text("Logs")
                    }
                }
                .tag(1)
            Text("Settings")
                .font(.title)
                .tabItem {
                    VStack {
                        Image(systemName: "gearshape.fill")
                        Text("Settings")
                    }
                }
                .tag(2)
        }
    }
    
    private func logsName() -> String {
        if self.logs.numErrors > 0 {
            return "exclamationmark.triangle.fill"
        } else if self.logs.numWarnings > 0 {
            return "drop.triangle.fill"
        } else {
            return "text.bubble"
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static let model = mockModel()
    
    static var previews: some View {
        ContentView(model)
    }
}
