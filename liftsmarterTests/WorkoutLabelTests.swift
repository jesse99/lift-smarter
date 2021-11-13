//  Created by Jesse Vorisek on 10/2/21.
import XCTest
@testable import liftsmarter

// Label is just the workout name so all we need to test here is the sub label.
class WorkoutLabelTests: XCTestCase {
    let formatter = DateFormatter()

    override func setUp() {
        self.formatter.dateFormat = "yyyy/MM/dd HH:mm"
    }
    
    func testEmpty() throws {
        let (_, program, workout) = create([])

        let (label, color) = program.subLabel(workout)
        XCTAssertEqual(label, "no exercises")
        XCTAssertEqual(color, .black)
    }
    
    func testAllDisabled() throws {
        let (model, program, workout) = create(["Squat", "Lunge"])

        for exercise in workout.workout(model).exercises {
            exercise.enabled = false
        }

        let (label, color) = program.subLabel(workout)
        XCTAssertEqual(label, "nothing enabled")
        XCTAssertEqual(color, .black)
    }
    
    // User has started or completed workouts today.
    func testToday() throws {
        let (_, program, workout) = create(["Squat", "Lunge"])

        var instance = workout.instances.first(where: {$0.name == "Squat"})!
        instance.appendCurrent()
        var (label, color) = program.subLabel(workout)
        XCTAssertEqual(label, "in progress")
        XCTAssertEqual(color, .red)

        instance.appendCurrent()
        (label, color) = program.subLabel(workout)
        XCTAssertEqual(label, "partially completed")
        XCTAssertEqual(color, .red)

        instance = workout.instances.first(where: {$0.name == "Lunge"})!
        instance.appendCurrent()
        (label, color) = program.subLabel(workout)
        XCTAssertEqual(label, "in progress")
        XCTAssertEqual(color, .red)

        instance.appendCurrent()
        (label, color) = program.subLabel(workout)
        XCTAssertEqual(label, "completed")
        XCTAssertEqual(color, .black)
    }
    
    func testAnyDay() throws {
        let (_, program, workout) = create(["Squat", "Lunge"])

        let (label, color) = program.subLabel(workout)
        XCTAssertEqual(label, "any day")
        XCTAssertEqual(color, .orange)
    }
    
    func testCyclic3() throws {
        let (_, program, workout) = create(["Squat", "Lunge"], .cyclic(3))
        
        var (label, color) = program.subLabel(workout)
        XCTAssertEqual(label, "not scheduled")
        XCTAssertEqual(color, .red)

        let instance = workout.instances.first(where: {$0.name == "Squat"})!
        instance.appendCurrent(now: date(minutes: 10))
        instance.appendCurrent(now: date(minutes: 20))

        (label, color) = program.subLabel(workout, now: date(minutes: 30))
        XCTAssertEqual(label, "partially completed")
        XCTAssertEqual(color, .red)

        (label, color) = program.subLabel(workout, now: date(day: 2))  // note that this is less than 24 hours after exercise was completed
        XCTAssertEqual(label, "in 2 days")
        XCTAssertEqual(color, .black)

        (label, color) = program.subLabel(workout, now: date(day: 3))
        XCTAssertEqual(label, "tomorrow")
        XCTAssertEqual(color, .blue)

        (label, color) = program.subLabel(workout, now: date(day: 4))
        XCTAssertEqual(label, "today")
        XCTAssertEqual(color, .orange)

        (label, color) = program.subLabel(workout, now: date(day: 5))
        XCTAssertEqual(label, "overdue by 1 day")
        XCTAssertEqual(color, .red)

        (label, color) = program.subLabel(workout, now: date(day: 6))
        XCTAssertEqual(label, "overdue by 2 days")
        XCTAssertEqual(color, .red)
        
        (label, color) = program.subLabel(workout, now: date(month: 12, day: 14))
        XCTAssertEqual(label, "overdue by more than 3 months")
        XCTAssertEqual(color, .red)
    }
    
