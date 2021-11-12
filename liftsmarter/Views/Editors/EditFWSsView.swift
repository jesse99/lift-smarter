//  Created by Jesse Vorisek on 10/9/21.
import SwiftUI

/// Used to edit the list of FixedWeightSet's. Also used to activate one of the sets.
struct EditFWSsView: View {
    let program: ProgramVM
    let apparatus: Binding<Apparatus>
    let originalWeights: [String: FixedWeightSet]
    let originalName: String?
    @State var fwsName: String?
    @State var showEditActions: Bool = false
    @State var selection: ListEntry? = nil
    @State var addingSheet: Bool = false
    @State var editingSheet: Bool = false
    @State var editingExtraSheet: Bool = false
    @State var confirmAlert: Bool = false
    @State var alertMesg: String = ""
    @State var error = ""
    @Environment(\.presentationMode) private var presentation

    init(_ program: ProgramVM, _ apparatus: Binding<Apparatus>) {
        self.program = program
        self.apparatus = apparatus
        
        var weights: [String: FixedWeightSet] = [:]
        for (name, fws) in program.getFixedWeights() {
            weights[name] = fws.clone()
        }
        self.originalWeights = weights

        if case .fixedWeights(let name) = apparatus.wrappedValue {
            self.originalName = name
            self._fwsName = State(initialValue: name)
        } else {
            ASSERT(false, "should only be called for fixedWeights")
            self.originalName = nil
            self._fwsName = State(initialValue: nil)
        }
    }
    
    var body: some View {
        VStack() {
            Text("Fixed Weight Sets").font(.largeTitle)

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
                EditFWSView(self.program, self.selection!.name)
            }
            .sheet(isPresented: self.$editingExtraSheet) {
                EditExtrasView(self.program, self.selection!.name)
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
            ActionSheet(title: Text(self.selection!.name), buttons: editButtons())}
        .alert(isPresented: $confirmAlert) {  
            return Alert(
                title: Text("Confirm delete"),
                message: Text(self.alertMesg),
                primaryButton: .destructive(Text("Delete")) {self.doDelete()},
                secondaryButton: .default(Text("Cancel")))
            }
    }

    private func getEntries() -> [ListEntry] {
        let names = self.program.getFixedWeights().keys.sorted()
        return names.mapi({ListEntry($1, $1 == self.fwsName ? .blue : .black, $0)})
    }

    private func editButtons() -> [ActionSheet.Button] {
        var buttons: [ActionSheet.Button] = []

        if self.fwsName == self.selection!.name {
            buttons.append(.default(Text("Deactivate"), action: self.onDeactivate))
        } else {
            buttons.append(.default(Text("Activate"), action: self.onActivate))
        }
        buttons.append(.destructive(Text("Delete"), action: self.onDelete))
        buttons.append(.default(Text("Duplicate"), action: self.onDuplicate))
        buttons.append(.default(Text("Edit"), action: self.onEdit))
        buttons.append(.default(Text("Edit Extras"), action: self.onEditExtra))
        buttons.append(.cancel(Text("Cancel"), action: {}))

        return buttons
    }

    private func onActivate() {
        print("activating with \(self.selection!.name)")
        self.fwsName = self.selection!.name
    }

    private func onDeactivate() {
        self.fwsName = nil
    }

    private func doDelete() {
        self.program.delFWS(self.selection!.name)    
        if self.fwsName == self.selection!.name {
            self.fwsName = nil
        }
    }

    private func onDelete() {
        func findUses(_ name: String) -> [String] {
            var uses: [String] = []

            for workout in self.program.workouts {
                for instance in workout.instances {
                    if case .fixedWeights(let iname) = instance.exercise.apparatus, iname == name {
                        uses.append(instance.name)
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
    
    private func onDuplicate() {
        let name = self.selection!.name
        if let fws = self.program.getFixedWeights()[name] {
            var newName = name
            for i in 2... {
                newName = name + " \(i)"
                if self.program.getFWS(newName) == nil {
                    break
                }
            }
            self.program.setFWS(newName, fws.clone())
        }
    }

    private func onAdd() {
        self.addingSheet = true
    }

    private func onEdit() {
        self.editingSheet = true
    }

    private func onEditExtra() {
        self.editingExtraSheet = true
    }

    private func onValidName(_ name: String) -> String {
        if name == self.originalName {
            return ""
        }
        
        if name.isBlankOrEmpty() {
            return "Need a name"
        }
        
        return self.program.getFWS(name) != nil ? "Name already exists" : ""
    }

    private func onAdded(_ name: String) {
        self.program.addFWS(name)
    }

    private func onCancel() {
        self.program.setFWS(self.originalWeights)
        self.presentation.wrappedValue.dismiss()
    }

    private func onOK() {
        self.apparatus.wrappedValue = .fixedWeights(name: self.fwsName)
        self.presentation.wrappedValue.dismiss()
    }
}

struct EditFWSsView_Previews: PreviewProvider {
    static let model = mockModel()
    static let program = ProgramVM(model)
    static let workout = model.program.workouts[0]
    static let exercise = model.program.exercises.first(where: {$0.name == "Triceps Press"})!
    static var apparatus = Binding.constant(exercise.apparatus)

    static var previews: some View {
        EditFWSsView(program, apparatus)
    }
}
