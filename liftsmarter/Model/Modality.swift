//  Created by Jesse Vorisek on 9/9/21.
import Foundation

/// Defines how an exercise should be performed and what to do after completing the exercise.
/// In general all modality combinations make sense. The only exception I can think of is
/// untimed sets with progression.
class Modality {
    var apparatus: Apparatus
    var sets: Sets
//    var progression: Progression?
//    var advisor: Advisor?
    
    init(_ apparatus: Apparatus, _ sets: Sets) {
        self.apparatus = apparatus
        self.sets = sets
    }
}
