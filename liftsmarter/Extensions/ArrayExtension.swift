//  Created by Jesse Vorisek on 9/12/21.
import Foundation

extension Array {
    func at(_ i: Int) -> Element? {
        return i < self.count ? self[i] : nil
    }
    
    func duplicate(x: Int) -> [Element] {
        var result: [Element] = []
        result.reserveCapacity(self.count * x)
        
        for _ in 0..<x {
            result.append(contentsOf: self)
        }
        
        return result
    }
}

func zip3<A, B, C>(_ a1: Array<A>, _ a2: Array<B>, _ a3: Array<C>) -> Array<(A, B, C)> {
    ASSERT(a1.count == a2.count && a1.count == a3.count, "counts must match")
    
    var result = Array<(A, B, C)>()
    result.reserveCapacity(a1.count)
    for i in 0..<a1.count {
        result.append((a1[i], a2[i], a3[i]))
    }
    
    return result
}
