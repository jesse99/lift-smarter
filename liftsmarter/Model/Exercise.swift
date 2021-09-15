//  Created by Jesse Vorisek on 9/9/21.
import Foundation

let RecentHours = 8.0

/// An Exercise all the details for how to do a particular movement. It does not
/// include history or achievement information.
class Exercise: Identifiable, ObservableObject {
    @Published var name: String            // "Heavy Bench"
    @Published var formalName: String      // "Bench Press"
    @Published var modality: Modality
    @Published var expected: Expected
    @Published var overridePercent: String // used to replace the normal weight percent label in exercise views with custom text

    init(_ name: String, _ formalName: String, _ modality: Modality, _ expected: Expected, overridePercent: String = "") {
        ASSERT_EQ(modality.sets.caseIndex(), expected.sets.caseIndex())
        self.name = name
        self.formalName = formalName
        self.modality = modality
        self.expected = expected
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

    var id: String {
        get {
            return self.name
        }
    }
}
