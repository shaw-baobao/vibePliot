import XCTest
@testable import VibePilotCore

final class GestureStabilizerTests: XCTestCase {
    func testRequiresConsecutiveFramesBeforeTriggering() {
        var stabilizer = GestureStabilizer(framesRequired: 3, cooldown: 0.8)
        let start = Date(timeIntervalSinceReferenceDate: 1000)

        XCTAssertNil(stabilizer.process(candidate: .ok, now: start))
        XCTAssertNil(stabilizer.process(candidate: .ok, now: start.addingTimeInterval(0.03)))
        XCTAssertEqual(stabilizer.process(candidate: .ok, now: start.addingTimeInterval(0.06)), .ok)
    }

    func testChangingCandidateResetsFrameCounter() {
        var stabilizer = GestureStabilizer(framesRequired: 2, cooldown: 0)
        let start = Date(timeIntervalSinceReferenceDate: 2000)

        XCTAssertNil(stabilizer.process(candidate: .ok, now: start))
        XCTAssertNil(stabilizer.process(candidate: .fist, now: start.addingTimeInterval(0.03)))
        XCTAssertEqual(stabilizer.process(candidate: .fist, now: start.addingTimeInterval(0.06)), .fist)
    }

    func testCooldownPreventsRapidRetrigger() {
        var stabilizer = GestureStabilizer(framesRequired: 1, cooldown: 1.0)
        let start = Date(timeIntervalSinceReferenceDate: 3000)

        XCTAssertEqual(stabilizer.process(candidate: .fist, now: start), .fist)
        XCTAssertNil(stabilizer.process(candidate: .fist, now: start.addingTimeInterval(0.2)))
        XCTAssertEqual(stabilizer.process(candidate: .fist, now: start.addingTimeInterval(1.2)), .fist)
    }
}

