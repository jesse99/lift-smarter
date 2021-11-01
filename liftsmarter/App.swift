//  Created by Jesse Vorisek on 9/9/21.
import SwiftUI

var app: liftsmarterApp!

@main
struct liftsmarterApp: App {    // can use ScenePhase to detect when come to the foreground or goto the background, see https://stackoverflow.com/questions/62538110/swiftui-app-life-cycle-ios14-where-to-put-appdelegate-code
    var model: Model
    let program: ProgramVM
    let logs: LogsVM
    let notifications: Notifications
    @Environment(\.scenePhase) private var phase
    
    init() {
        if let store = loadStore(from: "model") {
            self.model = Model(from: store)
        } else {
            self.model = mockModel()             // TODO: do something else here
        }

        self.program = ProgramVM(model)
        self.logs = LogsVM(model)
        self.notifications = Notifications()

        app = self
    }

    var body: some Scene {
        WindowGroup {
            ContentView(program, logs)
        }.onChange(of: phase, perform: self.onPhaseChange(_:))
    }
    
    func saveState() {
        self.model.program.validate()       // TODO: temp
        storeObject(model, to: "model")
    }
    
    private func onPhaseChange(_ newPhase: ScenePhase) {
        if newPhase == .background {
            if self.model.dirty {
                // We do this in case iOS decides to exit our app once it's in the background.
                // TODO: Potentially this could be the only place where we save but that might be a bit annoying in the sim where we normally just kill the app.
                self.saveState()
            }
            if let secs = TimerView.remaining {
                self.notifications.add(afterSecs: secs)
            }
        } else if newPhase == .active {
            self.notifications.remove()
        }
    }
}

// These are not methods because we want to call loadStore as part of the init method.
fileprivate func loadStore(from fileName: String) -> Store? {
    if let encoded = loadEncoded(from: fileName) {
        if let data = encoded as? Data {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .secondsSince1970
            do {
                return try decoder.decode(Store.self, from: data)
            } catch {
                logErr("Failed to decode '\(fileName)': \(error.localizedDescription)")
            }
        } else {
            logErr("Failed to get data for '\(fileName)'")
        }
    }
    return nil
}

fileprivate func loadEncoded(from fileName: String) -> AnyObject? {
    guard let url = fileNameToURL(fileName) else {
        logErr("Failed to get URL for '\(fileName)'")
        return nil
    }

    do {
        if let data = try? Data(contentsOf: url) {
            return try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as AnyObject
        }
    } catch {
        logErr("Failed to encode '\(fileName)': \(error.localizedDescription)")
    }
    return nil
}

fileprivate func storeObject(_ object: Storable, to fileName: String) {
    let store = Store()
    object.save(store)

    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .secondsSince1970
    do {
        let data = try encoder.encode(store)
        saveEncoded(data as AnyObject, to: fileName)
    } catch {
        logErr("Failed to store '\(fileName)': \(error.localizedDescription)")
    }
}

fileprivate func saveEncoded(_ object: AnyObject, to fileName: String) {
    guard let url = fileNameToURL(fileName) else {
        logErr("Failed to get URL for '\(fileName)'")
        return
    }

    do {
        let data = try NSKeyedArchiver.archivedData(withRootObject: object, requiringSecureCoding: true)
        try data.write(to: url)
    } catch {
        logErr("Failed to archive '\(fileName)': \(error.localizedDescription)")
    }
}

fileprivate func fileNameToURL(_ fname: String) -> URL? {
    guard let dirURL = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first else {
        logErr("Failed to get URL for '\(fname)'")
        return nil
    }

    return dirURL.appendingPathComponent(fname)
}
