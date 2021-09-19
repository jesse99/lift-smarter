//  Created by Jesse Vorisek on 9/9/21.
import Foundation

let RecentHours = 8.0

/// An Exercise all the details for how to do a particular movement.
class Exercise {
    var name: String            // "Heavy Bench"
    var formalName: String      // "Bench Press"
    var modality: Modality
    var expected: Expected      // this may not always be ideal, but user's can always add a second version of an exercise
    var allowRest: Bool         // respect rest weeks
    var overridePercent: String // used to replace the normal weight percent label in exercise views with custom text

    init(_ name: String, _ formalName: String, _ modality: Modality, _ expected: Expected, overridePercent: String = "") {
        ASSERT_EQ(modality.sets.caseIndex(), expected.sets.caseIndex())
        self.name = name
        self.formalName = formalName
        self.modality = modality
        self.expected = expected
        self.allowRest = true
        self.overridePercent = overridePercent
    }
        
    convenience init(_ name: String, _ formalName: String, _ modality: Modality) {
        self.init(name, formalName, modality, defaultExpected(modality))
    }
        
    func isBodyWeight() -> Bool {
        switch self.modality.apparatus {
        case .bodyWeight:
            return true
        default:
            return false
        }
    }

//    static func ==(lhs: Exercise, rhs: Exercise) -> Bool {  // TODO: names would have to be unique?
//        return lhs.name == rhs.name
//    }

//    func hash(into hasher: inout Hasher) {
//        hasher.combine(self.id)
//    }
}
