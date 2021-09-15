//  Created by Jesse Vorisek on 9/9/21.
import Foundation

// TODO:
// support magnets/extra on fixedWeights
// support pairedPlates and singlePlates
// support bumpers, may want to use a PlateWeightSet here, plates have a weight/count
// support magnets
enum Apparatus: Equatable {
    /// Typically these are unweighted but users can enter an arbitrary weight if they are using a plate,
    /// kettlebell, chains, milk jug, or whatever (this comes from Expected).
    case bodyWeight

    /// This is used for dumbbels, kettlebells, cable machines, etc. Name references a FixedWeights object.
    /// If name is nil then the user hasn't activated a FixedWeight set yet.
    case fixedWeights(name: String?)
}

extension Apparatus {
    func caseIndex() -> Int {
        switch self {
        case .bodyWeight:
            return 0
        case .fixedWeights(name: _):
            return 1
        }
    }
}
