//  Created by Jesse Vorisek on 9/11/21.
import Foundation
import SwiftUI

class LogsVM: ObservableObject {
    private let model: Model
    
    init(_ model: Model) {
        self.model = model
    }
    
    var lines: [LogLine] {
        get {return self.model.logs.lines}
    }
}

// Misc Logic
extension LogsVM {
    func log(_ level: LogLevel, _ message: String) {
        self.model.logs.log(level, message)
    }
}

// UI Labels
extension LogsVM {
    func tabImage() -> String {
        if self.model.logs.numErrors > 0 {
            return "exclamationmark.triangle.fill"
        } else if self.model.logs.numWarnings > 0 {
            return "drop.triangle.fill"
        } else {
            return "text.bubble"
        }
    }

    func lineText(_ line: LogLine) -> String {
        return line.timeStr() + " " + line.line
    }

    func lineColor(_ line: LogLine) -> Color {
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
}
