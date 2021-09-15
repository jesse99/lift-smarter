//  Created by Jesse Vorisek on 9/11/21.
import MessageUI
import SwiftUI

// From https://stackoverflow.com/questions/56784722/swiftui-send-email
struct MailView: UIViewControllerRepresentable {
    let payload: String
    @Binding var result: Result<MFMailComposeResult, Error>?
    @Environment(\.presentationMode) var presentation

    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        @Binding var presentation: PresentationMode
        @Binding var result: Result<MFMailComposeResult, Error>?

        init(presentation: Binding<PresentationMode>, result: Binding<Result<MFMailComposeResult, Error>?>) {
            _presentation = presentation
            _result = result
        }

        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            defer {
                $presentation.wrappedValue.dismiss()
            }
            guard error == nil else {
                self.result = .failure(error!)
                return
            }
            self.result = .success(result)
        }
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(presentation: presentation, result: $result)
    }

    func makeUIViewController(context: UIViewControllerRepresentableContext<MailView>) -> MFMailComposeViewController {
        let composer = MFMailComposeViewController()
        composer.mailComposeDelegate = context.coordinator

        let data = self.payload.data(using: .utf8)!    // safe because strings are already Unicode
        composer.addAttachmentData(data, mimeType: "text/plain", fileName: "liftsmart.log")
        
        return composer
    }

    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: UIViewControllerRepresentableContext<MailView>) {
    }
}

struct LogView: View {
    let model: Model
    @ObservedObject var logs: Logs
    @State var show = LogLevel.Warning
    @State var isShowingMailView = false
    @State var result: Result<MFMailComposeResult, Error>? = nil

    init(_ model: Model) {
        self.model = model
        self.logs = model.logs
    }
    
    var body: some View {
        VStack() {
            Text("Logs").font(.largeTitle)
            List(self.logs.lines) {line in
                if line.level.rawValue <= self.show.rawValue {
                    Text(getText(line)).font(.headline).foregroundColor(getColor(line))
                }
            }
            HStack {
                Button("Email", action: onEmail).font(.callout) // TODO: make sure that this works
                    .padding(.leading)
                    .disabled(!self.canEmail())
                    .sheet(isPresented: self.$isShowingMailView) {MailView(payload: self.getPayload(), result: self.$result)
                }
                Spacer()
                Menu(self.showStr()) {
                    Button("Cancel", action: {})
                    Button(buttonStr(.Debug), action: {self.show = .Debug})
                    Button(buttonStr(.Info), action: {self.show = .Info})
                    Button(buttonStr(.Warning), action: {self.show = .Warning})
                    Button(buttonStr(.Error), action: {self.show = .Error})
                }.font(.callout).padding(.trailing)
            }.padding(.bottom)
        }
    }
    
    private func getText(_ line: LogLine) -> String {
        return line.timeStr() + " " + line.line
    }
    
    private func getColor(_ line: LogLine) -> Color {
        var color: UIColor
        switch line.level {
        case .Debug:
            color = .gray
        case .Error:
            color = .red
        case .Info:
            color = .black
        case.Warning:
            color = .orange
        }

        if !line.current {
            switch line.level {
            case .Debug:
                color = color.lighten(byPercentage: 0.3) ?? .lightGray
            case .Error:
                color = color.shade(byPercentage: 0.6) ?? .lightGray
            case .Info:
                color = color.lighten(byPercentage: 0.7) ?? .lightGray
            case.Warning:
                color = color.shade(byPercentage: 0.4) ?? .lightGray
            }
        }
        
        return Color(color)
    }

    private func showStr() -> String {
        switch self.show {
        case .Error:
            return "Only Errors"
        case.Warning:
            return "Warning, Error"
        case .Info:
            return "Info, Warning, Error"
        case .Debug:
            return "All Logs"
        }
    }
    
    private func buttonStr(_ level: LogLevel) -> String {
        switch level {
        case .Error:
            return "Errors only"
        case.Warning:
            return "Warning and Errors"
        case .Info:
            return "Info, Warning, and Errors"
        case .Debug:
            return "All"
        }
    }
    
    private func canEmail() -> Bool {
        return MFMailComposeViewController.canSendMail()
    }
    
    private func onEmail() {
        self.isShowingMailView = true
    }

    private func getPayload() -> String {
        var payload = ""
        payload.reserveCapacity(30*self.logs.lines.count)
        
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") ?? "?"
        payload += "Version: \(version)\n"

        let build = Bundle.main.object(forInfoDictionaryKey: kCFBundleVersionKey as String) ?? "?"
        payload += "Build: \(build)\n\n"
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale.current
        payload += "Date: \(formatter.string(from: Date()))\n"

        for line in self.logs.lines {
            payload += "\(line.timeStr()) \(line.level) \(line.line)\n"
        }

        return payload
    }
}

struct LogView_Previews: PreviewProvider {
    static var previews: some View {
        LogView(makeModel())
    }
    
    static func makeModel() -> Model {
        let model = mockModel()
        model.logs.lines.append(LogLine(TimeInterval(0.0), .Info, "Started up", id: 1, current: false))
        model.logs.lines.append(LogLine(TimeInterval(1.1001), .Info, "No one cares", id: 2, current: false))
        model.logs.lines.append(LogLine(TimeInterval(2.0), .Warning, "Meltdown imminent", id: 3, current: false))
        model.logs.lines.append(LogLine(TimeInterval(2.1), .Error, "Containment failure", id: 4, current: false))
        
        model.logs.lines.append(LogLine(TimeInterval(0.0), .Info, "Started up", id: 5))
        model.logs.lines.append(LogLine(TimeInterval(0.1), .Info, "Loaded store", id: 6))
        model.logs.lines.append(LogLine(TimeInterval(1.0), .Info, "Starting Skullcrushers", id: 7))
        model.logs.lines.append(LogLine(TimeInterval(1.01), .Error, "Crushed head", id: 8))
        model.logs.lines.append(LogLine(TimeInterval(2.0), .Info, "Finished", id: 9))

        model.logs.maxLines = 12
        model.logs.nextID = model.logs.lines.count + 1

        return model
    }
}
