//  Created by Jesse Vorisek on 10/9/21.
import SwiftUI

/// Used to add one or more weights to a FixedWeightSet.
struct AddFixedWeightsView: View {
    let program: ProgramVM
    let name: String
    let fws: Binding<FixedWeightSet>
    let extra: Bool
    let onEdit: () -> Void
    @State var first = ""
    @State var max = ""
    @State var step = ""
    @State var showHelp = false
    @State var helpText = ""
    @State var error = ""
    @Environment(\.presentationMode) private var presentation
    
    init(_ program: ProgramVM, _ name: String, _ fws: Binding<FixedWeightSet>, extra: Bool, onEdit: @escaping () -> Void) {
        self.program = program
        self.name = name
        self.fws = fws
        self.extra = extra
        self.onEdit = onEdit
    }

    var body: some View {
        VStack() {
            Text("Add to \(self.name)").font(.largeTitle)
            
            weightField("First", self.$first, self.onEditedRange, self.onFirstHelp, placeholder: "10")
            weightField("Step", self.$step, self.onEditedRange, self.onStepHelp, placeholder: "10")
            weightField("Last", self.$max, self.onEditedRange, self.onMaxHelp, placeholder: "200")
            Spacer()

            Text(self.error).foregroundColor(.red).font(.callout)

            Divider()
            HStack {
                Button("Cancel", action: onCancel).font(.callout)
                Spacer()
                Spacer()
                Button("OK", action: onOK).font(.callout).disabled(!self.error.isEmpty)
            }
            .padding()
        }
        .alert(isPresented: $showHelp) { 
            return Alert(
                title: Text("Help"),
                message: Text(self.helpText),
                dismissButton: .default(Text("OK")))
        }
        .onAppear(perform: {self.onEditedRange("")})
    }
    
    private func onEditedRange(_ text: String) {
        self.error = self.program.validateWeightRange(self.first, self.step, self.max) ?? ""
    }
        
    private func onFirstHelp() {
        self.helpText = "The lowest weight to add."
        self.showHelp = true
    }

    private func onStepHelp() {
        self.helpText = "The weight increment."
        self.showHelp = true
    }

    private func onMaxHelp() {
        self.helpText = "Weights stop being added after this is reached. If empty then only first will be added."
        self.showHelp = true
    }

    private func onCancel() {
        self.presentation.wrappedValue.dismiss()
    }

    private func onOK() {
        if let f = Double(self.first) { // this should always work
            if extra {
                if let s = Double(self.step), let m = Double(self.max) {
                    var weight = f
                    while weight <= m {
                        self.fws.wrappedValue.extra.add(weight)
                        weight += s
                    }
                } else {
                    self.fws.wrappedValue.extra.add(f)
                }
            } else {
                if let s = Double(self.step), let m = Double(self.max) {
                    var weight = f
                    while weight <= m {
                        self.fws.wrappedValue.weights.add(weight)
                        weight += s
                    }
                } else {
                    self.fws.wrappedValue.weights.add(f)
                }
            }
            self.onEdit()
        }
        self.presentation.wrappedValue.dismiss()
    }
}

struct AddFixedWeightsView_Previews: PreviewProvider {
    static let model = mockModel()
    static let program = ProgramVM(model)
    static var fws = Binding.constant(program.getFWS("Dumbbells")!)

    static var previews: some View {
        AddFixedWeightsView(program, "Dumbbells", fws, extra: false, onEdit: AddFixedWeightsView_Previews.onEdited
        )
    }
    
    static func onEdited() {
        
    }
}
