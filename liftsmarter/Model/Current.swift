//  Created by Jesse Vorisek on 9/9/21.
import Foundation

enum ActualRep {
    case reps(count: Int, percent: Double)

    case duration(secs: Int, percent: Double)
}

/// Where the user is now with respect to an Exercise. 
final class Current {
    var startDate: Date       // date exercise was started
    var weight: Double        // may be 0.0, this is from expected.weight
    var setIndex: Int         // if this is sets.count then the user has finished those sets
    var reps: [ActualRep]     // what the user has done so far, does not include warmup or backup sets
    
    init() {
        self.startDate = Date.distantPast
        self.weight = 0.0
        self.setIndex = 0
        self.reps = []
    }
    
    init(weight: Double) {
        self.startDate = Date()
        self.weight = weight
        self.setIndex = 0
        self.reps = []
    }
}
