//  Created by Jesse Vorisek on 9/9/21.
import Foundation

let RecentHours = 8.0

/// An Exercise all the details for how to do a particular movement. Most of the fields should be
/// mirrored between the program and the workouts that use an exercise, but info.current and
/// enabled are specific to workouts.
/// 
/// This is essentially a de-normalized form of the data designed to simplify usage (but slightly
/// complicate edits).
class Exercise: Storable {
    var name: String            // "Heavy Bench"
    var formalName: String      // "Bench Press"
    var apparatus: Apparatus
    var info: ExerciseInfo      // set info, expected, and current
    var allowRest: Bool         // respect rest weeks
    var overridePercent: String // used to replace the normal weight percent label in exercise views with custom text
    var enabled: Bool           // true if the user wants to perform the exercise within a particular workout

    init(_ name: String, _ formalName: String, _ apparatus: Apparatus, _ info: ExerciseInfo, overridePercent: String = "") {
        self.name = name
        self.formalName = formalName
        self.apparatus = apparatus
        self.info = info
        self.allowRest = true
        self.overridePercent = overridePercent
        self.enabled = true
    }
        
    required init(from store: Store) {
        self.name = store.getStr("name")
        self.formalName = store.getStr("formalName")
        self.apparatus = store.getObj("apparatus")
        self.info = store.getObj("info")
        self.allowRest = store.getBool("allowRest")
        self.overridePercent = store.getStr("overridePercent")
        self.enabled = store.getBool("enabled")
    }

    func save(_ store: Store) {
        store.addStr("name", name)
        store.addStr("formalName", formalName)
        store.addObj("apparatus", apparatus)
        store.addObj("info", info)
        store.addBool("allowRest", allowRest)
        store.addStr("overridePercent", overridePercent)
        store.addBool("enabled", enabled)
    }

    func clone() -> Exercise {
        let store = Store()
        store.addObj("self", self)
        let result: Exercise = store.getObj("self")
        return result
    }
}
