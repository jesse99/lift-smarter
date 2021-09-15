//  Created by Jesse Vorisek on 9/9/21.
import SwiftUI

@main
struct liftsmarterApp: App {
    var model = mockModel()             // TODO: do something else here

    var body: some Scene {
        WindowGroup {
            ContentView(model)
        }
    }
}
