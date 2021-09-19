//  Created by Jesse Vorisek on 9/9/21.
import SwiftUI

@main
struct liftsmarterApp: App {
    var model: Model
    let program: ProgramVM
    let logs: LogsVM
    
    init() {
        self.model = mockModel()             // TODO: do something else here
        self.program = ProgramVM(model)
        self.logs = LogsVM(model)
    }

    var body: some Scene {
        WindowGroup {
            ContentView(program, logs)
        }
    }
}
