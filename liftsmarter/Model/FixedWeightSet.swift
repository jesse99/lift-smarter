//  Created by Jesse Vorisek on 10/5/21.
import Foundation

let epsilonWeight = 0.001   // a weight smaller than any real weight

func sameWeight(_ lhs: Double, _ rhs: Double) -> Bool {
    return abs(lhs - rhs) < epsilonWeight
}

func differentWeight(_ lhs: Double, _ rhs: Double) -> Bool {
    return abs(lhs - rhs) > epsilonWeight
}

struct ActualWeight {
    let weight: Double   // 45 for a plate, 35 for a dumbbell, 2.5 for a magnet, 1.2.5 for an extra weight
    let label: String    // "", "bumper", or "magnet" for a plate and "" or "extra" for a fixed weight (extra because it could be a cable machine)
}

struct ActualWeights {
    let total: Double            // often sum of weights below but will also include stuff like barbell weight if that's being used
    let weights: [ActualWeight]
}

struct FixedWeights: Equatable, Sequence, Storable {
    init() {
        self.weights = []
    }
    
    init(_ weights: [Double]) {
        self.weights = weights
    }
    
    init(from store: Store) {
        self.weights = store.getDblArray("weights")
    }

    func save(_ store: Store) {
        store.addDblArray("weights", weights)
    }

    mutating func add(_ weight: Double) {
        if let index = self.weights.firstIndex(where: {$0 >= weight}) {
            if self.weights[index] != weight {            // ValidateFixedWeightRange allows overlapping ranges so we need to test for dupes
                self.weights.insert(weight, at: index)
                self.edited += 1
            }
        } else {
            self.weights.append(weight)
            self.edited += 1
        }
    }
    
    mutating func remove(at: Int) {
        self.weights.remove(at: at)
        self.edited += 1
    }
    
    var count: Int {
        get {return self.weights.count}
    }
    
    var editedCount: Int {
        get {return self.edited}
    }
    
    // Weights are guaranteed to be sorted.
    subscript(index: Int) -> Double {
        get {
            return self.weights[index]
        }
    }
    
    var first: Double? {
        return self.weights.first
    }
    
    var last: Double? {
        return self.weights.last
    }
    
    func firstIndex(where predicate: (Double) -> Bool) -> Int? {
        return self.weights.firstIndex(where: predicate)
    }
    
    func makeIterator() -> Array<Double>.Iterator {
        return self.weights.makeIterator()
    }

    func subsets(sizeLE: Int, allowEmpty: Bool) -> [[Double]] {
        var result: [[Double]] = []
        self.weights.subsets(sizeLE: sizeLE, allowEmpty: allowEmpty, {result.append($0)})
        return result
    }

    static func ==(lhs: FixedWeights, rhs: FixedWeights) -> Bool {
        return lhs.weights == rhs.weights
    }
    
    private var weights: [Double]
    private var edited = 0
}

/// List of arbitrary weights, e.g. for dumbbells or a cable machine.
class FixedWeightSet: Equatable, Storable {
    var weights: FixedWeights
    var extra: FixedWeights     // TODO: should we support multiples of the same extra weight? maybe by allowing duplicate weights in the list? people could just explicity add the duplicate (eg add a 5.0 extra for two 2.5 extras)
    var extraAdds: Int          // number of extra weights that can be added to the main weight

    init() {
        self.weights = FixedWeights()
        self.extra = FixedWeights()
        self.extraAdds = 1
    }
    
    init(_ weights: [Double], extra: [Double] = [], extraAdds: Int = 1) {
        self.weights = FixedWeights(weights)
        self.extra = FixedWeights(extra)
        self.extraAdds = extraAdds
    }
    
    required init(from store: Store) {
        self.weights = store.getObj("weights")
        self.extra = store.getObj("extra")
        self.extraAdds = store.getInt("extraAdds")
    }

    func save(_ store: Store) {
        store.addObj("weights", weights)
        store.addObj("extra", extra)
        store.addInt("extraAdds", extraAdds)
    }

    func clone() -> FixedWeightSet {
        let store = Store()
        store.addObj("self", self)
        let result: FixedWeightSet = store.getObj("self")
        return result
    }

    static func ==(lhs: FixedWeightSet, rhs: FixedWeightSet) -> Bool {
        return lhs.weights == rhs.weights && lhs.extra == rhs.extra && lhs.extraAdds == rhs.extraAdds
    }
    
    func getClosest(_ target: Double) -> ActualWeights {
        let below = self.getClosestBelow(target)
        let above = self.getClosestAbove(target)
        if above != nil {
            if abs(below.total - target) <= abs(above!.total - target) {
                return below
            } else {
                return above!
            }
        } else {
            return below
        }
    }
    
    func getAll() -> [ActualWeights] {
        if self.cachedWeights != self.weights.editedCount || self.cachedExtra != self.extra.editedCount || self.cachedCount != self.extraAdds {
            self.cache = []
            
            let subsets = self.extra.subsets(sizeLE: self.extraAdds, allowEmpty: true)
            for weight in self.weights {
                for subset in subsets {
                    let total = weight + subset.reduce(0.0, {$0 + $1})
                    if let index = cache.firstIndex(where: {sameWeight($0.total, total)}) {
                        if cache[index].weights.count > subset.count + 1 {
                            // We've found a simpler configuration for this weight.
                            cache.remove(at: index)
                            
                            let fixed = [ActualWeight(weight: weight, label: "")]
                            let extra = subset.sorted(by: {$0 > $1}).map({ActualWeight(weight: $0, label: "extra")})
                            cache.insert(ActualWeights(total: total, weights: fixed + extra), at: index)
                        }
                    } else {
                        // We've found a brand new weight.
                        let fixed = [ActualWeight(weight: weight, label: "")]
                        let extra = subset.sorted(by: {$0 > $1}).map({ActualWeight(weight: $0, label: "extra")})
                        cache.append(ActualWeights(total: total, weights: fixed + extra))
                    }
                }
            }
            
            // Cache is sorted from smallest to largest but the extra field is largest to smallest (looks nicer when displaying it to the user).
            self.cache.sort(by: {$0.total < $1.total})

            self.cachedWeights = self.weights.editedCount
            self.cachedExtra = self.extra.editedCount
            self.cachedCount = self.extraAdds
        }
        
        return self.cache
    }
    
    // Equal or below.
    func getClosestBelow(_ target: Double) -> ActualWeights {
        let all = self.getAll()
        for candidate in all.reversed() {
            if candidate.total <= target {
                return candidate
            }
        }
        
        return ActualWeights(total: 0.0, weights: [ActualWeight(weight: 0.0, label: "")])
    }
    
    // Equal or above.
    func getClosestAbove(_ target: Double) -> ActualWeights? {
        let all = self.getAll()
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
    func getBelow(_ weight: Double) -> ActualWeights {
        return self.getClosestBelow(weight - epsilonWeight)
    }

    // Next weight above specified weight
    func getAbove(_ weight: Double) -> ActualWeights? {
        return self.getClosestAbove(weight + epsilonWeight)
    }
    
    private var cachedWeights = -1
    private var cachedExtra = -1
    private var cachedCount = -1
    private var cache: [ActualWeights] = []
}
