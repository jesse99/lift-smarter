//  Created by Jesse Vorisek on 9/11/21.
import Foundation

extension Model {
    func log(_ level: LogLevel, _ message: String) {
        self.logs.log(level, message)
    }
}

extension Logs {
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
        self.self.nextID += 1
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
