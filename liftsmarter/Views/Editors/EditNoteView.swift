//  Created by Jesse Vorisek on 10/17/21.
import SwiftUI

struct EditNoteView: View {
    let formalName: String
    @State var text: String
    @ObservedObject var program: ProgramVM
    @Environment(\.presentationMode) private var presentation

    init(_ program: ProgramVM, _ formalName: String) {
        self.program = program
        self.formalName = formalName
        self._text = State(initialValue: program.getUserNote(formalName) ?? defaultNotes[formalName] ?? "")
    }
    
    var body: some View {
        VStack {
            Text("Edit \(self.formalName)").font(.largeTitle)
            TextEditor(text: self.$text).padding()
            Spacer()
            HStack {
                Button("Cancel", action: onCancel).font(.callout)
                Button("Help", action: onHelp).font(.callout)
                Spacer()
                Spacer()
                Button("Done", action: onDone).font(.callout)
            }.padding()
        }
    }
    
    func onHelp() {
        UIApplication.shared.open(URL(string: "https://docs.github.com/en/github/writing-on-github/getting-started-with-writing-and-formatting-on-github/basic-writing-and-formatting-syntax")!)
    }

    func onCancel() {
        self.presentation.wrappedValue.dismiss()
    }

    func onDone() {
        if self.text != (self.program.getUserNote(formalName) ?? defaultNotes[formalName] ?? "") {
            if self.text.isBlankOrEmpty() {
                self.program.setUserNote(self.formalName, nil)
            } else {
                self.program.setUserNote(self.formalName, self.text)
            }
        }
        app.saveState()
        self.presentation.wrappedValue.dismiss()
    }
}

struct EditNoteView_Previews: PreviewProvider {
    static let model = mockModel()
    static let vm = ProgramVM(model)
    
    static var previews: some View {
        EditNoteView(vm, "Arch Hangs")
    }
}
