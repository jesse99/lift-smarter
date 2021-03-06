//  Created by Jesse Vorisek on 10/31/21.
import SwiftUI

/// This is used to notify the user that a timer has expired if the app is in the background.
class Notifications {   // note that it's awkward to fold this into App because of the required mutations
    var enabled = false
    var pendingID = ""
    var nextID = 1
    
    init() {
        let options: UNAuthorizationOptions = [.alert, .sound, .badge]
        let notifications = UNUserNotificationCenter.current()
        notifications.requestAuthorization(options: options) {allowed, error in
            if allowed {
                self.enabled = true
            } else {
                if let err = error {
                    log(.Warning, "background notifications were not authorized: \(err)")
                } else {
                    log(.Info, "background notifications were not authorized")
                }
            }
        }
    }

    func add(afterSecs: Double, title: String = "Timer finished", subTitle: String = "") {
        if self.enabled {
            if !self.pendingID.isEmpty {
                log(.Info, "removing old notification")
            }
            self.remove()
            
            let content = UNMutableNotificationContent()
            content.title = title
            content.subtitle = subTitle
            content.sound = UNNotificationSound.default
            
            self.pendingID = "listsmarter-\(self.nextID)"
            self.nextID += 1

            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: afterSecs, repeats: false)
            let request = UNNotificationRequest(identifier: self.pendingID, content: content, trigger: trigger)

            let notifications = UNUserNotificationCenter.current()
            notifications.add(request) {error in
                if let err = error {
                    log(.Error, "failed to schedule notification: \(err)")
                }
            }
            log(.Info, "added notification after \(afterSecs) secs")
        }
    }
    
    func remove() {
        if !self.pendingID.isEmpty {
            let notifications = UNUserNotificationCenter.current()
            notifications.removePendingNotificationRequests(withIdentifiers: [self.pendingID])
            self.pendingID = ""
            log(.Info, "removed old notification")
        }
    }
}
