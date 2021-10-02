//  Created by Jesse Vorisek on 9/26/21.
import XCTest
@testable import liftsmarter

class ScheduleTests: XCTestCase {
    let formatter = DateFormatter()
    
    var mobility: Workout!
    var lower: Workout!
    var upper: Workout!
    var model: Model!
    var vm: ProgramVM!
    
    override func setUp() {
        self.formatter.dateFormat = "yyyy/MM/dd HH:mm"

        self.mobility = Workout("Mobility", [], schedule: .anyDay)
        self.lower = Workout("Lower", [], schedule: .days([.monday, .wednesday, .friday]))
        self.upper = Workout("Upper",[], schedule: .cyclic(2))

        let workouts = [mobility!, lower!, upper!]
        let exercises: [Exercise] = []
        let program = Program("Home", workouts, exercises, weeksStart: Date())
        self.model = Model(program)
        self.vm = ProgramVM(self.model)

        program.weeksStart = self.date(minutes: 0)
    }
    
    func testWeeksBetween() throws {
        XCTAssertEqual(weeksBetween(from: self.model.program.weeksStart, to: date(day: 1)), 0)
        XCTAssertEqual(weeksBetween(from: self.model.program.weeksStart, to: date(month: 10)), 4)
        XCTAssertEqual(weeksBetween(from: self.model.program.weeksStart, to: date(month: 11)), 9)
        XCTAssertEqual(weeksBetween(from: self.model.program.weeksStart, to: date(month: 11, day: 2)), 9)
        XCTAssertEqual(weeksBetween(from: self.model.program.weeksStart, to: date(month: 11, day: 3)), 9)
        XCTAssertEqual(weeksBetween(from: self.model.program.weeksStart, to: date(month: 11, day: 30)), 13)
        XCTAssertEqual(weeksBetween(from: self.model.program.weeksStart, to: date(month: 12)), 13)
        XCTAssertEqual(weeksBetween(from: self.model.program.weeksStart, to: date(month: 12, day: 30)), 17)
        XCTAssertEqual(weeksBetween(from: self.model.program.weeksStart, to: date(year: 2022, month: 1, day: 1)), 17)
        XCTAssertEqual(weeksBetween(from: self.model.program.weeksStart, to: date(year: 2022, month: 1, day: 2)), 18)
        XCTAssertEqual(weeksBetween(from: self.model.program.weeksStart, to: date(year: 2022, month: 1, day: 10)), 19)
    }
    
    func testProgramWeeks() throws {
        // No workouts use .weeks.
        XCTAssertEqual(vm.getWeek(date()), 1)
        XCTAssertEqual(vm.getWeek(date(day: 8)), 1)
        
        // All the workouts use .weeks(1).
        mobility.schedule = .weeks([1], .days([.monday]))
        lower.schedule = .weeks([1], .days([.tuesday]))
        upper.schedule = .weeks([1], .days([.wednesday]))
        XCTAssertEqual(vm.getWeek(date()), 1)
        XCTAssertEqual(vm.getWeek(date(day: 8)), 1)
        
        // Workouts use weeks 1, 2, and 3.
        mobility.schedule = .weeks([1], .days([.monday]))
        lower.schedule = .weeks([2], .days([.tuesday]))
        upper.schedule = .weeks([3], .days([.wednesday]))
        XCTAssertEqual(vm.getWeek(date()), 1)
        XCTAssertEqual(vm.getWeek(date(day: 4)), 1)
        XCTAssertEqual(vm.getWeek(date(day: 5)), 2)     // weeks start with Sunday
        XCTAssertEqual(vm.getWeek(date(day: 11)), 2)
        XCTAssertEqual(vm.getWeek(date(day: 15)), 3)
        XCTAssertEqual(vm.getWeek(date(day: 22)), 1)
        XCTAssertEqual(vm.getWeek(date(day: 29)), 2)

        // Workouts use weeks 1, 2, and 4. There shouldn't be anything special about this other than no workouts
        // are scheduled for week 3,
        mobility.schedule = .weeks([1], .days([.monday]))
        lower.schedule = .weeks([2], .days([.tuesday]))
        upper.schedule = .weeks([4], .days([.wednesday]))
        XCTAssertEqual(vm.getWeek(date()), 1)
        XCTAssertEqual(vm.getWeek(date(day: 4)), 1)
        XCTAssertEqual(vm.getWeek(date(day: 5)), 2)
        XCTAssertEqual(vm.getWeek(date(day: 11)), 2)
        XCTAssertEqual(vm.getWeek(date(day: 15)), 3)
        XCTAssertEqual(vm.getWeek(date(day: 22)), 4)
        XCTAssertEqual(vm.getWeek(date(day: 29)), 1)
        
        // Week setting and week getting should be consistent
        vm.setWeek(4, date(day: 8))
        XCTAssertEqual(vm.getWeek(date(day: 8)), 4)

        vm.setWeek(3, date(day: 10))
        XCTAssertEqual(vm.getWeek(date(day: 10)), 3)
        XCTAssertEqual(vm.getWeek(date(day: 21)), 1)

        vm.setWeek(1, date(day: 12))
        XCTAssertEqual(vm.getWeek(date(day: 12)), 1)
        XCTAssertEqual(vm.getWeek(date(day: 21)), 2)
        
        // Year boundary
        XCTAssertEqual(vm.getWeek(date(month: 12, day: 30)), 4)
        XCTAssertEqual(vm.getWeek(date(year: 2022, month: 1, day: 1)), 4)
        XCTAssertEqual(vm.getWeek(date(year: 2022, month: 1, day: 2)), 1)
    }
        
    private func date(year: Int = 2021, month: Int = 9, day: Int = 1, minutes: Int = 1) -> Date {
        return self.formatter.date(from: "\(year)/\(month)/\(day) 09:\(minutes)")!
    }
}
