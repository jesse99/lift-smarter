//  Created by Jesse Vorisek on 9/9/21.
import Combine
import Foundation

/// Encapsulates all the state associated with the application. This layer has just data and simple accessors; actual logic
/// belongs in the logic layer.
class Model {
    // State management is a bit of a pain with SwiftUI. It's normally best if state is all structs so that
    // ObservableObject's auto-update as their fields change. But life is way easier to handle mutation for
    // shared objects with classes. So that's what we do with the caveat that when we mutate objects embedded
    // within arrays we need to explicitly call objectWillChange.send to inform views that the state changed
    // (this is the "nested ObservableObject" problem).
    var program: Program
    var fixedWeights: [String: FixedWeightSet] = [:]
    var history: History
    var userNotes: [String: String] = [:]    // this overrides defaultNotes
    var logs: Logs
    // TODO: add history, fixed weight sets, userNotes
    
    init(_ program: Program) {
        self.program = program
        self.history = History()
        self.logs = Logs()
    }    
}
