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

    /// Barbell, leg press, etc. Name references a Plates object. If name is nil then the user hasn't activated a Plates yet.
    case dualPlates(barWeight: Double, _ name: String?)

    /// This is used for dumbbels, kettlebells, cable machines, etc. Name references a FixedWeights object.
    /// If name is nil then the user hasn't activated a FixedWeight set yet.
    case fixedWeights(name: String?)

    /// T-bar row, landmine, etc.
    case singlePlates(_ name: String?)
}

extension Apparatus: Storable {
    init(from store: Store) {
        let tname = store.getStr("type")
        switch tname {
        case "bodyWeight":
            self = .bodyWeight
            
        case "dualPlates":
            let name = store.hasKey("name") ? store.getStr("name") : nil
            self = .dualPlates(barWeight: store.getDbl("barWeight"), name)
            
        case "fixedWeights":
            let name = store.hasKey("name") ? store.getStr("name") : nil
            self = .fixedWeights(name: name)
            
        case "singlePlates":
            let name = store.hasKey("name") ? store.getStr("name") : nil
            self = .singlePlates(name)
            
        default:
            ASSERT(false, "loading apparatus had unknown type: \(tname)"); abort()
        }
    }
    
    func save(_ store: Store) {
        switch self {
        case .bodyWeight:
            store.addStr("type", "bodyWeight")

        case .dualPlates(barWeight: let bar, let name):
            store.addStr("type", "dualPlates")
            store.addDbl("barWeight", bar)
            if let name = name {
                store.addStr("name", name)
            }

        case .fixedWeights(name: let name):
            store.addStr("type", "fixedWeights")
            if let name = name {
                store.addStr("name", name)
            }

        case .singlePlates(let name):
            store.addStr("type", "singlePlates")
            if let name = name {
                store.addStr("name", name)
            }
        }
    }
}

extension Apparatus {
    func caseIndex() -> Int {
        switch self {
        case .bodyWeight:
            return 0
        case .fixedWeights(name: _):
            return 1
        case .dualPlates(barWeight: _, _):
            return 2
        case .singlePlates(_):
            return 3
        }
    }

    func clone() -> Apparatus {
        switch self {
        case .bodyWeight:
            return self
        case .fixedWeights(name: _):
            return self
        case .dualPlates(barWeight: let bar, let name):
            return .dualPlates(barWeight: bar, name)
        case .singlePlates(let name):
            return .singlePlates(name)
        }
    }
}
