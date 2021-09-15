//  Created by Jesse Jones on 9/9/21.
import XCTest
@testable import liftsmarter

class ModelTests: XCTestCase {
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testMocks() throws {
        // Verify that no asserts fire when constructing mock model.
        let model = mockModel()
        XCTAssert(!model.program.name.isEmpty)
    }

    func testPerformanceExample() throws {
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
