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
    @State var error = ""
    @Environment(\.presentationMode) private var presentation

    init(_ program: ProgramVM, _ name: String) {
        self.program = program
        self.originalName = name
        
        let fws = program.getFWS(name) ?? FixedWeightSet([])
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
            Text(self.error).foregroundColor(.red).font(.callout)

            Divider()
            HStack {
                Button("Cancel", action: onCancel).font(.callout)
                Spacer()
                Spacer()
                Button("Add", action: onAdd)
                    .font(.callout)
                    .sheet(isPresented: self.$showAdd) {AddFixedWeightsView(self.program, self.originalName, self.$fws, extra: true)}
                Button("OK", action: onOK).font(.callout).disabled(!self.error.isEmpty)
            }
            .padding()
        }
        .actionSheet(isPresented: $showEditActions) {
            ActionSheet(title: Text(self.selection!.name), buttons: editButtons())}
        .alert(isPresented: $showAlert) {   // and views can only have one alert
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
        self.error = ""

        if let count = Int(self.extraAdds) {
            self.fws.extraAdds = count
        } else {
            self.error = "Max to use should be a number"
        }
    }
    
    func onEditedWeight(_ text: String) {
        let newWeight = Double(text)!
        let originalWeight = self.fws.extra[self.selection!.index]
        if abs(newWeight - originalWeight) > 0.01 {
            self.fws.extra.remove(at: self.selection!.index)
            self.fws.extra.add(newWeight)
        }
    }

    // This is used by EditTextView, not this view.
    func onValidWeight(_ text: String) -> String {
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

    func doDelete() {
        self.fws.extra.remove(at: self.selection!.index)
    }
    
    func doDeleteAll() {
        self.fws = FixedWeightSet([])
    }
    
    func onDelete() {
        self.showAlert = true
        self.alertAction = .deleteSelected
    }
    
    func onDeleteAll() {
        self.showAlert = true
        self.alertAction = .deleteAll
    }
    
    func onEdit() {
        self.showEdit = true
    }

    func onAdd() {
        self.showAdd = true
    }

    func onCancel() {
        self.presentation.wrappedValue.dismiss()
    }

    func onOK() {
        if self.fws != program.getFWS(self.originalName) {
            self.program.setFWS(self.originalName, self.fws)
        }

        app.saveState()
        self.presentation.wrappedValue.dismiss()
    }
}

struct EditExtrasView_Previews: PreviewProvider {
    static let model = mockModel()
    static let program = ProgramVM(model)

    static var previews: some View {
        EditExtrasView(program, "Dumbbells")
    }
}
