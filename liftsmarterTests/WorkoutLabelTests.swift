//  Created by Jesse Vorisek on 10/2/21.
import XCTest
@testable import liftsmarter

// Label is just the workout name so all we need to test here is the sub label.
class WorkoutLabelTests: XCTestCase {
    let formatter = DateFormatter()
    
    var mobility: Workout!
    var empty: Workout!
    var allDisabled: Workout!
    var lower: Workout!
    var model: Model!
    var vm: ProgramVM!
    
    override func setUp() {
        self.formatter.dateFormat = "yyyy/MM/dd HH:mm"

        let exercises: [Exercise] = [   // modality type doesn't matter for these tests
            Exercise("Squat", "Squat", Modality(Apparatus.bodyWeight, .durations([DurationSet(secs: 30), DurationSet(secs: 30)]))),
            Exercise("Lunge", "Lunge", Modality(Apparatus.bodyWeight, .durations([DurationSet(secs: 30), DurationSet(secs: 30)])))
        ]
        self.empty = Workout("Empty", [], schedule: .anyDay)
        self.allDisabled = Workout("Disabled", ["Squat", "Lunge"], schedule: .anyDay)
        self.lower = Workout("Lower", ["Squat", "Lunge"], schedule: .anyDay)
        
        for instance in allDisabled.instances {
            instance.enabled = false
        }

        let workouts = [empty!, allDisabled!, lower!]
        let program = Program("Home", workouts, exercises, weeksStart: Date())
        self.model = Model(program)
        self.vm = ProgramVM(self.model)

        program.weeksStart = self.date(minutes: 0)
    }
    
    func testEmpty() throws {
        let workout = WorkoutVM(ProgramVM(self.model), self.empty)

        let (label, color) = self.vm.subLabel(workout)
        XCTAssertEqual(label, "no exercises")
        XCTAssertEqual(color, .black)
    }
    
    func testAllDisabled() throws {
        let workout = WorkoutVM(ProgramVM(self.model), self.allDisabled)

        let (label, color) = self.vm.subLabel(workout)
        XCTAssertEqual(label, "nothing enabled")
        XCTAssertEqual(color, .black)
    }
    
    // TODO:
    // today/tomorrow/in 2 days/any day
    //    anyDay
    //    cyclic
    //    days
    //    weeks
    // restWeek
    //    be sure to account for exercise.allowRest and exercise.enabled

    // User has started or completed workouts today.
    func testToday() throws {
        let workout = WorkoutVM(ProgramVM(self.model), self.lower)

        var instance = workout.instances.first(where: {$0.name == "Squat"})!
        instance.updateCurrent()
        var (label, color) = self.vm.subLabel(workout)
        XCTAssertEqual(label, "in progress")
        XCTAssertEqual(color, .red)

        instance.updateCurrent()
        (label, color) = self.vm.subLabel(workout)
        XCTAssertEqual(label, "partially completed")
        XCTAssertEqual(color, .red)

        instance = workout.instances.first(where: {$0.name == "Lunge"})!
        instance.updateCurrent()
        (label, color) = self.vm.subLabel(workout)
        XCTAssertEqual(label, "in progress")
        XCTAssertEqual(color, .red)

        instance.updateCurrent()
        (label, color) = self.vm.subLabel(workout)
        XCTAssertEqual(label, "completed")
        XCTAssertEqual(color, .black)
    }
    
    private func date(year: Int = 2021, month: Int = 9, day: Int = 1, minutes: Int = 1) -> Date {
        return self.formatter.date(from: "\(year)/\(month)/\(day) 09:\(minutes)")!
    }
}
