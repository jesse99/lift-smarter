//  Created by Jesse Vorisek on 9/9/21.
import Foundation

extension Date {
    func hoursSinceDate(_ rhs: Date) -> Double {    // TODO Might want to handle this more like weeks()
        let secs = self.timeIntervalSince(rhs)
        let mins = secs/60.0
        let hours = mins/60.0
        return hours
    }

    func daysSinceDate(_ rhs: Date) -> Double {    // TODO Might want to handle this more like weeks()
        let secs = self.startOfDay().timeIntervalSince(rhs.startOfDay())
        let mins = secs/60.0
        let hours = mins/60.0
        let days = hours/24.0
        return days
    }
    
    func startOfDay() -> Date {
        let calendar = Calendar.current
        let result = calendar.startOfDay(for: self)
        return result
    }

    func startOfWeek() -> Date {
        let calendar = Calendar.current
        if let sunday = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)) {
            return sunday    // TODO: handle year change
        } else {
            return Date()
        }
    }

    func string(format: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.string(from: self)
    }

    func daysMatch(_ rhs: Date) -> Bool {
        let delta = Calendar.current.dateComponents([.day], from: self, to: rhs)
        return delta.day == 0
    }
}

func daysBetween(from: Date, to: Date) -> Int {
    ASSERT_NE(from.compare(to), .orderedDescending)

    let start1 = from.startOfDay()
    let start2 = to.startOfDay()
    return Calendar.current.dateComponents([.day], from: start1, to: start2).day!
}

func weeksBetween(from: Date, to: Date) -> Int {
    ASSERT_NE(from.compare(to), .orderedDescending)

    let start1 = from.startOfWeek()
    let start2 = to.startOfWeek()
    return Calendar.current.dateComponents([.weekOfMonth], from: start1, to: start2).weekOfMonth!
}

// blockStart is an arbitrary week within week 1.
// currentDate is an arbitrary date after blockStart.
// numWeeks is the total number of weeks within the program.
// Returns the week number for the current date,
func currentWeek(blockStart: Date, currentDate: Date, numWeeks: Int) -> Int {
    ASSERT_EQ(blockStart.compare(currentDate), .orderedAscending)
    let weeks = weeksBetween(from: blockStart, to: currentDate)
    let week = (weeks % numWeeks) + 1
    return week
}

// Weeks are the normal 1-based week indexes.
// Days are zero based indexes where Sunday is 0.
func daysBetween(fromWeek: Int, fromDay: Int, toWeek: Int, toDay: Int, numWeeks: Int) -> Int {
    ASSERT_LE(fromWeek, numWeeks)
    ASSERT_LE(toWeek, numWeeks)
    
    var toWeek = toWeek
    if toWeek < fromWeek {
        toWeek += numWeeks
    }
    
    if fromWeek == toWeek && toDay < fromDay {
        toWeek += numWeeks
    }
    
    if fromWeek <= toWeek {
        return 7*(toWeek - fromWeek) - fromDay + toDay
    } else {
        return 7*(numWeeks - fromWeek + toWeek) - fromDay + toDay
    }
}
