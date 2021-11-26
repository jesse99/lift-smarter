//  Created by Jesse Vorisek on 11/26/21.
import SwiftUI

/// Used to edit the list of Plates. Also used to activate one of the sets.
struct EditPlatesSetView: View {
    let program: ProgramVM
    let apparatus: Binding<Apparatus>
    let dual: Bool
    let originalPlates: [String: Plates]
    let originalName: String?
    @State var platesName: String?
    @State var barWeight = ""
    @State var showEditActions: Bool = false
    @State var selection: ListEntry? = nil
    @State var addingSheet: Bool = false
    @State var editingSheet: Bool = false
    @State var confirmAlert: Bool = false
    @State var alertMesg: String = ""
    @State var error = ""
    @Environment(\.presentationMode) private var presentation

    init(_ program: ProgramVM, _ apparatus: Binding<Apparatus>) {
        self.program = program
        self.apparatus = apparatus
        
        var weights: [String: Plates] = [:]
        for (name, plates) in program.getPlatesSet() {
            weights[name] = plates.clone()
        }
        self.originalPlates = weights
        
        switch apparatus.wrappedValue {
        case .dualPlates(barWeight: let bar, let name):
            self.dual = true
            self.originalName = name
            self._platesName = State(initialValue: name)
            self._barWeight = State(initialValue: friendlyWeight(bar))
        case .singlePlates(let name):
            self.dual = false
            self.originalName = name
            self._platesName = State(initialValue: name)
        default:
            ASSERT(false, "should only be called for single or dual plates")
            self.dual = false
            self.originalName = nil
            self._platesName = State(initialValue: nil)
        }
    }
    
    var body: some View {
        VStack() {
            Text("Plates List").font(.largeTitle)

            if self.dual {
                weightField("Bar Weight", self.$barWeight, self.onEdited)
            }

            List(self.getEntries()) {entry in
                VStack() {
                    Text(entry.name).foregroundColor(entry.color).font(.headline)
                }
                .contentShape(Rectangle())  // so we can click within spacer
                    .onTapGesture {
                        self.selection = entry
                        self.showEditActions = true
                    }
            }
            .sheet(isPresented: self.$editingSheet) {
                EditPlatesView(self.program, self.selection!.name, dual: self.dual)
            }
            Text(self.error).foregroundColor(.red).font(.callout)

            Divider()
            HStack {
                Button("Cancel", action: onCancel).font(.callout)
                Spacer()
                Spacer()
                Button("Add", action: self.onAdd).font(.callout)
                    .sheet(isPresented: self.$addingSheet) {
                        EditTextView(title: "Name", content: "", caps: .words, validator: self.onValidName, sender: self.onAdded)
                    }
                Button("OK", action: onOK).font(.callout).disabled(!self.error.isEmpty)
            }
            .padding()
        }
        .actionSheet(isPresented: $showEditActions) {
            ActionSheet(title: Text(self.selection!.name), buttons: self.editButtons())}
        .alert(isPresented: $confirmAlert) {
            return Alert(
                title: Text("Confirm delete"),
                message: Text(self.alertMesg),
                primaryButton: .destructive(Text("Delete")) {self.doDelete()},
                secondaryButton: .default(Text("Cancel")))
            }
    }

    private func getEntries() -> [ListEntry] {
        let names = self.program.getPlatesSet().keys.sorted()
        return names.mapi({ListEntry($1, $1 == self.platesName ? .blue : .black, $0)})
    }

    private func editButtons() -> [ActionSheet.Button] {
        var buttons: [ActionSheet.Button] = []

        if self.platesName == self.selection!.name {
            buttons.append(.default(Text("Deactivate"), action: self.onDeactivate))
        } else {
            buttons.append(.default(Text("Activate"), action: self.onActivate))
        }
        buttons.append(.destructive(Text("Delete"), action: self.onDelete))
        buttons.append(.default(Text("Duplicate"), action: self.onDuplicate))
        buttons.append(.default(Text("Edit"), action: self.onEdit))
        buttons.append(.cancel(Text("Cancel"), action: {}))

        return buttons
    }

    private func onEdited(_ text: String) {
        self.error = ""
        
        if self.dual {
            if let weight = Double(self.barWeight) {
                if weight < 0.0 {
                    self.error = "Bar weight cannot be negative"
                }
            } else {
                self.error = "Bar weight should be a floating point number"
            }
        }
    }

    private func onActivate() {
        self.platesName = self.selection!.name
    }

    private func onDeactivate() {
        self.platesName = nil
    }

    private func onDelete() {
        func findUses(_ name: String) -> [String] {
            var uses: [String] = []

            for workout in self.program.workouts {
                for instance in workout.instances {
                    switch instance.exercise.apparatus {
                    case .dualPlates(barWeight: _, let iname):
                        if iname == name {
                            if uses.first(where: {$0 == instance.name}) == nil {
                                uses.append(instance.name)
                            }
                        }
                    case .singlePlates(let iname):
                        if iname == name {
                            if uses.first(where: {$0 == instance.name}) == nil {
                                uses.append(instance.name)
                            }
                        }
                    default:
                        break
                    }
                }
            }

            return uses.sorted()
        }

        self.confirmAlert = true

        let name = self.selection!.name
        let uses = findUses(name)
        if uses.count == 0 {
            self.alertMesg = "\(name) isn't being used"
        } else if uses.count == 1 {
            self.alertMesg = "\(name) is used by \(uses[0])"
        } else if uses.count == 2 {
            self.alertMesg = "\(name) is used by \(uses[0]) and \(uses[1])"
        } else if uses.count > 2 {
            self.alertMesg = "\(name) is used by \(uses[0]), \(uses[1]), ..."
        }
    }
    
    private func doDelete() {
        self.program.delPlates(self.selection!.name)
        if self.platesName == self.selection!.name {
            self.platesName = nil
        }
    }

    private func onDuplicate() {
        let name = self.selection!.name
        if let plates = self.program.getPlatesSet()[name] {
            var newName = name
            for i in 2... {
                newName = name + " \(i)"
                if self.program.getPlatesSet()[newName] == nil {
                    break
                }
            }
            self.program.setPlates(newName, plates.clone())
        }
    }

    private func onAdd() {
        self.addingSheet = true
    }

    private func onEdit() {
        self.editingSheet = true
    }

    private func onValidName(_ name: String) -> String {
        if name == self.originalName {
            return ""
        }
        
        if name.isBlankOrEmpty() {
            return "Need a name"
        }
        
        return self.program.getPlatesSet()[name] != nil ? "Name already exists" : ""
    }

    private func onAdded(_ name: String) {
        self.program.addPlates(name, dual: self.dual)
    }

    private func onCancel() {
        self.program.setPlates(self.originalPlates)
        self.presentation.wrappedValue.dismiss()
    }

    private func onOK() {
        if self.dual {
            self.apparatus.wrappedValue = .dualPlates(barWeight: Double(self.barWeight)!, self.platesName)
        } else {
            self.apparatus.wrappedValue = .singlePlates(self.platesName)
        }
        self.presentation.wrappedValue.dismiss()
    }
}

struct EditPlatesSetView_Previews: PreviewProvider {
    static let model = mockModel()
    static let program = ProgramVM(ModelVM(model), model)
    static let workout = model.program.workouts[0]
    static let exercise = model.program.exercises.first(where: {$0.name == "Deadlift"})!
    static var apparatus = Binding.constant(exercise.apparatus)

    static var previews: some View {
        EditPlatesSetView(program, apparatus)
    }
}
