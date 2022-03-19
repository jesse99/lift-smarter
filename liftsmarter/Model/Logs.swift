//  Created by Jesse Vorisek on 9/11/21.
import Foundation

enum LogLevel: Int {
    case Error
    case Warning
    case Info
    case Debug
}

typealias LogFunc = (LogLevel, String) -> Void

var logToLog: LogFunc? = nil
var initedLogs = false
var queuedLogs: [(LogLevel, String)] = []

func log(_ level: LogLevel, _ mesg: String) {
    if let log = logToLog {
        log(level, mesg)
    } else if initedLogs {
        // We're logging after Logs has been torn down which is quite annoying. Not much we can do other than print.
        print("\(level.toStr()) \(mesg)")
    } else {
        // We're logging before Logs has been instantiated.
        queuedLogs.append((level, mesg))
    }
}

struct LogLine: Identifiable, Storable {
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

    init(from store: Store) {
        self.seconds = store.getDbl("seconds")
        self.level = store.getObj("level")
        self.line = store.getStr("line")
        current = false
        self.id = store.getInt("id")
    }

    func save(_ store: Store) {
        store.addDbl("seconds", seconds)
        store.addObj("level", level)
        store.addStr("line", line)
        store.addInt("id", id)
    }
}

class Logs: Storable {
    var lines: [LogLine] = []   // newest are at end
    var numErrors = 0
    var numWarnings = 0
    var maxLines = 1000
    var nextID = 0
    let startTime: TimeInterval // time at which this instance of the app started
    
    init() {
        self.startTime = Date().timeIntervalSince1970 - 0.00001  // subtract a tiny time so we don't print a -0.0 timestamp
        self.setupLog()
    }
    
    required init(from store: Store) {
        self.lines = store.getObjArray("lines")
        self.numErrors = store.getInt("numErrors")
        self.numWarnings = store.getInt("numWarnings")
        self.maxLines = store.getInt("maxLines")
        self.nextID = store.getInt("nextID")
        self.startTime = store.getDbl("startTime")
        self.setupLog()
    }

    deinit {
//#if !targetEnvironment(simulator)       // unit tests are concurrent which causes problems here
//        logToLog = nil                  // TODO: above test seems to no longer work
//#endif
    }

    func save(_ store: Store) {
        store.addObjArray("lines", lines)
        store.addInt("numErrors", numErrors)
        store.addInt("numWarnings", numWarnings)
        store.addInt("maxLines", maxLines)
        store.addInt("nextID", nextID)
        store.addDbl("startTime", startTime)
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
        let prefix = entry.level.toStr()
        print("\(timestamp) \(prefix) \(message)")
#endif
    }
    
    private func setupLog() {
        logToLog = self.log
        initedLogs = true
        for (level, mesg) in queuedLogs {
            self.log(level, mesg)
        }
        queuedLogs = []
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
}

extension LogLevel {
    func toStr() -> String {
        switch self {
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

extension LogLevel: Storable {
    init(from store: Store) {
        self = LogLevel(rawValue: store.getInt("level"))!
    }
    
    func save(_ store: Store) {
        store.addInt("level", self.rawValue)
    }
}
