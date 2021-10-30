//  Created by Jesse Vorisek on 10/9/21.
import SwiftUI

typealias HelpFunc = () -> Void
typealias Help2Func = (String) -> Void

/// Used for text fields that are mostly words, e.g. an exercise name.
func wordsField(_ label: String,_ text: Binding<String>, _ onEdit: @escaping (String) -> Void, onHelp: HelpFunc? = nil) -> AnyView {
    return AnyView(
        HStack {
            Text("\(label):").font(.headline)
            TextField("", text: text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.default)
                .disableAutocorrection(true)
                .autocapitalization(.words)
                .onChange(of: text.wrappedValue, perform: onEdit)
            if let fn = onHelp {
                Button("?", action: fn).font(.callout).padding(.trailing)
            }
        }.padding(.leading)
    )
}

/// Used for text fields that are mostly numeric, e.g. "30s" or "8x3".
func numericishField(_ label: String, _ text: Binding<String>, _ onEdit: @escaping (String) -> Void, _ onHelp: HelpFunc? = nil) -> AnyView {
    return AnyView(
        HStack {
            Text("\(label):").font(.headline)
            TextField("", text: text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.default)
                .disableAutocorrection(true)
                .onChange(of: text.wrappedValue, perform: onEdit)
            if let fn = onHelp {
                Button("?", action: fn).font(.callout).padding(.trailing)
            }
        }.padding(.leading)
    )
}

// Simple integer
func intField(_ label: String, _ text: Binding<String>, _ onEdit: @escaping (String) -> Void, _ onHelp: HelpFunc? = nil, placeholder: String = "") -> AnyView {
    return AnyView(
        HStack {
            Text("\(label):").font(.headline)
            TextField(placeholder, text: text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.numberPad)
                .disableAutocorrection(true)
                .onChange(of: text.wrappedValue, perform: onEdit)
            if let fn = onHelp {
                Button("?", action: fn).font(.callout).padding(.trailing)
            }
        }.padding(.leading)
    )
}

/// Used for text fields that contain just a weight.
func weightField(_ label: String, _ text: Binding<String>, _ onEdit: @escaping (String) -> Void, _ onHelp: HelpFunc? = nil, placeholder: String = "") -> AnyView {
    return AnyView(
        HStack {
            Text("\(label):").font(.headline)
            TextField(placeholder, text: text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.decimalPad)
                .disableAutocorrection(true)
                .onChange(of: text.wrappedValue, perform: onEdit)
            if let fn = onHelp {
                Button("?", action: fn).font(.callout).padding(.trailing)
            }
        }.padding(.leading)
    )
}