    func testCyclic2() throws {
        let (_, program, workout) = create(["Squat", "Lunge"], .cyclic(2))
        
        var (label, color) = program.subLabel(workout)
        XCTAssertEqual(label, "not scheduled")
        XCTAssertEqual(color, .red)

        let instance = workout.instances.first(where: {$0.name == "Squat"})!
        instance.appendCurrent(now: date(minutes: 10))
        instance.appendCurrent(now: date(minutes: 20))

        (label, color) = program.subLabel(workout, now: date(minutes: 30))
        XCTAssertEqual(label, "partially completed")
        XCTAssertEqual(color, .red)

        (label, color) = program.subLabel(workout, now: date(day: 2))
        XCTAssertEqual(label, "tomorrow")
        XCTAssertEqual(color, .blue)

        (label, color) = program.subLabel(workout, now: date(day: 3))
        XCTAssertEqual(label, "today")
        XCTAssertEqual(color, .orange)

        (label, color) = program.subLabel(workout, now: date(day: 4))
        XCTAssertEqual(label, "overdue by 1 day")
        XCTAssertEqual(color, .red)

        (label, color) = program.subLabel(workout, now: date(day: 5))
        XCTAssertEqual(label, "overdue by 2 days")
        XCTAssertEqual(color, .red)
    }
    
    func testCyclic1() throws {
        let (_, program, workout) = create(["Squat", "Lunge"], .cyclic(1))
        
        var (label, color) = program.subLabel(workout)
        XCTAssertEqual(label, "today")
        XCTAssertEqual(color, .orange)

        let instance = workout.instances.first(where: {$0.name == "Squat"})!
        instance.appendCurrent(now: date(minutes: 10))
        instance.appendCurrent(now: date(minutes: 20))

        (label, color) = program.subLabel(workout, now: date(minutes: 30))
        XCTAssertEqual(label, "partially completed")
        XCTAssertEqual(color, .red)

        (label, color) = program.subLabel(workout, now: date(day: 2))
        XCTAssertEqual(label, "today")
        XCTAssertEqual(color, .orange)

        (label, color) = program.subLabel(workout, now: date(day: 3))
        XCTAssertEqual(label, "overdue by 1 day")
        XCTAssertEqual(color, .red)

        (label, color) = program.subLabel(workout, now: date(day: 4))
        XCTAssertEqual(label, "overdue by 2 days")
        XCTAssertEqual(color, .red)
    }
    
    func testDays() throws {
        let (_, program, workout) = create(["Squat", "Lunge"], .days([.monday, .wednesday]))
        
        var (label, color) = program.subLabel(workout, now: date(day: 5))   // sunday
        XCTAssertEqual(label, "tomorrow")
        XCTAssertEqual(color, .blue)

        (label, color) = program.subLabel(workout, now: date(day: 6))   // monday
        XCTAssertEqual(label, "today")
        XCTAssertEqual(color, .orange)

        (label, color) = program.subLabel(workout, now: date(day: 7))   // tuesday
        XCTAssertEqual(label, "tomorrow")
        XCTAssertEqual(color, .blue)

        (label, color) = program.subLabel(workout, now: date(day: 8))   // wednesay
        XCTAssertEqual(label, "today")
        XCTAssertEqual(color, .orange)

        (label, color) = program.subLabel(workout, now: date(day: 9))   // thursday
        XCTAssertEqual(label, "in 4 days")
        XCTAssertEqual(color, .black)

        (label, color) = program.subLabel(workout, now: date(day: 10))   // friday
        XCTAssertEqual(label, "in 3 days")
        XCTAssertEqual(color, .black)
        
        (label, color) = program.subLabel(workout, now: date(day: 11))   // saturday
        XCTAssertEqual(label, "in 2 days")
        XCTAssertEqual(color, .black)
    }
    
