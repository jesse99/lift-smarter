//  Created by Jesse Vorisek on 11/10/21.
import SwiftUI

/// Used to edit Plates arrays.
struct EditPlatesView: View {
    enum ActiveAlert {case deleteSelected, deleteAll}

    let program: ProgramVM
    let originalName: String
    let dual: Bool
    @State var name: String
    @State var plates: Plates
    @State var showEditActions = false
    @State var showAdd = false
    @State var showEdit = false
    @State var showAlert = false
    @State var alertAction: EditPlatesView.ActiveAlert = .deleteSelected
    @State var selection: ListEntry? = nil
    @State var edited = 0   // hack because Plates is a class now so @State doesn't work with it
    @State var error = ""
    @Environment(\.presentationMode) private var presentation

    init(_ program: ProgramVM, _ name: String, dual: Bool) {
        let std = Plates([
            Plate(weight: 45, count: dual ? 4: 2, type: .standard),
            Plate(weight: 35, count: dual ? 4: 2, type: .standard),
            Plate(weight: 25, count: dual ? 4: 2, type: .standard),
            Plate(weight: 10, count: dual ? 4: 2, type: .standard),
            Plate(weight: 5, count: dual ? 4: 2, type: .standard)
        ])

        self.program = program
        self.dual = dual
        self.originalName = name
        self._plates = State(initialValue: program.getPlatesSet()[name]?.clone() ?? std)
        self._name = State(initialValue: name)
    }
    
    var body: some View {
        VStack() {
            Text(self.dual ? "Dual Plates" : "Single Plates").font(.largeTitle)

            wordsField("Name", self.$name, self.onEditedName)
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
            .sheet(isPresented: self.$showEdit) {
                EditPlateView(self.plates[self.selection!.index], onEdited: self.doEdited)}
            Spacer()
            Text(self.error).foregroundColor(.red).font(.callout).id(self.edited)

            Divider()
            HStack {
                Button("Cancel", action: onCancel).font(.callout)
                Spacer()
                Spacer()
                Button("Add", action: onAdd)
                    .font(.callout)
                    .sheet(isPresented: self.$showAdd) {
                        EditTextView(title: "Weight", content: "", type: .decimalPad, validator: self.onValidWeight, sender: self.doAdded)}
                Button("OK", action: onOK).font(.callout).disabled(!self.error.isEmpty)
            }
            .padding()
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
                    message: Text("\(self.plates.count) weights"),
                    primaryButton: .destructive(Text("Delete")) {self.doDeleteAll()},
                    secondaryButton: .default(Text("Cancel")))
            }}
    }

    private func getEntries() -> [ListEntry] {
        var entries: [ListEntry] = []

        for i in 0..<self.plates.count {
            let plate = self.plates[i]

            var label = friendlyUnitsWeight(plate.weight, plural: false) + " "
            switch plate.type {
            case .standard: break
            case .bumper: label += "bumper "
            case .magnet: label += "magnet "
            }
            if plate.count > 1 {
                label += "x\(plate.count)"
            }
            entries.append(ListEntry(label, .black, i))
        }

        return entries
    }
    
    private func editButtons() -> [ActionSheet.Button] {
        var buttons: [ActionSheet.Button] = []

        buttons.append(.destructive(Text("Delete"), action: self.onDelete))
        buttons.append(.destructive(Text("Delete All"), action: self.onDeleteAll))
        buttons.append(.default(Text("Edit"), action: self.onEdit))
        buttons.append(.cancel(Text("Cancel"), action: {}))

        return buttons
    }
    
    private func onEditedName(_ text: String) {
        self.error = ""

        if text != self.originalName {
            if self.program.getBellsSet()[text] != nil {
                self.error = "Name already exists"
            }
        }
    }
    
    private func doEdited(_ plate: Plate) {
        self.plates.remove(at: self.selection!.index)
        self.plates.add(plate)
        self.edited += 1
    }

    // This is used by EditTextView, not this view.
    private func onValidWeight(_ text: String) -> String {
        if let newWeight = Double(text) {
            if newWeight <= 0.0 {
                return "Weight should be larger than zero (found \(text))"
            } else {
               return ""
            }
        } else {
            return "Expected a floating point number for weight (found '\(text)')"
        }
    }

    private func doAdded(_ text: String) {
        self.plates.add(Plate(weight: Double(text)!, count: self.dual ? 4 : 2, type: .standard))
        self.edited += 1
    }

    private func doDelete() {
        self.plates.remove(at: self.selection!.index)
    }
    
    private func doDeleteAll() {
        self.plates = Plates()
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
        if self.name != self.originalName {
            self.program.delPlates(self.originalName)
            self.program.setPlates(self.name, self.plates)
        } else if self.plates != program.getPlatesSet()[self.name] {
            self.program.setPlates(self.name, self.plates)
        }

        app.saveState()
        self.presentation.wrappedValue.dismiss()
    }
}

struct EditPlatesView_Previews: PreviewProvider {
    static let model = mockModel()
    static let program = ProgramVM(ModelVM(model), model)

    static var previews: some View {
        EditPlatesView(program, "Deadlift", dual: true)
    }
}
