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
        case resting    // implicit timer used when the set has rest secs
        case timing     // explicit timer used when the user presses the Start Timer button
    }

    let id: String
    var state = RestState.State.exercising
    var label = ""
    var color = Color.black
    let timer = RestartableTimer(every: 1, tolerance: 0.5, start: false)
    var startTime = Date()
    var duration: Int
    var expired = false
    
    mutating func restore() {
        if let saved = restTimers[self.id] {
            let elapsed = Date().timeIntervalSince(saved.saveTime)
            if saved.remaining > elapsed {
                self.restart(saved.state, Int(saved.remaining - elapsed))
            }
        }
    }

    mutating func restart(_ state: RestState.State, _ duration: Int) {
        self.state = state
        self.startTime = Date()
        self.duration = duration
        self.expired = false
        self.label = ""
        self.timer.restart()
    }

    mutating func stop() {
        self.state = .exercising
        self.timer.stop()
    }
    
    // This will count down to duration seconds and, if the count down goes far enough past
    // duration, revert back to the normal exercising view.
    mutating func onTimer() {
        let secs = Double(self.duration) - Date().timeIntervalSince(self.startTime)
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

        if !self.expired {
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
