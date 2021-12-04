//  Created by Jesse Vorisek on 9/18/21.
import Combine
import Foundation

// Timers are a little goofy in SwiftUI: there's no good way to start and stop them and they are automatically
// stopped (invalidated) if they're in a NavigationLink view and the user goes back and then returns.
class RestartableTimer: ObservableObject {
    var timer: Publishers.Autoconnect<Timer.TimerPublisher>
    var running = true
    var every: TimeInterval
    private let tolerance: TimeInterval
    
    // Note that the timer won't fire until the every interval elapses.
    init(every: TimeInterval, tolerance: TimeInterval? = nil, start: Bool = true) {
        self.every = every
        self.tolerance = tolerance ?? 0.8*every
        self.timer = Timer.publish(every: self.every, tolerance: self.tolerance, on: .main, in: .common).autoconnect()
        if !start {
            self.stop()
        }
    }

    func restart() {
        self.timer = Timer.publish(every: every, tolerance: tolerance, on: .main, in: .common).autoconnect()
        self.running = true
    }

    func restart(every: TimeInterval) {
        self.every = every
        self.restart()
    }

    func stop() {
        self.timer.upstream.connect().cancel()
        self.running = false
    }
}

