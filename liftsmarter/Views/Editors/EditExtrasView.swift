//  Created by Jesse Vorisek on 11/7/21.
import SwiftUI

/// Used to edit the extra weights in a Bells object.
struct EditExtrasView: View {
    enum ActiveAlert {case deleteSelected, deleteAll}

    let program: ProgramVM
    let originalName: String
    @State var extraAdds: String
    @State var bells: Bells
    @State var showEditActions = false
    @State var showAdd = false
    @State var showEdit = false
    @State var showAlert = false
    @State var alertAction: EditExtrasView.ActiveAlert = .deleteSelected
    @State var selection: ListEntry? = nil
    @State var edited = 0   // hack because Bells is a class now so @State doesn't work with it
    @State var error = ""
    @Environment(\.presentationMode) private var presentation

    init(_ program: ProgramVM, _ name: String) {
        self.program = program
        self.originalName = name
        
        let bells = program.getBells(name)?.clone() ?? Bells([])
        self._bells = State(initialValue: bells)
        self._extraAdds = State(initialValue: bells.extraAdds.description)
    }
    
    var body: some View {
        VStack() {
            Text("Extra Weights").font(.largeTitle)

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
            .sheet(isPresented: self.$showEdit) {EditTextView(title: "Weight", content: friendlyWeight(self.bells.extra[self.selection!.index]), validator: self.onValidWeight, sender: self.onEditedWeight)}
            Spacer()
            Text(self.error).foregroundColor(.red).font(.callout).id(self.edited)

            Divider()
            HStack {
                Button("Cancel", action: onCancel).font(.callout)
                Spacer()
                Spacer()
                Button("Add", action: onAdd)
                    .font(.callout)
                    .sheet(isPresented: self.$showAdd) {AddBellRangeView(self.program, self.originalName, self.$bells, extra: true, onEdit: self.onAddedWeight)}
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
                    message: Text("\(self.bells.extra.count) weights"),
                    primaryButton: .destructive(Text("Delete")) {self.doDeleteAll()},
                    secondaryButton: .default(Text("Cancel")))
            }}
    }

    private func getEntries() -> [ListEntry] {
        return self.bells.extra.mapi {ListEntry(friendlyUnitsWeight($1), .black, $0)}
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
            if count <= self.bells.extra.count {
                self.bells.extraAdds = count
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
        let originalWeight = self.bells.extra[self.selection!.index]
        if differentWeight(newWeight, originalWeight) {
            self.bells.extra.remove(at: self.selection!.index)
            self.bells.extra.add(newWeight)
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
        self.bells.extra.remove(at: self.selection!.index)
        self.onValidate()
    }
    
    private func doDeleteAll() {
        self.bells = Bells([])
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
        if self.bells != program.getBells(self.originalName) {
            self.program.setBells(self.originalName, self.bells)
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
