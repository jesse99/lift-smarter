//  Created by Jesse Vorisek on 10/9/21.
import SwiftUI

var listEntryID: Int = 0

struct ListEntry: Identifiable {
    let name: String
    let color: Color
    let id: Int     // can't use this as an index because ids should change when entries change
    let index: Int

    init(_ name: String, _ color: Color, _ index: Int) {
        self.name = name
        self.color = color
        self.id = listEntryID
        self.index = index
        
        listEntryID += 1
    }
}

struct PairedEntry: Identifiable {
    let lhs: String
    let rhs: String
    let id: Int  // can't use this as an index because ids should change when entries change
    let index: Int

    init(_ lhs: String, _ rhs: String, _ index: Int) {
        self.lhs = lhs
        self.rhs = rhs
        self.id = listEntryID
        self.index = index
        
        listEntryID += 1
    }
}

/// Used to edit a single Bells object.
struct EditBellsView: View {
    enum ActiveAlert {case deleteSelected, deleteAll}

    let program: ProgramVM
    let originalName: String
    @State var name: String
    @State var bells: Bells
    @State var showEditActions = false
    @State var showAdd = false
    @State var showEdit = false
    @State var showAlert = false
    @State var alertAction: EditBellsView.ActiveAlert = .deleteSelected
    @State var selection: ListEntry? = nil
    @State var edited = 0   // hack because Bells is a class now so @State doesn't work with it
    @State var error = ""
    @Environment(\.presentationMode) private var presentation

    init(_ program: ProgramVM, _ name: String) {
        self.program = program
        self.originalName = name
        self._bells = State(initialValue: program.getBells(name)?.clone() ?? Bells([]))
        self._name = State(initialValue: name)
    }
    
    var body: some View {
        VStack() {
            Text("Weights").font(.largeTitle)

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
            .sheet(isPresented: self.$showEdit) {EditTextView(title: "\(self.name) Weight", content: friendlyWeight(self.bells.weights[self.selection!.index]), validator: self.onValidWeight, sender: self.onEditedWeight)}
            Spacer()
            Text(self.error).foregroundColor(.red).font(.callout).id(self.edited)

            Divider()
            HStack {
                Button("Cancel", action: onCancel).font(.callout)
                Spacer()
                Spacer()
                Button("Add", action: onAdd)
                    .font(.callout)
                    .sheet(isPresented: self.$showAdd) {AddBellRangeView(self.program, self.originalName, self.$bells, extra: false, onEdit: self.onAddedWeight)}
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
                    message: Text("\(self.bells.weights.count) weights"),
                    primaryButton: .destructive(Text("Delete")) {self.doDeleteAll()},
                    secondaryButton: .default(Text("Cancel")))
            }}
    }

    private func getEntries() -> [ListEntry] {
        return self.bells.weights.mapi {ListEntry(friendlyUnitsWeight($1), .black, $0)}
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
            if self.program.getBells(text) != nil {
                self.error = "Name already exists"
            }
        }
    }
    
    private func onEditedWeight(_ text: String) {
        let newWeight = Double(text)!
        let originalWeight = self.bells.weights[self.selection!.index]
        if differentWeight(newWeight, originalWeight) {
            self.bells.weights.remove(at: self.selection!.index)
            self.bells.weights.add(newWeight)
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
    }

    private func doDelete() {
        self.bells.weights.remove(at: self.selection!.index)
    }
    
    private func doDeleteAll() {
        self.bells = Bells([])
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
            self.program.delBells(self.originalName)
            self.program.setBells(self.name, self.bells)
        } else if self.bells != program.getBells(self.name) {
            self.program.setBells(self.name, self.bells)
        }

        app.saveState()
        self.presentation.wrappedValue.dismiss()
    }
}

struct EditBellsView_Previews: PreviewProvider {
    static let model = mockModel()
    static let program = ProgramVM(ModelVM(model), model)

    static var previews: some View {
        EditBellsView(program, "Dumbbells")
    }
}
