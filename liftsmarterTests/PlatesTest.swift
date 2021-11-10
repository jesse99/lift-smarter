//  Created by Jesse Vorisek on 11/8/21.
import XCTest
@testable import liftsmarter

class PlatesTests: XCTestCase {
    func testBasics1() throws {
        let plates = Plates([
            Plate(weight: 45, count: 2, type: .standard),
            Plate(weight: 35, count: 2, type: .standard),
            Plate(weight: 25, count: 2, type: .standard),
            Plate(weight: 10, count: 2, type: .standard),
            Plate(weight: 5, count: 2, type: .standard),
            Plate(weight: 1.25, count: 2, type: .magnet)
        ])
        
        let actuals = plates.getAll(dual: false)
        let weights = actuals.map({$0.total})

        XCTAssertEqual(weights[0], 5.0)
        XCTAssertEqual(weights[1], 6.25)
        XCTAssertEqual(weights[2], 7.5)
        XCTAssertEqual(weights[3], 10.0)
        XCTAssertEqual(weights[4], 11.25)
        XCTAssertEqual(weights[5], 12.5)
        XCTAssertEqual(weights.last!, 45 + 45 + 35 + 35 + 25 + 25 + 10 + 10 + 5 + 5 + 1.25 + 1.25)
    }
    
    func testBasics2() throws {
        let plates = Plates([
            Plate(weight: 45, count: 4, type: .standard),
            Plate(weight: 35, count: 4, type: .standard),
            Plate(weight: 25, count: 4, type: .standard),
            Plate(weight: 10, count: 4, type: .standard),
            Plate(weight: 5, count: 4, type: .standard),
            Plate(weight: 1.25, count: 4, type: .magnet)
        ])
        
        let actuals = plates.getAll(dual: true)
        let weights = actuals.map({$0.total})

        XCTAssertEqual(weights[0], 10.0)
        XCTAssertEqual(weights[1], 12.5)
        XCTAssertEqual(weights[2], 15.0)
        XCTAssertEqual(weights[3], 20.0)
        XCTAssertEqual(weights[4], 22.5)
        XCTAssertEqual(weights[5], 25.0)
        XCTAssertEqual(weights.last!, 2.0*(45 + 45 + 35 + 35 + 25 + 25 + 10 + 10 + 5 + 5 + 1.25 + 1.25))
    }
    
    func testSimplest() throws {
        let plates = Plates([
            Plate(weight: 45, count: 2, type: .standard),
            Plate(weight: 35, count: 2, type: .standard),
            Plate(weight: 25, count: 2, type: .standard),
            Plate(weight: 10, count: 4, type: .standard),
            Plate(weight: 5, count: 4, type: .standard),
            Plate(weight: 1.25, count: 2, type: .magnet)
        ])
        
        let actuals = plates.getAll(dual: false)
        let weights = actuals.map({$0.total})
        let labels = actuals.map({self.label($0.weights)})

        XCTAssertEqual(weights[30], 55.0)
        XCTAssertEqual(labels[30], "45 + 10")
        
        XCTAssertEqual(weights[35], 62.5)
        XCTAssertEqual(labels[35], "35 + 25 + 1.25 magnet + 1.25 magnet")

        XCTAssertEqual(weights[45], 80.0)
        XCTAssertEqual(labels[45], "45 + 35")

        XCTAssertEqual(weights[55], 96.25)
        XCTAssertEqual(labels[55], "35 + 35 + 25 + 1.25 magnet")
    }
    
    func testBumpers() throws {
        let plates = Plates([
            Plate(weight: 45, count: 2, type: .standard),
            Plate(weight: 35, count: 2, type: .standard),
            Plate(weight: 25, count: 4, type: .bumper),
            Plate(weight: 10, count: 4, type: .standard),
            Plate(weight: 5, count: 4, type: .standard),
            Plate(weight: 1.25, count: 2, type: .magnet)
        ])
        
        let actuals = plates.getAll(dual: false)
        let weights = actuals.map({$0.total})
        let labels = actuals.map({self.label($0.weights)})

        XCTAssertEqual(weights[30], 55.0)
        XCTAssertEqual(labels[30], "25 bumper + 25 bumper + 5")
        
        XCTAssertEqual(weights[35], 62.5)
        XCTAssertEqual(labels[35], "25 bumper + 25 bumper + 10 + 1.25 magnet + 1.25 magnet")

        XCTAssertEqual(weights[45], 80.0)
        XCTAssertEqual(labels[45], "25 bumper + 25 bumper + 25 bumper + 5")
    }

    private func label(_ actuals: [ActualWeight]) -> String {
        let parts: [String] = actuals.map({
            if $0.label.isEmpty {
                return friendlyWeight($0.weight)
            } else {
                return friendlyWeight($0.weight) + " " + $0.label
            }
        })
        return parts.joined(separator: " + ")
    }
}
