//  Created by Jesse Vorisek on 11/8/21.
import Foundation

enum PlateType: Int {case standard; case bumper; case magnet}

struct Plate: Equatable, Storable {
    let weight: Double  // weight of the plate, e.g. 45 or 2.5 (for a micro=plate or a magnet)
    let count: Int      // number of plates at that weight/type the user had
    let type: PlateType // bumpers are special cased (they are used if at all possible)

    init(weight: Double, count: Int, type: PlateType) {
        self.weight = weight
        self.count = count
        self.type = type
    }

    init(from store: Store) {
        self.weight = store.getDbl("weight")
        self.count = store.getInt("count")
        self.type = PlateType(rawValue: store.getInt("type"))!
    }

    func save(_ store: Store) {
        store.addDbl("weight", weight)
        store.addInt("count", count)
        store.addInt("type", type.rawValue)
    }
}

/// List of plates, bumpers, and magnets
class Plates: Equatable, Storable {
    init(_ plates: [Plate] = []) {
        ASSERT(plates.isSorted({$0.weight >= $1.weight}), "plates should be largest to smallest")
        self.plates = plates
    }
    
    required init(from store: Store) {
        self.plates = store.getObjArray("plates")
    }

    func save(_ store: Store) {
        store.addObjArray("plates", plates)
    }

    func clone() -> Plates {
        let store = Store()
        store.addObj("self", self)
        let result: Plates = store.getObj("self")
        return result
    }

    static func ==(lhs: Plates, rhs: Plates) -> Bool {
        return lhs.plates == rhs.plates
    }
    
    func getClosest(_ target: Double, dual: Bool) -> ActualWeights {
        let below = self.getClosestBelow(target, dual: dual)
        let above = self.getClosestAbove(target, dual: dual)
        if above != nil {
            if abs(below.total - target) == abs(above!.total - target) {
                let belowBumper = below.weights.contains(where: {$0.label == "bumper"})
                let aboveBumper = above!.weights.contains(where: {$0.label == "bumper"})
                if belowBumper && !aboveBumper {
                    return below
                } else if !belowBumper && aboveBumper {
                    return above!
                }

                if below.weights.count < above!.weights.count {
                    return below
                } else {
                    return above!
                }
            } else if abs(below.total - target) <= abs(above!.total - target) {
                return below
            } else {
                return above!
            }
        } else {
            return below
        }
    }
    
    func getAll(dual: Bool) -> [ActualWeights] {
        func mapWeights(_ subset: [Plate]) -> [ActualWeight] {
            let weights: [ActualWeight] = subset.map({
                switch $0.type {
                case .standard:
                    return ActualWeight(weight: $0.weight, label: "")
                case .bumper:
                    return ActualWeight(weight: $0.weight, label: "bumper")
                case .magnet:
                    return ActualWeight(weight: $0.weight, label: "magnet")
                }
            })
            return weights
        }
        
        if (!dual && self.cache1.isEmpty) || (dual && self.cache2.isEmpty) {             // TODO: need to clear these on edits
            var temp: [Plate] = []              // count should be ignored
            for candidate in self.plates {
                if dual {
                    if candidate.count >= 2 {
                        temp.append(contentsOf: Array(repeating: candidate, count: candidate.count/2))
                    }
                } else {
                    temp.append(contentsOf: Array(repeating: candidate, count: candidate.count))
                }
            }

            var cache: [ActualWeights] = []
            if dual {
                // Just the bar.
                cache.append(ActualWeights(total: 0.0, weights: [ActualWeight(weight: 0.0, label: "")]))
            }

            let scaling = dual ? 2.0 : 1.0
            temp.subsets(sizeLE: temp.count, allowEmpty: false, {subset in
                if subset.contains(where: {$0.type == .standard || $0.type == .bumper}) {
                    let total = scaling * subset.reduce(0.0, {$0 + $1.weight})
                    if let index = cache.firstIndex(where: {sameWeight($0.total, total)}) {
                        let newBumpers = subset.filter({$0.type == .bumper}).count
                        let oldBumpers = cache[index].weights.filter({$0.label == "bumper"}).count
                        if newBumpers > oldBumpers ||                                   // use bumpers where possible
                            subset.count + 1 < cache[index].weights.count ||            // prefer smaller number of plates
                            (subset.count + 1 == cache[index].weights.count &&          // prefer smaller max plate to larger (less plate shuffling)
                             subset.first!.weight < cache[index].weights.first!.weight) {
                            // We've found a better configuration for this weight.
                            cache.remove(at: index)
                            cache.insert(ActualWeights(total: total, weights: mapWeights(subset)), at: index)
                        }
                    } else {
                        // We've found a brand new weight.
                        cache.append(ActualWeights(total: total, weights: mapWeights(subset)))
                    }
                }
            })
            
            if dual {
                self.cache2 = cache.sorted(by: {$0.total < $1.total})
            } else {
                self.cache1 = cache.sorted(by: {$0.total < $1.total})
            }
        }
        
        return dual ? self.cache2 : self.cache1
    }

    // Equal or below.
    func getClosestBelow(_ target: Double, dual: Bool) -> ActualWeights {
        let all = self.getAll(dual: dual)
        for candidate in all.reversed() {
            if candidate.total <= target {
                return candidate
            }
        }
        
        return ActualWeights(total: 0.0, weights: [ActualWeight(weight: 0.0, label: "")])
    }
    
    // Equal or above.
    func getClosestAbove(_ target: Double, dual: Bool) -> ActualWeights? {
        let all = self.getAll(dual: dual)
        for candidate in all {
            if candidate.total >= target {
                return candidate
            }
        }
        
        if let last = all.last {
            return last
        } else {
            return nil
        }
    }
    
    // Next weight below specified weight
    func getBelow(_ weight: Double, dual: Bool) -> ActualWeights {
        return self.getClosestBelow(weight - epsilonWeight, dual: dual)
    }

    // Next weight above specified weight
    func getAbove(_ weight: Double, dual: Bool) -> ActualWeights? {
        return self.getClosestAbove(weight + epsilonWeight, dual: dual)
    }
    
    private var plates: [Plate]         // ordered largest to smallest
    private var cache1: [ActualWeights] = []
    private var cache2: [ActualWeights] = []
}
