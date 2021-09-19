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

class Logs {
    var lines: [LogLine] = []   // newest are at end
    var numErrors = 0
    var numWarnings = 0
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

    // This sort of logic would normally go into a view model but we want to allow logging
    // from pretty much anywhere (e.g. ASSERT) so it's here.
    func log(_ level: LogLevel, _ message: String) {
        while self.lines.count >= self.maxLines {
            let line = self.lines[0]
            if line.level == .Error {
                self.numErrors -= 1
            } else if line.level == .Warning {
                self.numWarnings -= 1
            }
            self.lines.remove(at: 0)
        }

        let elapsed = Date().timeIntervalSince1970 - self.startTime
        let entry = LogLine(elapsed, level, message, id: self.nextID)
        self.nextID += 1
        self.lines.append(entry)
        
        if entry.level == .Error {
            self.numErrors += 1
        } else if entry.level == .Warning {
            self.numWarnings += 1
        }

#if targetEnvironment(simulator)
        let timestamp = entry.timeStr()
        let prefix = entry.levelStr()
        print("\(timestamp) \(prefix) \(message)")
#endif
    }
}

extension LogLine {
    func timeStr() -> String {
        var elapsed = self.seconds
        if elapsed > 60*60 {
            let hours = floor(elapsed/(60*60))
            elapsed -= hours*60*60
            
            let mins = floor(elapsed/60)
            elapsed -= mins*60
            return String(format: "%.0f:%.0f:%.1f", hours, mins, elapsed)
        } else if elapsed > 60 {
            let mins = floor(elapsed/60)
            elapsed -= mins*60
            return String(format: "%.0f:%.1f", mins, elapsed)
        } else {
            return String(format: "%.1f", elapsed)
        }
    }

    func levelStr() -> String {
        switch self.level {
        case .Error:
            return "ERR "
        case .Warning:
            return "WARN"
        case .Info:
            return "INFO"
        case .Debug:
            return "DBG "
        }
    }
}
