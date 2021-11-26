//  Created by Jesse Vorisek on 10/9/21.
import SwiftUI

/// Used to edit the list of Bells objects. Also used to activate one of the sets.
struct EditBellsSetView: View {
    let program: ProgramVM
    let apparatus: Binding<Apparatus>
    let originalWeights: [String: Bells]
    let originalName: String?
    @State var bellsName: String?
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
        
        var weights: [String: Bells] = [:]
        for (name, bells) in program.getBellsSet() {
            weights[name] = bells.clone()
        }
        self.originalWeights = weights

        if case .bells(let name) = apparatus.wrappedValue {
            self.originalName = name
            self._bellsName = State(initialValue: name)
        } else {
            ASSERT(false, "should only be called for bells")
            self.originalName = nil
            self._bellsName = State(initialValue: nil)
        }
    }
    
    var body: some View {
        VStack() {
            Text("Weights List").font(.largeTitle)

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
                EditBellsView(self.program, self.selection!.name)
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
        let names = self.program.getBellsSet().keys.sorted()
        return names.mapi({ListEntry($1, $1 == self.bellsName ? .blue : .black, $0)})
    }

    private func editButtons() -> [ActionSheet.Button] {
        var buttons: [ActionSheet.Button] = []

        if self.bellsName == self.selection!.name {
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
        self.bellsName = self.selection!.name
    }

    private func onDeactivate() {
        self.bellsName = nil
    }

    private func onDelete() {
        func findUses(_ name: String) -> [String] {
            var uses: [String] = []

            for workout in self.program.workouts {
                for instance in workout.instances {
                    if case .bells(let iname) = instance.exercise.apparatus, iname == name {
                        if uses.first(where: {$0 == instance.name}) == nil {
                            uses.append(instance.name)
                        }
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
        self.program.delBells(self.selection!.name)    
        if self.bellsName == self.selection!.name {
            self.bellsName = nil
        }
    }

    private func onDuplicate() {
        let name = self.selection!.name
        if let bells = self.program.getBellsSet()[name] {
            var newName = name
            for i in 2... {
                newName = name + " \(i)"
                if self.program.getBells(newName) == nil {
                    break
                }
            }
            self.program.setBells(newName, bells.clone())
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
        
        return self.program.getBells(name) != nil ? "Name already exists" : ""
    }

    private func onAdded(_ name: String) {
        self.program.addBells(name)
    }

    private func onCancel() {
        self.program.setBellsSet(self.originalWeights)
        self.presentation.wrappedValue.dismiss()
    }

    private func onOK() {
        self.apparatus.wrappedValue = .bells(name: self.bellsName)
        self.presentation.wrappedValue.dismiss()
    }
}

struct EditBellsSetView_Previews: PreviewProvider {
    static let model = mockModel()
    static let program = ProgramVM(ModelVM(model), model)
    static let workout = model.program.workouts[0]
    static let exercise = model.program.exercises.first(where: {$0.name == "Triceps Press"})!
    static var apparatus = Binding.constant(exercise.apparatus)

    static var previews: some View {
        EditBellsSetView(program, apparatus)
    }
}
