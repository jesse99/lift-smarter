//  Created by Jesse Vorisek on 10/5/21.
import Foundation

let epsilonWeight = 0.001   // a weight smaller than any real weight

struct ActualWeights {
    let total: Double       // often sum of weights below but will also include stuff like barbell weight if that's being used
    let weights: [Double]   // for fixed weight sets this will have one entry, for plates it'll be something like [45. 25]
    let extra: [Double]     // often empty, otherwise something like [2.5, 1.25]
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
            }
        } else {
            self.weights.append(weight)
        }
    }
    
    mutating func remove(at: Int) {
        self.weights.remove(at: at)
    }
    
    var count: Int {
        get {return self.weights.count}
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

    static func ==(lhs: FixedWeights, rhs: FixedWeights) -> Bool {
        return lhs.weights == rhs.weights
    }
    
    private var weights: [Double]
}

/// List of arbitrary weights, e.g. for dumbbells or a cable machine.
struct FixedWeightSet: Equatable, Storable {
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
    
    init(from store: Store) {
        self.weights = store.getObj("weights")
        self.extra = store.getObj("extra")
        self.extraAdds = store.getInt("extraAdds")
    }

    func save(_ store: Store) {
        store.addObj("weights", weights)
        store.addObj("extra", extra)
        store.addInt("extraAdds", extraAdds)
    }

    static func ==(lhs: FixedWeightSet, rhs: FixedWeightSet) -> Bool {
        return lhs.weights == rhs.weights && lhs.extra == rhs.extra && lhs.extraAdds == rhs.extraAdds
    }
    
    func getClosest(_ target: Double) -> Double {
        let below = self.getClosestBelow(target)
        let above = self.getClosestAbove(target)
        if above != nil {
            if abs(below - target) <= abs(above! - target) {
                return below
            } else {
                return above!
            }
        } else {
            return below
        }
    }
    
    func getAll() -> [Double] {
        return self.weights.map({$0})
    }
    
    // TODO:
    // for getClosestAbove
    //    find the last weight <= target               don't think this quite works with large extra weights
    //    if equal then return it
    //    if can add extra and get >=target then use that (skip any that wind up larger than next weight)
    //    use the next weight
    //
    // build up a list of weight combos
    // include a list of extras
    // return the closest with the smallest number of extras
    //
    // could keep a cache (valid of FixedWeight edit counts and extraAdds matches cached)
    // cache would be ActualWeights sorted by total and them extra.count
    
    // Equal or below.
    func getClosestBelow(_ target: Double) -> Double {
        for candidate in self.weights.reversed() {
            if candidate <= target {
                return candidate
            }
        }
        
        return 0.0
    }
    
    // Equal or above.
    func getClosestAbove(_ target: Double) -> Double? {
        for candidate in self.weights {
            if candidate >= target {
                return candidate
            }
        }
        
        return self.weights.last
    }
    
    // Next weight below specified weight
    func getBelow(_ weight: Double) -> Double {
        return self.getClosestBelow(weight - epsilonWeight)
    }

    // Next weight above specified weight
    func getAbove(_ weight: Double) -> Double? {
        return self.getClosestAbove(weight + epsilonWeight)
    }
}
