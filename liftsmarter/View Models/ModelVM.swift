//  Created by Jesse Vorisek on 11/12/21.
import Foundation
import UIKit

class ModelVM: ObservableObject {
    private let model: Model

    init(_ model: Model) {
        self.model = model
    }
    
    var active: String {
        get {return self.model.program.name}
    }
    
    // Can't return programs because it's not legal to return Program and ProgramVM isn't possible because that's tied to model.program.

    func willChange() {
        self.model.dirty = true
        self.objectWillChange.send()
    }
}

// Mutators
extension ModelVM {
    func setActive(_ name: String) {
        self.willChange()
        self.model.program = self.model.programs.first(where: {$0.name == name})!
    }
    
    func add() {
        self.willChange()
        
        var name = "New"
        var count = 2
        while self.model.programs.first(where: {$0.name == name}) != nil {
            name = "New \(count)"
            count += 1
        }
        
        let program = Program(name, [], [], weeksStart: Date())
        self.model.programs.append(program)
        self.model.programs.sort(by: {$0.name < $1.name})
    }
    
    func delete(_ index: Int) {
        self.willChange()
        self.model.programs.remove(at: index)
    }

    func duplicate(_ index: Int) {
        self.willChange()

        var program = self.model.programs[index]
        var name = program.name
        var count = 2
        while self.model.programs.first(where: {$0.name == name}) != nil {
            name = "\(name) \(count)"
            count += 1
        }
        
        program = program.clone()
        program.name = name
        
        self.model.programs.append(program)
        self.model.programs.sort(by: {$0.name < $1.name})
    }
}

// UI
extension ModelVM {
    func entries() -> [ListEntry] {
        return self.model.programs.mapi({
            if $1 === self.model.program {
                return ListEntry($1.name, .blue, $0)
            } else {
                return ListEntry($1.name, .black, $0)
            }
        })
    }
}
