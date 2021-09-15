//  Created by Jesse Vorisek on 9/9/21.
import Combine
import Foundation

/// Encapsulates all the state associated with the application. This layer has just data and simple accessors; actual logic
/// belongs in the logic layer.
class Model {               // I think the nested data will be ObservableObject's instead of the model itself
    var program: Program
    var logs: Logs
    // TODO: add history, fixed weight sets, userNotes
    
    init(_ program: Program) {
        self.program = program
        self.logs = Logs()
    }
}
