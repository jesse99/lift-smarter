//  Created by Jesse Vorisek on 9/9/21.
import Foundation

typealias LogFunc = (String) -> Void

var logError: LogFunc? = nil

func logErr(_ mesg: String) {
    if let log = logError {
        log(mesg)
    } else {
        print(mesg)
    }
}

func ASSERT(_ predicate: Bool, _ prefix: String, file: StaticString = #file, line: UInt = #line)  {
    // Thread.callStackSymbols can be used to print a back trace but it only includes mangled names and instruction offsets
    // so it's rather annoying.
    if !predicate {
        let url = URL(fileURLWithPath: file.description)
        logErr("\(prefix) failed at \(url.lastPathComponent):\(line)")
        precondition(false, file: file, line: line)
    }
}

func ASSERT_EQ<T>(_ lhs: T, _ rhs: T, _ prefix: String = "", file: StaticString = #file, line: UInt = #line) where T : Equatable {
    if lhs != rhs {
        let url = URL(fileURLWithPath: file.description)
        if prefix.isEmpty {
            logErr("\(prefix) \(lhs) == \(rhs) failed at \(url.lastPathComponent):\(line)")
        } else {
            logErr("\(lhs) == \(rhs) failed at \(url.lastPathComponent):\(line)")
        }
        precondition(false, file: file, line: line)
    }
}

func ASSERT_NE<T>(_ lhs: T, _ rhs: T, _ prefix: String = "", file: StaticString = #file, line: UInt = #line) where T : Equatable {
    if lhs == rhs {
        let url = URL(fileURLWithPath: file.description)
        if prefix.isEmpty {
            logErr("\(prefix) \(lhs) != \(rhs) failed at \(url.lastPathComponent):\(line)")
        } else {
            logErr("\(lhs) != \(rhs) failed at \(url.lastPathComponent):\(line)")
        }
        precondition(false, file: file, line: line)
    }
}

func ASSERT_LE<T>(_ lhs: T, _ rhs: T, _ prefix: String = "", file: StaticString = #file, line: UInt = #line) where T : Comparable {
    if lhs > rhs {
        let url = URL(fileURLWithPath: file.description)
        if prefix.isEmpty {
            logErr("\(prefix) \(lhs) <= \(rhs) failed at \(url.lastPathComponent):\(line)")
        } else {
            logErr("\(lhs) <= \(rhs) failed at \(url.lastPathComponent):\(line)")
        }
        precondition(false, file: file, line: line)
    }
}

func ASSERT_GE<T>(_ lhs: T, _ rhs: T, _ prefix: String = "", file: StaticString = #file, line: UInt = #line) where T : Comparable {
    if lhs < rhs {
        let url = URL(fileURLWithPath: file.description)
        if prefix.isEmpty {
            logErr("\(prefix) \(lhs) >= \(rhs) failed at \(url.lastPathComponent):\(line)")
        } else {
            logErr("\(lhs) >= \(rhs) failed at \(url.lastPathComponent):\(line)")
        }
        precondition(false, file: file, line: line)
    }
}

func ASSERT_NIL<T>(_ value: T?, _ prefix: String = "", file: StaticString = #file, line: UInt = #line) where T : Equatable {
    if let v = value {
        let url = URL(fileURLWithPath: file.description)
        if prefix.isEmpty {
            logErr("\(prefix) \(v) == nil failed at \(url.lastPathComponent):\(line)")
        } else {
            logErr("\(v) == nil failed at \(url.lastPathComponent):\(line)")
        }
        precondition(false, file: file, line: line)
    }
}

func ASSERT_NOT_NIL<T>(_ value: T?, _ prefix: String = "", file: StaticString = #file, line: UInt = #line) where T : Equatable {
    if value == nil {
        let url = URL(fileURLWithPath: file.description)
        if prefix.isEmpty {
            logErr("\(prefix) not nil failed at \(url.lastPathComponent):\(line)")
        } else {
            logErr("not nil failed at \(url.lastPathComponent):\(line)")
        }
        precondition(false, file: file, line: line)
    }
}
