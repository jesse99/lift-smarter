//  Created by Jesse Jones on 9/9/21.
import XCTest
@testable import liftsmarter

class BellsSetTests: XCTestCase {
    func testSubsets1() throws {
        let bells = Bells([10, 20], extra: [2.0, 3.0], extraAdds: 1)
        
        let actuals = bells.getAll()
        let weights = actuals.map({$0.total})
        
        XCTAssertEqual(weights[0], 10.0)
        XCTAssertEqual(weights[1], 12.0)
        XCTAssertEqual(weights[2], 13.0)
        XCTAssertEqual(weights[3], 20.0)
        XCTAssertEqual(weights[4], 22.0)
        XCTAssertEqual(weights[5], 23.0)
    }

    func testSubsets2() throws {
        let bells = Bells([10, 20], extra: [2.0, 3.0], extraAdds: 2)
        
        let actuals = bells.getAll()
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
        let bells = Bells([10, 20], extra: [2.0, 3.0, 4.0, 5.0], extraAdds: 3)
        
        let actuals = bells.getAll()
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
        let bells = Bells([5, 10, 20, 25, 35])
        
        XCTAssertEqual(bells.getClosestBelow(0.0).total, 0.0)   // getClosestBelow are the key functions
        XCTAssertEqual(bells.getClosestBelow(4.0).total, 0.0)   // equal or below
        XCTAssertEqual(bells.getClosestBelow(5.0).total, 5.0)
        XCTAssertEqual(bells.getClosestBelow(9.0).total, 5.0)
        XCTAssertEqual(bells.getClosestBelow(40.0).total, 35.0)

        XCTAssertEqual(bells.getClosestAbove(0.0)!.total, 5.0)
        XCTAssertEqual(bells.getClosestAbove(4.0)!.total, 5.0)
        XCTAssertEqual(bells.getClosestAbove(5.0)!.total, 5.0)
        XCTAssertEqual(bells.getClosestAbove(9.0)!.total, 10.0)
        XCTAssertEqual(bells.getClosestAbove(40.0)!.total, 35.0)

        XCTAssertEqual(bells.getBelow(0.0).total, 0.0)          // these need minimal testing
        XCTAssertEqual(bells.getBelow(4.0).total, 0.0)          // below
        XCTAssertEqual(bells.getBelow(5.0).total, 0.0)
        XCTAssertEqual(bells.getBelow(5.1).total, 5.0)
        XCTAssertEqual(bells.getBelow(9.0).total, 5.0)
        XCTAssertEqual(bells.getBelow(40.0).total, 35.0)

        XCTAssertEqual(bells.getAbove(0.0)!.total, 5.0)
        XCTAssertEqual(bells.getAbove(4.0)!.total, 5.0)
        XCTAssertEqual(bells.getAbove(5.0)!.total, 10.0)
        XCTAssertEqual(bells.getAbove(9.0)!.total, 10.0)
        XCTAssertEqual(bells.getAbove(40.0)!.total, 35.0)
    }

    func testOneExtra() throws {
        let bells = Bells([5, 10, 20, 25, 35], extra: [2.0, 3.0], extraAdds: 1)
        
        XCTAssertEqual(bells.getClosestBelow(2.0).total, 0.0)
        XCTAssertEqual(bells.getClosestBelow(10.0).total, 10.0)
        XCTAssertEqual(bells.getClosestBelow(12.0).total, 12.0)
        XCTAssertEqual(bells.getClosestBelow(13.0).total, 13.0)
        XCTAssertEqual(bells.getClosestBelow(14.0).total, 13.0)
        XCTAssertEqual(bells.getClosestBelow(15.0).total, 13.0)
        XCTAssertEqual(bells.getClosestBelow(40.0).total, 38.0)

        XCTAssertEqual(bells.getClosestAbove(2.0)!.total, 5.0)
        XCTAssertEqual(bells.getClosestAbove(10.0)!.total, 10.0)
        XCTAssertEqual(bells.getClosestAbove(12.0)!.total, 12.0)
        XCTAssertEqual(bells.getClosestAbove(13.0)!.total, 13.0)
        XCTAssertEqual(bells.getClosestAbove(14.0)!.total, 20.0)
        XCTAssertEqual(bells.getClosestAbove(15.0)!.total, 20.0)
        XCTAssertEqual(bells.getClosestAbove(40.0)!.total, 38.0)
    }