    func testAnyDayWeeks() throws {
        let (_, program, workout) = create(["Squat", "Lunge"], .weeks([1, 4], .anyDay), restWeeks: [6])
        
        var (label, color) = program.subLabel(workout, now: date())
        XCTAssertEqual(label, "any day")
        XCTAssertEqual(color, .orange)

        (label, color) = program.subLabel(workout, now: date(day: 2))
        XCTAssertEqual(label, "any day")
        XCTAssertEqual(color, .orange)

        (label, color) = program.subLabel(workout, now: date(day: 6))
        XCTAssertEqual(label, "in 13 days")
        XCTAssertEqual(color, .black)

        (label, color) = program.subLabel(workout, now: date(day: 16))
        XCTAssertEqual(label, "in 3 days")
        XCTAssertEqual(color, .black)

        (label, color) = program.subLabel(workout, now: date(day: 23))
        XCTAssertEqual(label, "any day")
        XCTAssertEqual(color, .orange)

        (label, color) = program.subLabel(workout, now: date(day: 30))
        XCTAssertEqual(label, "in 10 days")
        XCTAssertEqual(color, .black)
    }
    
    func testDaysWeeks() throws {
        let (_, program, workout) = create(["Squat", "Lunge"], .weeks([1, 4], .days([.monday, .wednesday])), restWeeks: [6])
        
        var (label, color) = program.subLabel(workout, now: date())
        XCTAssertEqual(label, "today")
        XCTAssertEqual(color, .orange)

        (label, color) = program.subLabel(workout, now: date(day: 4))
        XCTAssertEqual(label, "in 16 days")
        XCTAssertEqual(color, .black)

        (label, color) = program.subLabel(workout, now: date(day: 6))
        XCTAssertEqual(label, "in 14 days")
        XCTAssertEqual(color, .black)

        (label, color) = program.subLabel(workout, now: date(day: 16))
        XCTAssertEqual(label, "in 4 days")
        XCTAssertEqual(color, .black)

        (label, color) = program.subLabel(workout, now: date(day: 21))
        XCTAssertEqual(label, "tomorrow")
        XCTAssertEqual(color, .blue)

        (label, color) = program.subLabel(workout, now: date(day: 30))
        XCTAssertEqual(label, "in 11 days")
        XCTAssertEqual(color, .black)
    }

    func testRestWeekAllAllowed() throws {
        let (_, program, workout) = create(["Squat", "Lunge"], .weeks([1, 4], .anyDay), restWeeks: [3, 4, 6])
        
        var (label, color) = program.subLabel(workout, now: date())
        XCTAssertEqual(label, "any day")
        XCTAssertEqual(color, .orange)

        (label, color) = program.subLabel(workout, now: date(day: 2))
        XCTAssertEqual(label, "any day")
        XCTAssertEqual(color, .orange)

        (label, color) = program.subLabel(workout, now: date(day: 6))
        XCTAssertEqual(label, "in 34 days")
        XCTAssertEqual(color, .black)

        (label, color) = program.subLabel(workout, now: date(day: 16))  // rest week
        XCTAssertEqual(label, "in 24 days")
        XCTAssertEqual(color, .black)

        (label, color) = program.subLabel(workout, now: date(day: 23))  // both rest and workout week
        XCTAssertEqual(label, "in 17 days")
        XCTAssertEqual(color, .black)

        (label, color) = program.subLabel(workout, now: date(day: 30))
        XCTAssertEqual(label, "in 10 days")
        XCTAssertEqual(color, .black)

        (label, color) = program.subLabel(workout, now: date(month: 10, day: 11))
        XCTAssertEqual(label, "any day")
        XCTAssertEqual(color, .orange)
    }
    
