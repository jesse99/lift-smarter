//  Created by Jesse Jones on 9/9/21.
import XCTest
@testable import liftsmarter

class FixedWeightSetTests: XCTestCase {
    func testSubsets1() throws {
        let fws = FixedWeightSet([10, 20], extra: [2.0, 3.0], extraAdds: 1)
        
        let actuals = fws.getAll()
        let weights = actuals.map({$0.total})
        
        XCTAssertEqual(weights[0], 10.0)
        XCTAssertEqual(weights[1], 12.0)
        XCTAssertEqual(weights[2], 13.0)
        XCTAssertEqual(weights[3], 20.0)
        XCTAssertEqual(weights[4], 22.0)
        XCTAssertEqual(weights[5], 23.0)
    }

    func testSubsets2() throws {
        let fws = FixedWeightSet([10, 20], extra: [2.0, 3.0], extraAdds: 2)
        
        let actuals = fws.getAll()
        let weights = actuals.map({$0.total})
        
        XCTAssertEqual(weights[0], 10.0)
        XCTAssertEqual(weights[1], 12.0)
        XCTAssertEqual(weights[2], 13.0)
        XCTAssertEqual(weights[3], 15.0)
        XCTAssertEqual(weights[4], 20.0)
        XCTAssertEqual(weights[5], 22.0)
        XCTAssertEqual(weights[6], 23.0)
        XCTAssertEqual(weights[7], 25.0)
    }

    func testSubsets3() throws {
        let fws = FixedWeightSet([10, 20], extra: [2.0, 3.0, 4.0, 5.0], extraAdds: 3)
        
        let actuals = fws.getAll()
        let weights = actuals.map({$0.total})
        let counts = actuals.map({$0.weights.count})
        
        XCTAssertEqual(weights[0], 10.0)
        XCTAssertEqual(counts[0], 1)

        XCTAssertEqual(weights[1], 12.0)    // 1 extra
        XCTAssertEqual(weights[2], 13.0)
        XCTAssertEqual(weights[3], 14.0)
        XCTAssertEqual(weights[4], 15.0)
        XCTAssertEqual(counts[1], 2)
        XCTAssertEqual(counts[2], 2)
        XCTAssertEqual(counts[3], 2)
        XCTAssertEqual(counts[4], 2)

        XCTAssertEqual(weights[5], 16.0)    // 2 extra
        XCTAssertEqual(weights[6], 17.0)
        XCTAssertEqual(weights[7], 18.0)
        XCTAssertEqual(weights[8], 19.0)
        XCTAssertEqual(counts[5], 3)
        XCTAssertEqual(counts[6], 3)
        XCTAssertEqual(counts[7], 3)
        XCTAssertEqual(counts[8], 3)

        XCTAssertEqual(weights[9], 20.0)
        XCTAssertEqual(counts[9], 1)

        XCTAssertEqual(weights[10], 21.0)    // 3 extra
        XCTAssertEqual(weights[11], 22.0)
        // ...
        XCTAssertEqual(weights.last, 32.0)
        XCTAssertEqual(counts[10], 4)
        XCTAssertEqual(counts[11], 2)
        XCTAssertEqual(counts.last, 4)
    }

    func testBasics() throws {
        let fws = FixedWeightSet([5, 10, 20, 25, 35])
        
        XCTAssertEqual(fws.getClosestBelow(0.0).total, 0.0)   // getClosestBelow are the key functions
        XCTAssertEqual(fws.getClosestBelow(4.0).total, 0.0)   // equal or below
        XCTAssertEqual(fws.getClosestBelow(5.0).total, 5.0)
        XCTAssertEqual(fws.getClosestBelow(9.0).total, 5.0)
        XCTAssertEqual(fws.getClosestBelow(40.0).total, 35.0)

        XCTAssertEqual(fws.getClosestAbove(0.0)!.total, 5.0)
        XCTAssertEqual(fws.getClosestAbove(4.0)!.total, 5.0)
        XCTAssertEqual(fws.getClosestAbove(5.0)!.total, 5.0)
        XCTAssertEqual(fws.getClosestAbove(9.0)!.total, 10.0)
        XCTAssertEqual(fws.getClosestAbove(40.0)!.total, 35.0)

        XCTAssertEqual(fws.getBelow(0.0).total, 0.0)          // these need minimal testing
        XCTAssertEqual(fws.getBelow(4.0).total, 0.0)          // below
        XCTAssertEqual(fws.getBelow(5.0).total, 0.0)
        XCTAssertEqual(fws.getBelow(5.1).total, 5.0)
        XCTAssertEqual(fws.getBelow(9.0).total, 5.0)
        XCTAssertEqual(fws.getBelow(40.0).total, 35.0)

        XCTAssertEqual(fws.getAbove(0.0)!.total, 5.0)
        XCTAssertEqual(fws.getAbove(4.0)!.total, 5.0)
        XCTAssertEqual(fws.getAbove(5.0)!.total, 10.0)
        XCTAssertEqual(fws.getAbove(9.0)!.total, 10.0)
        XCTAssertEqual(fws.getAbove(40.0)!.total, 35.0)
    }

