//  Created by Jesse Jones on 9/9/21.
import XCTest
@testable import liftsmarter

class FixedWeightSetTests: XCTestCase {
    func testBasics() throws {
        let fws = FixedWeightSet([5, 10, 20, 25, 35])
        
        XCTAssertEqual(fws.getClosestBelow(0.0), 0.0)   // getClosestBelow are the key functions
        XCTAssertEqual(fws.getClosestBelow(4.0), 0.0)   // equal or below
        XCTAssertEqual(fws.getClosestBelow(5.0), 5.0)
        XCTAssertEqual(fws.getClosestBelow(9.0), 5.0)
        XCTAssertEqual(fws.getClosestBelow(40.0), 35.0)

        XCTAssertEqual(fws.getClosestAbove(0.0), 5.0)
        XCTAssertEqual(fws.getClosestAbove(4.0), 5.0)
        XCTAssertEqual(fws.getClosestAbove(5.0), 5.0)
        XCTAssertEqual(fws.getClosestAbove(9.0), 10.0)
        XCTAssertEqual(fws.getClosestAbove(40.0), 35.0)

        XCTAssertEqual(fws.getBelow(0.0), 0.0)          // these need minimal testing
        XCTAssertEqual(fws.getBelow(4.0), 0.0)          // below
        XCTAssertEqual(fws.getBelow(5.0), 0.0)
        XCTAssertEqual(fws.getBelow(5.1), 5.0)
        XCTAssertEqual(fws.getBelow(9.0), 5.0)
        XCTAssertEqual(fws.getBelow(40.0), 35.0)

        XCTAssertEqual(fws.getAbove(0.0), 5.0)
        XCTAssertEqual(fws.getAbove(4.0), 5.0)
        XCTAssertEqual(fws.getAbove(5.0), 10.0)
        XCTAssertEqual(fws.getAbove(9.0), 10.0)
        XCTAssertEqual(fws.getAbove(40.0), 35.0)
    }

    func testOneExtra() throws {
        let fws = FixedWeightSet([5, 10, 20, 25, 35], extra: [2.0, 3.0], extraAdds: 1)
        
        XCTAssertEqual(fws.getClosestBelow(2.0), 0.0)
        XCTAssertEqual(fws.getClosestBelow(10.0), 10.0)
        XCTAssertEqual(fws.getClosestBelow(12.0), 12.0)
        XCTAssertEqual(fws.getClosestBelow(13.0), 13.0)
        XCTAssertEqual(fws.getClosestBelow(14.0), 13.0)
        XCTAssertEqual(fws.getClosestBelow(15.0), 13.0)
        XCTAssertEqual(fws.getClosestBelow(40.0), 38.0)

        XCTAssertEqual(fws.getClosestAbove(2.0), 5.0)
        XCTAssertEqual(fws.getClosestAbove(10.0), 10.0)
        XCTAssertEqual(fws.getClosestAbove(12.0), 12.0)
        XCTAssertEqual(fws.getClosestAbove(13.0), 13.0)
        XCTAssertEqual(fws.getClosestAbove(14.0), 20.0)
        XCTAssertEqual(fws.getClosestAbove(15.0), 20.0)
        XCTAssertEqual(fws.getClosestAbove(40.0), 38.0)
    }

    func testTwoExtra() throws {
        let fws = FixedWeightSet([5, 10, 20, 25, 35], extra: [2.0, 3.0], extraAdds: 2)
        
        XCTAssertEqual(fws.getClosestBelow(2.0), 0.0)
        XCTAssertEqual(fws.getClosestBelow(10.0), 10.0)
        XCTAssertEqual(fws.getClosestBelow(12.0), 12.0)
        XCTAssertEqual(fws.getClosestBelow(13.0), 13.0)
        XCTAssertEqual(fws.getClosestBelow(14.0), 13.0)
        XCTAssertEqual(fws.getClosestBelow(15.0), 15.0)
        XCTAssertEqual(fws.getClosestBelow(40.0), 40.0)

        XCTAssertEqual(fws.getClosestAbove(2.0), 5.0)
        XCTAssertEqual(fws.getClosestAbove(10.0), 10.0)
        XCTAssertEqual(fws.getClosestAbove(12.0), 12.0)
        XCTAssertEqual(fws.getClosestAbove(13.0), 13.0)
        XCTAssertEqual(fws.getClosestAbove(14.0), 15.0)
        XCTAssertEqual(fws.getClosestAbove(15.0), 15.0)
        XCTAssertEqual(fws.getClosestAbove(40.0), 40.0)
    }

    func testLargeExtra() throws {
        let fws = FixedWeightSet([10, 20, 30, 40], extra: [3.0, 4.0, 8.0], extraAdds: 2)  // seems unlikely that this would actually happen
        
        XCTAssertEqual(fws.getClosestBelow(2.0), 0.0)
        XCTAssertEqual(fws.getClosestBelow(8.0), 0.0)
        XCTAssertEqual(fws.getClosestBelow(9.0), 0.0)
        XCTAssertEqual(fws.getClosestBelow(10.0), 10.0)
        XCTAssertEqual(fws.getClosestBelow(12.0), 10.0)
        XCTAssertEqual(fws.getClosestBelow(13.0), 13.0)
        XCTAssertEqual(fws.getClosestBelow(14.0), 14.0)
        XCTAssertEqual(fws.getClosestBelow(15.0), 14.0)
        XCTAssertEqual(fws.getClosestBelow(17.0), 17.0)
        XCTAssertEqual(fws.getClosestBelow(18.0), 18.0)
        XCTAssertEqual(fws.getClosestBelow(21.0), 20.0)
        XCTAssertEqual(fws.getClosestBelow(22.0), 22.0)
        XCTAssertEqual(fws.getClosestBelow(60.0), 52.0)

        XCTAssertEqual(fws.getClosestAbove(2.0), 10.0)
        XCTAssertEqual(fws.getClosestAbove(8.0), 10.0)
        XCTAssertEqual(fws.getClosestAbove(9.0), 10.0)
        XCTAssertEqual(fws.getClosestAbove(10.0), 10.0)
        XCTAssertEqual(fws.getClosestAbove(12.0), 13.0)
        XCTAssertEqual(fws.getClosestAbove(13.0), 13.0)
        XCTAssertEqual(fws.getClosestAbove(14.0), 14.0)
        XCTAssertEqual(fws.getClosestAbove(15.0), 17.0)
        XCTAssertEqual(fws.getClosestAbove(17.0), 17.0)
        XCTAssertEqual(fws.getClosestBelow(18.0), 18.0)
        XCTAssertEqual(fws.getClosestBelow(21.0), 22.0)
        XCTAssertEqual(fws.getClosestBelow(22.0), 22.0)
        XCTAssertEqual(fws.getClosestBelow(60.0), 52.0)
    }
}
