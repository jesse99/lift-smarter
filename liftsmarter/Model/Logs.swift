//  Created by Jesse Vorisek on 9/11/21.
import Foundation

enum LogLevel: Int {
    case Error
    case Warning
    case Info
    case Debug
}

struct LogLine: Identifiable {
    let seconds: TimeInterval   // since program started
    let level: LogLevel
    let line: String
    let current: Bool           // true if the log line is for this run of the app
    let id: Int                 // this has to be unique across app instances
    
    init(_ seconds: TimeInterval, _ level: LogLevel, _ line: String, id: Int, current: Bool = true) {
        self.seconds = seconds
        self.level = level
        self.line = line
        self.current = current
        self.id = id
    }
}

class Logs: ObservableObject {
    @Published var lines: [LogLine] = []   // newest are at end
    @Published var numErrors = 0
    @Published var numWarnings = 0
    var maxLines = 1000
    var nextID = 0
    let startTime: TimeInterval // time at which this instance of the app started
    
    init() {
        self.startTime = Date().timeIntervalSince1970 - 0.00001  // subtract a tiny time so we don't print a -0.0 timestamp
        logError = {self.log(.Error, $0)}   // TODO: should save logs too (and just the logs)
    }
    
    deinit {
#if !targetEnvironment(simulator)
        logError = nil
#endif
    }
}
