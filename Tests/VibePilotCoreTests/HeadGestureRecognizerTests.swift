import XCTest
@testable import VibePilotCore

final class HeadGestureRecognizerTests: XCTestCase {
    func testDetectsShakeFromHorizontalFaceMotion() {
        let recognizer = HeadGestureRecognizer(settings: .default)
        let start = Date(timeIntervalSinceReferenceDate: 1000)

        let xs: [Float] = [0.50, 0.60, 0.42, 0.61, 0.40, 0.58, 0.44]
        let ys: [Float] = [0.55, 0.56, 0.55, 0.54, 0.55, 0.56, 0.55]

        let trigger = feed(recognizer: recognizer, xs: xs, ys: ys, start: start)
        XCTAssertEqual(trigger?.event, .shake)
    }

    func testDetectsNodFromVerticalFaceMotion() {
        let recognizer = HeadGestureRecognizer(settings: .default)
        let start = Date(timeIntervalSinceReferenceDate: 2000)

        let xs: [Float] = [0.50, 0.51, 0.49, 0.50, 0.51, 0.49, 0.50]
        let ys: [Float] = [0.55, 0.66, 0.47, 0.67, 0.46, 0.64, 0.50]

        let trigger = feed(recognizer: recognizer, xs: xs, ys: ys, start: start)
        XCTAssertEqual(trigger?.event, .nod)
    }

    private func feed(
        recognizer: HeadGestureRecognizer,
        xs: [Float],
        ys: [Float],
        start: Date
    ) -> GestureTrigger? {
        var trigger: GestureTrigger?

        for index in 0..<min(xs.count, ys.count) {
            let face = FacePoseFrame(
                centerX: xs[index],
                centerY: ys[index],
                width: 0.20,
                height: 0.20,
                confidence: 0.9,
                timestamp: start.addingTimeInterval(Double(index) * 0.08)
            )
            trigger = recognizer.process(face: face, now: face.timestamp) ?? trigger
        }

        return trigger
    }
}

