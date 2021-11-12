//  Created by Jesse Vorisek on 9/14/21.
import AVFoundation // for vibrate
import SwiftUI

struct TimerView: View {
    let title: String
    @State var duration: Int
    @State var secondDuration: Int = 0    // used to wait twice
    @State private var startTime = Date()
    @State private var elapsed: Int = 0
    @State private var label: String = ""
    @State private var waiting: Bool = true
    @State private var resting: Bool = false
    @Environment(\.presentationMode) private var presentationMode
    private let timer = Timer.publish(every: 1, tolerance: 0.5, on: .main, in: .common).autoconnect()

    static var remaining: Double? = nil    // nil => not running

    var body: some View {
        VStack {
            Text(self.title).font(.largeTitle)
            Spacer()
            Spacer()
            if self.waiting {
                Text("\(label)").font(.system(size: 64.0))
            } else {
                Text("\(label)").font(.system(size: 64.0)).foregroundColor(Color.green) // TODO: better to use DarkGreen
            }
            Spacer()
            Button(buttonLabel(), action: onStopTimer).font(.system(size: 20.0)).onReceive(timer, perform: onTimer)
            Spacer()
            Spacer()
        }.onAppear {UIApplication.shared.isIdleTimerDisabled = true}
    }
    
    func onStopTimer() {
        TimerView.remaining = nil
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        center.removeAllDeliveredNotifications()
        
        if self.secondDuration > 0 {
            self.duration = self.secondDuration
            self.secondDuration = 0
            self.startTime = Date()
            self.elapsed = 0
            self.resting = true
            self.waiting = true
        } else {
            self.timer.upstream.connect().cancel()
            UIApplication.shared.isIdleTimerDisabled = false
            self.presentationMode.wrappedValue.dismiss()
        }
    }
    
    // This will count down to duration seconds and, if the count down goes far enough past
    // duration, auto-close this modal view.
    func onTimer(_ currentTime: Date) {
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
            self.onStopTimer()
            return
        }

        // Timers don't run in the background so we'll use a local notification via sceneDidEnterBackground.
        TimerView.remaining = secs
        
        let wasWaiting = self.waiting
        self.waiting = secs > 0.0
        if self.waiting != wasWaiting {
            AudioServicesPlayAlertSound(kSystemSoundID_Vibrate)
        }
    }
    
    func buttonLabel() -> String {
        if resting {
            return "Stop Resting"
        } else {
            return "Stop Timer"
        }
    }
}

struct TimerView_Previews: PreviewProvider {
    static var previews: some View {
        TimerView(title: "Curls", duration: 10, secondDuration: 5)
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

