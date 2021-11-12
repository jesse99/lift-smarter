//  Created by Jesse Vorisek on 11/10/21.
import SwiftUI

/// Used to edit Plates arrays.
struct EditPlatesView: View {
    let apparatus: Binding<Apparatus>
    let plates: Plates
    let dual: Bool
    let originalPlates: Plates
    @State var entries: [ListEntry] = []
    @State var barWeight = ""
    @State var showEditActions: Bool = false
    @State var selection: ListEntry? = nil
    @State var addingSheet: Bool = false
    @State var editingSheet: Bool = false
    @State var confirmAlert: Bool = false
    @State var alertMesg: String = ""
    @State var error = ""
    @Environment(\.presentationMode) private var presentation

    init(_ apparatus: Binding<Apparatus>) {
        self.apparatus = apparatus
        
        switch apparatus.wrappedValue {
        case .dualPlates(barWeight: let bar, let plates):
            self.dual = true
            self._barWeight = State(initialValue: friendlyWeight(bar))
            self.plates = plates
            self.originalPlates = plates.clone()
        case .singlePlates(let plates):
            self.dual = false
            self.plates = plates
            self.originalPlates = plates.clone()
        default:
            ASSERT(false, "should only be called for plates")
            self.dual = false
            self.plates = Plates()
            self.originalPlates = Plates()
        }
        
        self._entries = State(initialValue: self.getEntries())
    }
    
    var body: some View {
        VStack() {
            Text("Edit Plates").font(.largeTitle)
            
            if self.dual {
                weightField("Bar Weight", self.$barWeight, self.onEdited)
            }

            List(self.entries) {entry in
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
                EditPlateView(self.plates[self.selection!.index], onEdited: self.doEdited)
            }
            Text(self.error).foregroundColor(.red).font(.callout)

            Divider()
            HStack {
                Button("Cancel", action: onCancel).font(.callout)
                Spacer()
                Spacer()
                Button("Add", action: self.onAdd).font(.callout)
                    .sheet(isPresented: self.$addingSheet) {
                        EditTextView(title: "Weight", content: "", type: .decimalPad, validator: self.onValidWeight, sender: self.doAdded)
                    }
                Button("OK", action: onOK).font(.callout).disabled(!self.error.isEmpty)
            }
            .padding()
        }
        .actionSheet(isPresented: $showEditActions) {
            ActionSheet(title: Text(self.selection!.name), buttons: editButtons())}
        .alert(isPresented: $confirmAlert) {   // and views can only have one alert
            return Alert(
                title: Text("Confirm delete"),
                message: Text(self.alertMesg),
                primaryButton: .destructive(Text("Delete")) {self.doDelete()},
                secondaryButton: .default(Text("Cancel")))
            }
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
        buttons.append(.default(Text("Edit"), action: self.onEdit))
        buttons.append(.cancel(Text("Cancel"), action: {}))

        return buttons
    }

    private func doEdited(_ plate: Plate) {
        self.plates.delete(at: self.selection!.index)
        self.plates.add(plate)
        self.entries = self.getEntries()
    }

    private func doDelete() {
        self.plates.delete(at: self.selection!.index)
        self.entries = self.getEntries()
    }

    private func onValidWeight(_ text: String) -> String {
        if let weight = Double(text) {
            if weight > 0.0 {
                return ""
            } else {
                return "Weight should be larger than zero"
            }
        } else {
            return "Weight should be a floating point number"
        }
    }

    private func doAdded(_ text: String) {
        switch apparatus.wrappedValue {
        case .dualPlates(barWeight: _, let plates):
            plates.add(Plate(weight: Double(text)!, count: 4, type: .standard))
        case .singlePlates(_):
            plates.add(Plate(weight: Double(text)!, count: 2, type: .standard))
        default:
            ASSERT(false, "should only be called for plates")
        }
        self.entries = self.getEntries()
    }

    private func onDelete() {
        self.confirmAlert = true
        
        let plate = self.plates[self.selection!.index]
        self.alertMesg = "Of \(friendlyUnitsWeight(plate.weight, plural: true))"
    }
    
    private func onAdd() {
        self.addingSheet = true
    }

    private func onEdit() {
        self.editingSheet = true
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

    private func onCancel() {
        switch apparatus.wrappedValue {
        case .dualPlates(barWeight: let bar, _):
            self.apparatus.wrappedValue = .dualPlates(barWeight: bar, self.originalPlates)
        case .singlePlates(_):
            self.apparatus.wrappedValue = .singlePlates(self.originalPlates)
        default:
            ASSERT(false, "should only be called for plates")
        }

        self.presentation.wrappedValue.dismiss()
    }

    private func onOK() {
        switch apparatus.wrappedValue {
        case .dualPlates(barWeight: _, let plates):
            self.apparatus.wrappedValue = .dualPlates(barWeight: Double(self.barWeight)!, plates)
        default:
            break
        }
        self.presentation.wrappedValue.dismiss()
    }
}

struct EditPlatesView_Previews: PreviewProvider {
    static let plates = Plates([
        Plate(weight: 45, count: 4, type: .standard),
        Plate(weight: 35, count: 4, type: .standard),
        Plate(weight: 25, count: 4, type: .standard),
        Plate(weight: 10, count: 4, type: .standard),
        Plate(weight: 5, count: 4, type: .standard)
    ])
    static var apparatus = Binding.constant(Apparatus.dualPlates(barWeight: 45.0, plates))

    static var previews: some View {
        EditPlatesView(apparatus)
    }
}
