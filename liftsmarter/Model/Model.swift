//  Created by Jesse Vorisek on 9/9/21.
import Combine
import Foundation

/// Encapsulates all the state associated with the application. This layer has just data and simple accessors; actual logic
/// belongs in the logic layer.
class Model: Storable {
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
    var dirty = false

    init(_ program: Program) {
        self.program = program
        self.history = History()
        self.logs = Logs()
        self.validate()
    }

    required init(from store: Store) {
        self.program = store.getObj("program")

        var names = store.getStrArray("fixedWeights-names")
        for (i, name) in names.enumerated() {
            self.fixedWeights[name] = store.getObj("fixedWeights-\(i)")
        }

        self.history = store.getObj("history")

        names = store.getStrArray("userNotes-names")
        for (i, name) in names.enumerated() {
            self.userNotes[name] = store.getStr("userNotes-\(i)")
        }

        self.logs = store.getObj("logs")
        self.validate()
    }

    func save(_ store: Store) {
        store.addObj("program", program)

        var names = Array(self.fixedWeights.keys)
        store.addStrArray("fixedWeights-names", names)
        for (i, name) in names.enumerated() {
            store.addObj("fixedWeights-\(i)", self.fixedWeights[name]!)
        }

        store.addObj("history", history)

        names = Array(self.userNotes.keys)
        store.addStrArray("userNotes-names", names)
        for (i, name) in names.enumerated() {
            store.addStr("userNotes-\(i)", self.userNotes[name]!)
        }

        store.addObj("logs", logs)
        dirty = false
    }
    
    func validate() {
        self.program.validate()

        var instances = Set<ObjectIdentifier>()
        for (_, fws) in self.fixedWeights {
            let id = ObjectIdentifier(fws)
            ASSERT(!instances.contains(id), "fws's must be unique")
            instances.update(with: id)
        }
    }
}
