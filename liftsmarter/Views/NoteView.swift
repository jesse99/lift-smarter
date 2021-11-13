//  Created by Jesse Vorisek on 10/17/21.
import SwiftUI
import WebKit

struct HTMLStringView: UIViewRepresentable {
    typealias UIViewType = WKWebView

    let htmlContent: String

    func makeUIView(context: Context) -> WKWebView {
        return WKWebView()
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        uiView.loadHTMLString(htmlContent, baseURL: nil)
    }
}

struct NoteView: View {
    let formalName: String
    @State var editModal = false
    @ObservedObject var program: ProgramVM
    @Environment(\.presentationMode) private var presentation

    init(_ program: ProgramVM, formalName: String) {
        self.program = program
        self.formalName = formalName
    }

    var body: some View {
        VStack {
            Text(self.formalName).font(.largeTitle)
            if #available(iOS 15.0, *) {
                Text(self.markup())
                    .font(.callout)
                    .padding()
            } else {
                HTMLStringView(htmlContent: self.markup())
                    .padding()
            }
            Spacer()
            HStack {
                Button("Revert", action: onRevert)
                    .font(.body)
                    .disabled(!self.hasUserNote())
                Button("Edit", action: onEdit)
                    .font(.callout)
                    .sheet(isPresented: self.$editModal) {EditNoteView(self.program, self.formalName)}
                Spacer()
                Spacer()
                Button("Done", action: onDone).font(.callout)
            }
            .padding()
        }
    }
    
    @available(iOS 15, *)
    private func markup() -> AttributedString {
        do {
            return try AttributedString(markdown: self.program.getUserNote(formalName) ?? defaultNotes[formalName] ?? "No note", options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace))
        } catch {
            return AttributedString("Error parsing markdown")
        }
    }
    
    @available(iOS 14, *)
    private func markup() -> String {
        return self.program.getUserNote(formalName) ?? defaultNotes[formalName] ?? "No note"
    }
    
    private func hasUserNote() -> Bool {
        return !((self.program.getUserNote(formalName) ?? "").isEmpty)
    }
    
    private func onEdit() {
        self.editModal = true
    }
    
    private func onRevert() {
        self.program.setUserNote(self.formalName, nil)
    }

    private func onDone() {
        self.presentation.wrappedValue.dismiss()
    }
}

struct NoteView_Previews: PreviewProvider {
    static let model = mockModel()
    static let vm = ProgramVM(ModelVM(model), model)
    
    static var previews: some View {
        NoteView(vm, formalName: "Arch Hangs")
    }
}