    func testRestWeekSomeAllowed() throws {
        let (model, program, workout) = create(["Squat", "Lunge"], .weeks([1, 4], .anyDay), restWeeks: [3, 4, 6])
        
        let exercise = program.exercises[0].exercise(model)
        exercise.allowRest = false
        
        var (label, color) = program.subLabel(workout, now: date())     // these are the same as testAnyDayWeeks because the workout is scheduled even during rest weeks
        XCTAssertEqual(label, "any day")
        XCTAssertEqual(color, .orange)

        (label, color) = program.subLabel(workout, now: date(day: 2))
        XCTAssertEqual(label, "any day")
        XCTAssertEqual(color, .orange)

        (label, color) = program.subLabel(workout, now: date(day: 6))
        XCTAssertEqual(label, "in 13 days")
        XCTAssertEqual(color, .black)

        (label, color) = program.subLabel(workout, now: date(day: 16))
        XCTAssertEqual(label, "in 3 days")
        XCTAssertEqual(color, .black)

        (label, color) = program.subLabel(workout, now: date(day: 23))
        XCTAssertEqual(label, "any day")
        XCTAssertEqual(color, .orange)

        (label, color) = program.subLabel(workout, now: date(day: 30))
        XCTAssertEqual(label, "in 10 days")
        XCTAssertEqual(color, .black)
    }

    func testAllRest() throws {
        let (_, program, workout) = create(["Squat", "Lunge"], .weeks([1, 4], .anyDay), restWeeks: [1, 2, 3, 4, 5, 6])
        
        var (label, color) = program.subLabel(workout, now: date())
        XCTAssertEqual(label, "not scheduled")
        XCTAssertEqual(color, .red)

        (label, color) = program.subLabel(workout, now: date(day: 2))
        XCTAssertEqual(label, "not scheduled")
        XCTAssertEqual(color, .red)

        (label, color) = program.subLabel(workout, now: date(day: 6))
        XCTAssertEqual(label, "not scheduled")
        XCTAssertEqual(color, .red)

        (label, color) = program.subLabel(workout, now: date(day: 16))  // rest week
        XCTAssertEqual(label, "not scheduled")
        XCTAssertEqual(color, .red)

        (label, color) = program.subLabel(workout, now: date(day: 23))  // both rest and workout week
        XCTAssertEqual(label, "not scheduled")
        XCTAssertEqual(color, .red)

        (label, color) = program.subLabel(workout, now: date(day: 30))
        XCTAssertEqual(label, "not scheduled")
        XCTAssertEqual(color, .red)

        (label, color) = program.subLabel(workout, now: date(month: 10, day: 11))
        XCTAssertEqual(label, "not scheduled")
        XCTAssertEqual(color, .red)
    }

    func testRestWithNoWeeks() throws {
        let (_, program, workout) = create(["Squat", "Lunge"], .days([.monday, .wednesday]), restWeeks: [3])
        
        var (label, color) = program.subLabel(workout, now: date(day: 5))   // sunday
        XCTAssertEqual(label, "tomorrow")
        XCTAssertEqual(color, .blue)

        (label, color) = program.subLabel(workout, now: date(day: 6))   // monday
        XCTAssertEqual(label, "today")
        XCTAssertEqual(color, .orange)

        (label, color) = program.subLabel(workout, now: date(day: 7))   // tuesday
        XCTAssertEqual(label, "tomorrow")
        XCTAssertEqual(color, .blue)

        (label, color) = program.subLabel(workout, now: date(day: 8))   // wednesay
        XCTAssertEqual(label, "today")
        XCTAssertEqual(color, .orange)

        (label, color) = program.subLabel(workout, now: date(day: 9))   // thursday
        XCTAssertEqual(label, "in 4 days")
        XCTAssertEqual(color, .black)

        (label, color) = program.subLabel(workout, now: date(day: 10))   // friday
        XCTAssertEqual(label, "in 3 days")
        XCTAssertEqual(color, .black)
        
        (label, color) = program.subLabel(workout, now: date(day: 11))   // saturday
        XCTAssertEqual(label, "in 2 days")
        XCTAssertEqual(color, .black)
        
        (label, color) = program.subLabel(workout, now: date(day: 15))   // wednesday (rest)
        XCTAssertEqual(label, "in 5 days")
        XCTAssertEqual(color, .black)

        (label, color) = program.subLabel(workout, now: date(day: 22))   // wednesday
        XCTAssertEqual(label, "today")
        XCTAssertEqual(color, .orange)
    }

