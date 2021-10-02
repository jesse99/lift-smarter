//  Created by Jesse Vorisek on 9/30/21.
import SwiftUI

/// Generic view allowing the user to enter in one line of arbitrary text.
struct EditTextView: View {
    typealias Validator = (String) -> String    // empty string => OK
    typealias Sender = (String) -> Void
    
    let title: String
    let placeHolder: String
    let type: UIKeyboardType
    let autoCorrect: Bool
    let caps: UITextAutocapitalizationType
    let validator: Validator?                   // nil if any string is OK
    let sender: Sender
    @State var content: String
    @State var error = ""
    @Environment(\.presentationMode) private var presentationMode

    init(title: String, content: String, placeHolder: String = "", type: UIKeyboardType = .default, autoCorrect: Bool = true, caps: UITextAutocapitalizationType = .none, validator: Validator? = nil, sender: @escaping Sender) {
        self.title = title
        self.placeHolder = placeHolder
        self.type = type
        self.caps = caps
        self.autoCorrect = autoCorrect
        self.validator = validator
        self.sender = sender
        self._content = State(initialValue: content)
    }

    var body: some View {
        VStack {
            Text(self.title).font(.largeTitle).padding(.bottom)
            TextField(self.placeHolder, text: self.$content)    // for multi-line use TextEditor (could do this with an if)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(self.type)
                .disableAutocorrection(!self.autoCorrect)
                .autocapitalization(caps)
                .onChange(of: self.content, perform: self.onEdited)
                .padding()
            Spacer()
            Text(self.error).foregroundColor(.red).font(.callout)
            HStack {
                Button("Cancel", action: onCancel).font(.callout)
                Spacer()
                Spacer()
                Button("OK", action: onOK).font(.callout).disabled(!self.error.isEmpty)
            }.padding()
        }.onAppear(perform: {
            self.onEdited(self.content)
        })
    }
    
    func onEdited(_ text: String) {
        if let closure = self.validator {
            self.error = closure(text)
        }
    }

    func onCancel() {
        self.presentationMode.wrappedValue.dismiss()
    }

    func onOK() {
        self.sender(self.content)
        self.presentationMode.wrappedValue.dismiss()
    }
}

struct EditTextView_Previews: PreviewProvider {
    static var previews: some View {
        EditTextView(title: "Edit Text", content: "", placeHolder: "arbitrary", sender: done)
    }
    
    static func done(_ text: String) {
    }
}
