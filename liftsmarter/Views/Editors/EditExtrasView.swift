//  Created by Jesse Vorisek on 11/7/21.
import SwiftUI

/// Used to edit the extra weights in a FixedWeightSet.
struct EditExtrasView: View {
    enum ActiveAlert {case deleteSelected, deleteAll}

    let program: ProgramVM
    let originalName: String
    @State var extraAdds: String
    @State var fws: FixedWeightSet
    @State var showEditActions = false
    @State var showAdd = false
    @State var showEdit = false
    @State var showAlert = false
    @State var alertAction: EditExtrasView.ActiveAlert = .deleteSelected
    @State var selection: ListEntry? = nil
    @State var edited = 0   // hack because FixedWeightSet is a class now so @State doesn't work with it
    @State var error = ""
    @Environment(\.presentationMode) private var presentation

    init(_ program: ProgramVM, _ name: String) {
        self.program = program
        self.originalName = name
        
        let fws = program.getFWS(name)?.clone() ?? FixedWeightSet([])
        self._fws = State(initialValue: fws)
        self._extraAdds = State(initialValue: fws.extraAdds.description)
    }
    
    var body: some View {
        VStack() {
            Text("Extra Fixed Weights").font(.largeTitle)

            intField("Max to use", self.$extraAdds, self.onEditedExtraAdds)
            Divider().background(Color.black)

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
            .sheet(isPresented: self.$showEdit) {EditTextView(title: "Weight", content: friendlyWeight(self.fws.extra[self.selection!.index]), validator: self.onValidWeight, sender: self.onEditedWeight)}
            Spacer()
            Text(self.error).foregroundColor(.red).font(.callout).id(self.edited)

            Divider()
            HStack {
                Button("Cancel", action: onCancel).font(.callout)
                Spacer()
                Spacer()
                Button("Add", action: onAdd)
                    .font(.callout)
                    .sheet(isPresented: self.$showAdd) {AddFixedWeightsView(self.program, self.originalName, self.$fws, extra: true, onEdit: self.onAddedWeight)}
                Button("OK", action: onOK).font(.callout).disabled(!self.error.isEmpty)
            }
            .padding()
            .onAppear(perform: self.onValidate)
        }
        .actionSheet(isPresented: $showEditActions) {
            ActionSheet(title: Text(self.selection!.name), buttons: editButtons())}
        .alert(isPresented: $showAlert) {   
            if self.alertAction == .deleteSelected {
                return Alert(
                    title: Text("Confirm delete"),
                    message: Text(self.selection!.name),
                    primaryButton: .destructive(Text("Delete")) {self.doDelete()},
                    secondaryButton: .default(Text("Cancel")))
            } else {
                return Alert(
                    title: Text("Confirm delete all"),
                    message: Text("\(self.fws.extra.count) weights"),
                    primaryButton: .destructive(Text("Delete")) {self.doDeleteAll()},
                    secondaryButton: .default(Text("Cancel")))
            }}
    }

    private func getEntries() -> [ListEntry] {
        return self.fws.extra.mapi {ListEntry(friendlyUnitsWeight($1), .black, $0)}
    }
    
    private func editButtons() -> [ActionSheet.Button] {
        var buttons: [ActionSheet.Button] = []

        buttons.append(.destructive(Text("Delete"), action: self.onDelete))
        buttons.append(.destructive(Text("Delete All"), action: self.onDeleteAll))
        buttons.append(.default(Text("Edit"), action: self.onEdit))
        buttons.append(.cancel(Text("Cancel"), action: {}))

        return buttons
    }
    
    private func onEditedExtraAdds(_ text: String) {
        self.onValidate()
    }
    
    private func onValidate() {
        if let count = Int(self.extraAdds) {
            if count <= self.fws.extra.count {
                self.fws.extraAdds = count
                self.error = ""
            } else {
                self.error = "Max to use can't be larger than the number of weights"
            }
        } else {
            self.error = "Max to use should be a number"
        }
    }
    
    private func onEditedWeight(_ text: String) {
        let newWeight = Double(text)!
        let originalWeight = self.fws.extra[self.selection!.index]
        if differentWeight(newWeight, originalWeight) {
            self.fws.extra.remove(at: self.selection!.index)
            self.fws.extra.add(newWeight)
            self.edited += 1
        }
    }

    // This is used by EditTextView, not this view.
    private func onValidWeight(_ text: String) -> String {
        if let newWeight = Double(text) {
            if newWeight < 0.0 {
                return "Weight cannot be negative (found \(text))"
            } else {
               return ""
            }
        } else {
            return "Expected a floating point number for weight (found '\(text)')"
        }
    }
    
    private func onAddedWeight() {
        self.edited += 1
        self.onValidate()
    }

    private func doDelete() {
        self.fws.extra.remove(at: self.selection!.index)
        self.onValidate()
    }
    
    private func doDeleteAll() {
        self.fws = FixedWeightSet([])
        self.onValidate()
    }
    
    private func onDelete() {
        self.showAlert = true
        self.alertAction = .deleteSelected
    }
    
    private func onDeleteAll() {
        self.showAlert = true
        self.alertAction = .deleteAll
    }
    
    private func onEdit() {
        self.showEdit = true
    }

    private func onAdd() {
        self.showAdd = true
    }

    private func onCancel() {
        self.presentation.wrappedValue.dismiss()
    }

    private func onOK() {
        if self.fws != program.getFWS(self.originalName) {
            self.program.setFWS(self.originalName, self.fws)
        }

        app.saveState()
        self.presentation.wrappedValue.dismiss()
    }
}

struct EditExtrasView_Previews: PreviewProvider {
    static let model = mockModel()
    static let program = ProgramVM(ModelVM(model), model)

    static var previews: some View {
        EditExtrasView(program, "Dumbbells")
    }
}