    func testOverdueWithRest() throws {
        let (model, programVM, workoutVM) = create(["Bench", "OHP"], .days([.monday, .thursday]))

        let workout = model.program.workouts.first(where: {$0.name == workoutVM.name})!
        let exercise = workout.exercises[0]
        workout.completed[exercise.name] = date(day: 1)

        var (label, color) = programVM.subLabel(workoutVM, now: date(day: 6))   // monday (next scheduled)
        XCTAssertEqual(label, "today")
        XCTAssertEqual(color, .orange)

        (label, color) = programVM.subLabel(workoutVM, now: date(day: 7))   // tuesday
        XCTAssertEqual(label, "overdue by 1 day")
        XCTAssertEqual(color, .red)

        // Exercises that rely on rest weeks should have at least one day of rest between them.
        (label, color) = programVM.subLabel(workoutVM, now: date(day: 8))   // wednesday
        XCTAssertEqual(label, "tomorrow")       // TODO: " (skipped previous)"?
        XCTAssertEqual(color, .blue)

        (label, color) = programVM.subLabel(workoutVM, now: date(day: 9))   // thursday
        XCTAssertEqual(label, "today")
        XCTAssertEqual(color, .orange)
    }

    func testOverdueWithNoRest() throws {
        let (model, programVM, workoutVM) = create(["Stretch", "Jog"], .days([.monday, .thursday]))
        for instance in workoutVM.instances {
            instance.exercise.setAllowRest(false)
        }

        let workout = model.program.workouts.first(where: {$0.name == workoutVM.name})!
        let exercise = workout.exercises[0]
        workout.completed[exercise.name] = date(day: 1)

        var (label, color) = programVM.subLabel(workoutVM, now: date(day: 6))   // monday (next scheduled)
        XCTAssertEqual(label, "today")
        XCTAssertEqual(color, .orange)

        (label, color) = programVM.subLabel(workoutVM, now: date(day: 7))   // tuesday
        XCTAssertEqual(label, "overdue by 1 day")
        XCTAssertEqual(color, .red)

        // Exercises that don't rely on rest weeks can be done back to back.
        (label, color) = programVM.subLabel(workoutVM, now: date(day: 8))   // wednesday
        XCTAssertEqual(label, "overdue by 2 days")
        XCTAssertEqual(color, .red)

        (label, color) = programVM.subLabel(workoutVM, now: date(day: 9))   // thursday
        XCTAssertEqual(label, "today")
        XCTAssertEqual(color, .orange)
    }

    private func create(_ names: [String], _ schedule: Schedule = .anyDay, restWeeks: [Int] = []) -> (Model, ProgramVM, WorkoutVM) {
        let sets = [DurationSet(secs: 30), DurationSet(secs: 30)]
        let exercises = names.map({Exercise($0, $0, .bodyWeight, .durations(DurationsInfo(sets: sets)))})
        let workout = Workout("Workout", exercises.map({$0.clone()}), schedule: schedule)
        let program = Program("Program", [workout], exercises, weeksStart: Date())
        program.weeksStart = self.date(minutes: 0)
        program.restWeeks = restWeeks

        let model = Model(program)
        let vm = ProgramVM(ModelVM(model), model)
        
        return (model, vm, WorkoutVM(vm, workout))
    }

    //     September
    // Su Mo Tu We Th Fr Sa
    //          1  2  3  4      date defaults to Sep 1, 2021
    // 5  6  7  8  9 10 11
    // 12 13 14 15 16 17 18
    // 19 20 21 22 23 24 25
    // 26 27 28 29 30
    //
    //      October
    // Su Mo Tu We Th Fr Sa
    //                1  2
    // 3  4  5  6  7  8  9
    // 10 11 12 13 14 15 16
    // 17 18 19 20 21 22 23
    // 24 25 26 27 28 29 30
    // 31
    private func date(year: Int = 2021, month: Int = 9, day: Int = 1, minutes: Int = 1) -> Date {
        return self.formatter.date(from: "\(year)/\(month)/\(day) 09:\(minutes)")!
    }
}