    func testOneExtra() throws {
        let fws = FixedWeightSet([5, 10, 20, 25, 35], extra: [2.0, 3.0], extraAdds: 1)
        
        XCTAssertEqual(fws.getClosestBelow(2.0).total, 0.0)
        XCTAssertEqual(fws.getClosestBelow(10.0).total, 10.0)
        XCTAssertEqual(fws.getClosestBelow(12.0).total, 12.0)
        XCTAssertEqual(fws.getClosestBelow(13.0).total, 13.0)
        XCTAssertEqual(fws.getClosestBelow(14.0).total, 13.0)
        XCTAssertEqual(fws.getClosestBelow(15.0).total, 13.0)
        XCTAssertEqual(fws.getClosestBelow(40.0).total, 38.0)

        XCTAssertEqual(fws.getClosestAbove(2.0)!.total, 5.0)
        XCTAssertEqual(fws.getClosestAbove(10.0)!.total, 10.0)
        XCTAssertEqual(fws.getClosestAbove(12.0)!.total, 12.0)
        XCTAssertEqual(fws.getClosestAbove(13.0)!.total, 13.0)
        XCTAssertEqual(fws.getClosestAbove(14.0)!.total, 20.0)
        XCTAssertEqual(fws.getClosestAbove(15.0)!.total, 20.0)
        XCTAssertEqual(fws.getClosestAbove(40.0)!.total, 38.0)
    }

    func testTwoExtra() throws {
        let fws = FixedWeightSet([5, 10, 20, 25, 35], extra: [2.0, 3.0], extraAdds: 2)
        
        XCTAssertEqual(fws.getClosestBelow(2.0).total, 0.0)
        XCTAssertEqual(fws.getClosestBelow(10.0).total, 10.0)
        XCTAssertEqual(fws.getClosestBelow(12.0).total, 12.0)
        XCTAssertEqual(fws.getClosestBelow(13.0).total, 13.0)
        XCTAssertEqual(fws.getClosestBelow(14.0).total, 13.0)
        XCTAssertEqual(fws.getClosestBelow(15.0).total, 15.0)
        XCTAssertEqual(fws.getClosestBelow(40.0).total, 40.0)

        XCTAssertEqual(fws.getClosestAbove(2.0)!.total, 5.0)
        XCTAssertEqual(fws.getClosestAbove(10.0)!.total, 10.0)
        XCTAssertEqual(fws.getClosestAbove(12.0)!.total, 12.0)
        XCTAssertEqual(fws.getClosestAbove(13.0)!.total, 13.0)
        XCTAssertEqual(fws.getClosestAbove(14.0)!.total, 15.0)
        XCTAssertEqual(fws.getClosestAbove(15.0)!.total, 15.0)
        XCTAssertEqual(fws.getClosestAbove(40.0)!.total, 40.0)
    }

    func testLargeExtra() throws {
        let fws = FixedWeightSet([10, 20, 30, 40], extra: [3.0, 4.0, 8.0], extraAdds: 2)  // seems unlikely that this would actually happen
        
        XCTAssertEqual(fws.getClosestBelow(2.0).total, 0.0)
        XCTAssertEqual(fws.getClosestBelow(8.0).total, 0.0)
        XCTAssertEqual(fws.getClosestBelow(9.0).total, 0.0)
        XCTAssertEqual(fws.getClosestBelow(10.0).total, 10.0)
        XCTAssertEqual(fws.getClosestBelow(12.0).total, 10.0)
        XCTAssertEqual(fws.getClosestBelow(13.0).total, 13.0)
        XCTAssertEqual(fws.getClosestBelow(14.0).total, 14.0)
        XCTAssertEqual(fws.getClosestBelow(15.0).total, 14.0)
        XCTAssertEqual(fws.getClosestBelow(17.0).total, 17.0)
        XCTAssertEqual(fws.getClosestBelow(18.0).total, 18.0)
        XCTAssertEqual(fws.getClosestBelow(21.0).total, 21.0)
        XCTAssertEqual(fws.getClosestBelow(22.0).total, 22.0)
        XCTAssertEqual(fws.getClosestBelow(60.0).total, 52.0)

        XCTAssertEqual(fws.getClosestAbove(2.0)!.total, 10.0)
        XCTAssertEqual(fws.getClosestAbove(8.0)!.total, 10.0)
        XCTAssertEqual(fws.getClosestAbove(9.0)!.total, 10.0)
        XCTAssertEqual(fws.getClosestAbove(10.0)!.total, 10.0)
        XCTAssertEqual(fws.getClosestAbove(12.0)!.total, 13.0)
        XCTAssertEqual(fws.getClosestAbove(13.0)!.total, 13.0)
        XCTAssertEqual(fws.getClosestAbove(14.0)!.total, 14.0)
        XCTAssertEqual(fws.getClosestAbove(15.0)!.total, 17.0)
        XCTAssertEqual(fws.getClosestAbove(17.0)!.total, 17.0)
        XCTAssertEqual(fws.getClosestAbove(18.0)!.total, 18.0)
        XCTAssertEqual(fws.getClosestAbove(21.0)!.total, 21.0)
        XCTAssertEqual(fws.getClosestAbove(22.0)!.total, 22.0)
        XCTAssertEqual(fws.getClosestAbove(60.0)!.total, 52.0)
    }
}
