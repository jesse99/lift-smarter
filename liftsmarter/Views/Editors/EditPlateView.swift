//  Created by Jesse Vorisek on 11/10/21.
import SwiftUI

/// Used to edit a Plate instance.
struct EditPlateView: View {
    let onEdited: (Plate) -> Void
    @State var weight = ""
    @State var count = ""
    @State var type = PlateType.standard
    @State var error = ""
    @Environment(\.presentationMode) private var presentation
    
    init(_ plate: Plate, onEdited: @escaping (Plate) -> Void) {
        self.onEdited = onEdited
        
        self._weight = State(initialValue: friendlyWeight(plate.weight))
        self._count = State(initialValue: plate.count.description)
        self._type = State(initialValue: plate.type)
    }

    var body: some View {
        VStack() {
            Text("Edit Plate").font(.largeTitle)
            
            weightField("Weight", self.$weight, self.onEdited)
            intField("Count", self.$count, self.onEdited)
            HStack {
                Menu(self.typeTitle()) {
                    Button("Cancel", action: {})
                    Button("Bumper", action: {self.type = .bumper})
                    Button("Magnet", action:   {self.type = .magnet})
                    Button("Standard", action: {self.type = .standard})
                }.font(.callout)
                Spacer()
            }.padding(.leading)
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
        .onAppear(perform: {self.onEdited("")})
    }
    
    private func onEdited(_ text: String) {
        self.error = ""
        
        if let weight = Double(self.weight) {
            if weight <= 0.0 {
                self.error += "Weight should be greater than zero. "
            }
        } else {
            self.error += "Weight should be a floating point number. "
        }

        if let count = Int(self.count) {
            if count <= 0 {
                self.error += "Count should be greater than zero."
            }
        } else {
            self.error += "Count should be an integral number."
        }
    }
    
    private func typeTitle() -> String {
        switch self.type {
        case .bumper: return "Bumper"
        case .magnet: return "Magnet"
        case .standard: return "Standard"
        }
    }
        
    private func onCancel() {
        self.presentation.wrappedValue.dismiss()
    }

    private func onOK() {
        if let weight = Double(self.weight), let count = Int(self.count) { // this should always work
            self.onEdited(Plate(weight: weight, count: count, type: self.type))
        }
        self.presentation.wrappedValue.dismiss()
    }
}

struct EditPlateView_Previews: PreviewProvider {
    static let model = mockModel()
    static let program = ProgramVM(ModelVM(model), model)
    static var plate = Plate(weight: 56.0, count: 4, type: .standard)

    static var previews: some View {
        EditPlateView(plate, onEdited: EditPlateView_Previews.edited)
    }
    
    static func edited(_ plate: Plate) {
    }
}
