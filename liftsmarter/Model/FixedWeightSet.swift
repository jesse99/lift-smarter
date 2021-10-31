//  Created by Jesse Vorisek on 10/5/21.
import Foundation

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
    var extra: FixedWeights
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
    
    // Equal or below.
    func getClosestBelow(_ target: Double) -> Double {
        if let index = self.weights.firstIndex(where: {$0 >= target}) {
            if self.weights[index] == target {
                return self.weights[index]
            } else if index > 0 {
                return self.weights[index - 1]
            }
        }
        if let last = self.weights.last, last < target {
            return last
        }
        return 0.0
    }
    
    // Equal or above.
    func getClosestAbove(_ target: Double) -> Double? {
        if let index = self.weights.firstIndex(where: {$0 >= target}) {
            return self.weights[index]
        } else {
            if let last = self.weights.last, last < target {
                return last
            }
            return nil
        }
    }
    
    // Next weight below specified weight (weight should be in fws).
    func getBelow(_ weight: Double) -> Double? {
        if let index = self.weights.firstIndex(where: {$0 == weight}) {
            if index > 0 {
                return self.weights[index - 1]
            }
        }
        return nil
    }

    // Next weight above specified weight (weight should be zero or in fws).
    func getAbove(_ weight: Double) -> Double? {
        if let index = self.weights.firstIndex(where: {$0 == weight}) {
            if index + 1 < self.weights.count {
                return self.weights[index + 1]
            }
        }
        if let first = self.weights.first, weight < first {
            return first
        }
        return nil
    }
}
