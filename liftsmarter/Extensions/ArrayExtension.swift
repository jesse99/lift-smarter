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
