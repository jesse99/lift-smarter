//  Created by Jesse Vorisek on 11/28/21.
import AVFoundation // for vibrate
import SwiftUI

struct SavedRestState {
    let state: RestState.State
    let saveTime: Date
    let remaining: Double
}

// Exercise instances with active timers.
var restTimers: [String: SavedRestState] = [:]

/// State associated with the rest timer used within exercise views.
struct RestState {
    enum State {
        case exercising // waiting for the user to finish a set
        case waiting    // user has started the set and we're timing it (e.g. a durations exercise)
        case resting    // implicit timer used when the set has rest secs
        case timing     // explicit timer used when the user presses the Start Timer button
    }

    let id: String
    var state = RestState.State.exercising
    var label = ""
    var color = Color.black
    let timer = RestartableTimer(every: 1, tolerance: 0.5, start: false)
    var startTime = Date()
    var timedSecs = 0         // for waiting this is the secs for a timed exercise, otherwise not used
    var restSecs: Int         // amount of time to rest
    var expired = false
    
    mutating func restore() {
        if let saved = restTimers[self.id] {
            let elapsed = Date().timeIntervalSince(saved.saveTime)
            if saved.remaining > elapsed {
                self.restart(saved.state, Int(saved.remaining - elapsed))
            }
        }
    }

    mutating func restart(_ state: RestState.State, _ restSecs: Int, _ timedSecs: Int = 0) {
        self.state = state
        self.startTime = Date()
        self.restSecs = restSecs
        self.timedSecs = timedSecs
        self.expired = false
        self.label = ""
        self.timer.restart()
    }

    mutating func stop() {
        restTimers[self.id] = nil
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        center.removeAllDeliveredNotifications()

        if case .waiting = self.state {
            if self.restSecs > 0 {
                self.restart(.resting, self.restSecs, self.timedSecs)
                return
            }
        }
        UIApplication.shared.isIdleTimerDisabled = false    // TODO: shouldn't we set this to true at some point?
        self.state = .exercising
        self.timer.stop()
    }
    
    // This will count down to duration seconds and, if the count down goes far enough past
    // duration, revert back to the normal exercising view.
    mutating func onTimer() {
        var secs: Double
        if case .waiting = self.state {
            secs = Double(self.timedSecs) - Date().timeIntervalSince(self.startTime)
        } else {
            secs = Double(self.restSecs) - Date().timeIntervalSince(self.startTime)
        }
        if secs > 0.0 {
            self.label = secsToShortDurationName(secs)
        } else if secs >= -2 {
            self.label = "Done!"
        } else if secs >= -2*60 {
            self.label = "+" + secsToShortDurationName(-secs)
        } else {
            // The timer has run for so long that we'll just kill it. The user is probably
            // not paying attention to the app so we'll do a vibrate to remind him.
            AudioServicesPlayAlertSound(kSystemSoundID_Vibrate)
            self.stop()
            return
        }

        if secs > 0 {
            self.color = .red
        } else {
            self.color = .green  // TODO: better to use DarkGreen
        }

        // Timers don't run in the background so we'll use a local notification via onPhaseChange.
        if secs > 0 {
            restTimers[self.id] = SavedRestState(state: self.state, saveTime: Date(), remaining: secs)
        } else {
            restTimers[self.id] = nil
        }

        let wasExpired = self.expired
        self.expired = secs <= 0.0
        if !wasExpired && self.expired {
            AudioServicesPlayAlertSound(kSystemSoundID_Vibrate)
        }
    }
}

fileprivate func secsToShortDurationName(_ interval: Double) -> String {
    let secs = Int(round(interval))
    let mins = interval/60.0
    let hours = interval/3600.0
    let days = round(hours/24.0)
    
    if secs < 120 {
        return secs == 1 ? "1 sec" : "\(secs) secs"
    } else if mins < 60.0 {
        return String(format: "%0.1f mins", arguments: [mins])
    } else if hours < 24.0 {
        return String(format: "%0.1f hours", arguments: [hours])
    } else {
        return String(format: "%0.1f days", arguments: [days])
    }
}
