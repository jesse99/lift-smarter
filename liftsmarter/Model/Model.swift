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
    var program: Program                        // this is the active program (and is a reference to an object in programs)
    var bellsSet: [String: Bells] = [:]    
    var platesSet: [String: Plates] = [:]
    var history: History
    var userNotes: [String: String] = [:]       // this overrides defaultNotes
    var logs: Logs
    var programs: [Program]                     // saved programs (sorted by name)
    var dirty = false

    init(_ program: Program) {
        self.program = program
        self.programs = [program]
        self.history = History()
        self.logs = Logs()
        self.initPlates()
        self.validate()
    }

    required init(from store: Store) {
        if store.hasKey("active-program") {
            // We load all the programs into memory because they don't take much memory and so that we can validate them
            // as the code is updated (if we persisted them into separate stores it could be a really long time before
            // they were validated).
            self.programs = store.getObjArray("programs")
            let active = store.getStr("active-program")
            self.program = self.programs.first(where: {$0.name == active})!
        } else {
            self.program = store.getObj("program")
            self.programs = [self.program]
        }

        var names = store.getStrArray("fixedWeights-names")
        for (i, name) in names.enumerated() {
            self.bellsSet[name] = store.getObj("fixedWeights-\(i)")
        }

        self.history = store.getObj("history")

        names = store.getStrArray("userNotes-names")
        for (i, name) in names.enumerated() {
            self.userNotes[name] = store.getStr("userNotes-\(i)")
        }

        self.logs = store.getObj("logs")
        if store.hasKey("plates-names") {
            names = store.getStrArray("plates-names", ifMissing: [])
            for (i, name) in names.enumerated() {
                self.platesSet[name] = store.getObj("plates-\(i)")
            }
        } else {
            self.initPlates()
        }

        self.validate()
    }

    func save(_ store: Store) {
        store.addObjArray("programs", programs)
        store.addStr("active-program", program.name)

        var names = Array(self.bellsSet.keys)
        store.addStrArray("fixedWeights-names", names)
        for (i, name) in names.enumerated() {
            store.addObj("fixedWeights-\(i)", self.bellsSet[name]!)
        }

        names = Array(self.platesSet.keys)
        store.addStrArray("plates-names", names)
        for (i, name) in names.enumerated() {
            store.addObj("plates-\(i)", self.platesSet[name]!)
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
    
    // Plates are a lot less variable that dumbbells or cable machines so we'll go ahead and initialize them here.
    // Typically all that'll happen after is that users will remove a few plates and sometimes add micro-plates or magnets.
    func initPlates() {
        ASSERT(self.platesSet.isEmpty, "plates set should be empty")
        
        self.platesSet["Deadlift"] = defaultDeadPlates
        self.platesSet["Dual"] = defaultDualPlates
        self.platesSet["Single"] = defaultSinglePlates
    }
    
    func validate() {
        ASSERT(self.programs.contains(where: {self.program === $0}), "program should reference a program in programs")
        for program in self.programs {
            program.validate()
        }
        ASSERT(self.programs.isSorted({$0.name < $1.name}), "programs should be sorted (and unique)")

        var instances = Set<ObjectIdentifier>()
        for (_, bells) in self.bellsSet {
            let id = ObjectIdentifier(bells)
            ASSERT(!instances.contains(id), "bells's must be unique")
            instances.update(with: id)
        }

        instances = Set<ObjectIdentifier>()
        for (_, plates) in self.platesSet {
            let id = ObjectIdentifier(plates)
            ASSERT(!instances.contains(id), "plates must be unique")
            instances.update(with: id)
        }
    }
}