    func testTwoExtra() throws {
        let bells = Bells([5, 10, 20, 25, 35], extra: [2.0, 3.0], extraAdds: 2)
        
        XCTAssertEqual(bells.getClosestBelow(2.0).total, 0.0)
        XCTAssertEqual(bells.getClosestBelow(10.0).total, 10.0)
        XCTAssertEqual(bells.getClosestBelow(12.0).total, 12.0)
        XCTAssertEqual(bells.getClosestBelow(13.0).total, 13.0)
        XCTAssertEqual(bells.getClosestBelow(14.0).total, 13.0)
        XCTAssertEqual(bells.getClosestBelow(15.0).total, 15.0)
        XCTAssertEqual(bells.getClosestBelow(40.0).total, 40.0)

        XCTAssertEqual(bells.getClosestAbove(2.0)!.total, 5.0)
        XCTAssertEqual(bells.getClosestAbove(10.0)!.total, 10.0)
        XCTAssertEqual(bells.getClosestAbove(12.0)!.total, 12.0)
        XCTAssertEqual(bells.getClosestAbove(13.0)!.total, 13.0)
        XCTAssertEqual(bells.getClosestAbove(14.0)!.total, 15.0)
        XCTAssertEqual(bells.getClosestAbove(15.0)!.total, 15.0)
        XCTAssertEqual(bells.getClosestAbove(40.0)!.total, 40.0)
    }

    func testLargeExtra() throws {
        let bells = Bells([10, 20, 30, 40], extra: [3.0, 4.0, 8.0], extraAdds: 2)  // seems unlikely that this would actually happen
        
        XCTAssertEqual(bells.getClosestBelow(2.0).total, 0.0)
        XCTAssertEqual(bells.getClosestBelow(8.0).total, 0.0)
        XCTAssertEqual(bells.getClosestBelow(9.0).total, 0.0)
        XCTAssertEqual(bells.getClosestBelow(10.0).total, 10.0)
        XCTAssertEqual(bells.getClosestBelow(12.0).total, 10.0)
        XCTAssertEqual(bells.getClosestBelow(13.0).total, 13.0)
        XCTAssertEqual(bells.getClosestBelow(14.0).total, 14.0)
        XCTAssertEqual(bells.getClosestBelow(15.0).total, 14.0)
        XCTAssertEqual(bells.getClosestBelow(17.0).total, 17.0)
        XCTAssertEqual(bells.getClosestBelow(18.0).total, 18.0)
        XCTAssertEqual(bells.getClosestBelow(21.0).total, 21.0)
        XCTAssertEqual(bells.getClosestBelow(22.0).total, 22.0)
        XCTAssertEqual(bells.getClosestBelow(60.0).total, 52.0)

        XCTAssertEqual(bells.getClosestAbove(2.0)!.total, 10.0)
        XCTAssertEqual(bells.getClosestAbove(8.0)!.total, 10.0)
        XCTAssertEqual(bells.getClosestAbove(9.0)!.total, 10.0)
        XCTAssertEqual(bells.getClosestAbove(10.0)!.total, 10.0)
        XCTAssertEqual(bells.getClosestAbove(12.0)!.total, 13.0)
        XCTAssertEqual(bells.getClosestAbove(13.0)!.total, 13.0)
        XCTAssertEqual(bells.getClosestAbove(14.0)!.total, 14.0)
        XCTAssertEqual(bells.getClosestAbove(15.0)!.total, 17.0)
        XCTAssertEqual(bells.getClosestAbove(17.0)!.total, 17.0)
        XCTAssertEqual(bells.getClosestAbove(18.0)!.total, 18.0)
        XCTAssertEqual(bells.getClosestAbove(21.0)!.total, 21.0)
        XCTAssertEqual(bells.getClosestAbove(22.0)!.total, 22.0)
        XCTAssertEqual(bells.getClosestAbove(60.0)!.total, 52.0)
    }
}
