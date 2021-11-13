//  Created by Jesse Vorisek on 11/12/21.
import SwiftUI

struct ProgramsView: View {
    @ObservedObject var model: ModelVM
    @State var showEditActions: Bool = false
    @State var selection: ListEntry? = nil
    @State var confirmAlert: Bool = false
    @State var alertMesg: String = ""

    init(_ model: ModelVM) {
        self.model = model
    }

    var body: some View {
        VStack() {
            Text("Programs").font(.largeTitle)

            List(self.model.entries()) {entry in
                VStack() {
                    Text(entry.name).foregroundColor(entry.color).font(.headline)
                }
                .contentShape(Rectangle())  // so we can click within spacer
                    .onTapGesture {
                        self.selection = entry
                        self.showEditActions = true
                    }
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
    }

    private func editButtons() -> [ActionSheet.Button] {
        var buttons: [ActionSheet.Button] = []

        buttons.append(.default(Text("Add"), action: self.onAdd))
        if self.selection!.name != self.model.active {
            buttons.append(.default(Text("Activate"), action: self.onActivate))
            buttons.append(.destructive(Text("Delete"), action: self.onDelete))
        }
        buttons.append(.cancel(Text("Cancel"), action: {}))

        return buttons
    }

    private func onActivate() {
        self.model.setActive(self.selection!.name)
    }

    private func onDelete() {
        self.confirmAlert = true
        self.alertMesg = "Of \(self.selection!.name)"
    }
    
    private func doDelete() {
        self.model.delete(self.selection!.index)
    }

    private func onAdd() {
        self.model.add()
    }
}

struct ProgramsView_Previews: PreviewProvider {
    static let model = ModelVM(mockModel())

    static var previews: some View {
        ProgramsView(model)
    }
}
