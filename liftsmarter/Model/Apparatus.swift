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

    /// Barbell, leg press, etc.
    case dualPlates(barWeight: Double, _ plates: Plates)

    /// This is used for dumbbels, kettlebells, cable machines, etc. Name references a FixedWeights object.
    /// If name is nil then the user hasn't activated a FixedWeight set yet.
    case fixedWeights(name: String?)

    /// T-bar row, landmine, etc.
    case singlePlates(_ plates: Plates)
}

extension Apparatus: Storable {
    init(from store: Store) {
        let tname = store.getStr("type")
        switch tname {
        case "bodyWeight":
            self = .bodyWeight
            
        case "dualPlates":
            self = .dualPlates(barWeight: store.getDbl("barWeight"), store.getObj("plates"))
            
        case "fixedWeights":
            let name = store.hasKey("name") ? store.getStr("name") : nil
            self = .fixedWeights(name: name)
            
        case "singlePlates":
            self = .singlePlates(store.getObj("plates"))
            
        default:
            ASSERT(false, "loading apparatus had unknown type: \(tname)"); abort()
        }
    }
    
    func save(_ store: Store) {
        switch self {
        case .bodyWeight:
            store.addStr("type", "bodyWeight")

        case .dualPlates(barWeight: let bar, let plates):
            store.addStr("type", "dualPlates")
            store.addDbl("barWeight", bar)
            store.addObj("plates", plates)

        case .fixedWeights(name: let name):
            store.addStr("type", "fixedWeights")
            if let name = name {
                store.addStr("name", name)
            }

        case .singlePlates(let plates):
            store.addStr("type", "singlePlates")
            store.addObj("plates", plates)
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
}
