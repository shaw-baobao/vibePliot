import Foundation

public final class GestureRecognizer {
    private struct GestureCandidate {
        let event: GestureEvent
        let confidence: Float
    }

    private struct Vec2 {
        let x: Double
        let y: Double
    }

    private var stabilizer: GestureStabilizer
    private var confidenceThreshold: Float

    public init(settings: AppSettings = .default) {
        self.confidenceThreshold = settings.confidenceThreshold
        self.stabilizer = GestureStabilizer(
            framesRequired: settings.framesRequired,
            cooldown: TimeInterval(settings.cooldownMs) / 1000
        )
    }

    public func update(settings: AppSettings) {
        confidenceThreshold = settings.confidenceThreshold
        stabilizer.update(
            framesRequired: settings.framesRequired,
            cooldown: TimeInterval(settings.cooldownMs) / 1000
        )
    }

    public func process(frame: HandPoseFrame, now: Date = Date()) -> GestureTrigger? {
        guard let candidate = classify(frame: frame), candidate.confidence >= confidenceThreshold else {
            _ = stabilizer.process(candidate: nil, now: now)
            return nil
        }

        guard let event = stabilizer.process(candidate: candidate.event, now: now) else {
            return nil
        }

        return GestureTrigger(event: event, confidence: candidate.confidence, timestamp: now)
    }

    private func classify(frame: HandPoseFrame) -> GestureCandidate? {
        guard !frame.points.isEmpty else {
            return nil
        }

        let lookup = makeLookup(points: frame.points)

        guard
            let wrist = point(namedLike: "wrist", in: lookup),
            let middleMCP = point(namedLike: "middlemcp", in: lookup)
        else {
            return nil
        }

        let palmBase = [wrist]
        let palmAnchors = [
            point(namedLike: "indexmcp", in: lookup),
            Optional(middleMCP),
            point(namedLike: "ringmcp", in: lookup),
            point(namedLike: "littlemcp", in: lookup)
        ].compactMap { $0 }

        let palmPoints = palmBase + palmAnchors
        guard palmPoints.count >= 3 else {
            return nil
        }

        let palmCenter = average(of: palmPoints)
        let scale = max(distance(wrist, middleMCP), 0.0001)

        guard
            let thumbTip = point(namedLike: "thumbtip", in: lookup),
            let indexTip = point(namedLike: "indextip", in: lookup),
            let middleTip = point(namedLike: "middletip", in: lookup),
            let ringTip = point(namedLike: "ringtip", in: lookup),
            let littleTip = point(namedLike: "littletip", in: lookup)
        else {
            return nil
        }

        let thumbDistance = normalizedDistance(thumbTip, palmCenter, scale: scale)
        let indexDistance = normalizedDistance(indexTip, palmCenter, scale: scale)
        let middleDistance = normalizedDistance(middleTip, palmCenter, scale: scale)
        let ringDistance = normalizedDistance(ringTip, palmCenter, scale: scale)
        let littleDistance = normalizedDistance(littleTip, palmCenter, scale: scale)

        let thumbIndexDistance = normalizedDistance(thumbTip, indexTip, scale: scale)

        let indexMiddleSpread = normalizedDistance(indexTip, middleTip, scale: scale)
        let middleRingSpread = normalizedDistance(middleTip, ringTip, scale: scale)
        let ringLittleSpread = normalizedDistance(ringTip, littleTip, scale: scale)

        if isOpenPalm(
            thumbDistance: thumbDistance,
            indexDistance: indexDistance,
            middleDistance: middleDistance,
            ringDistance: ringDistance,
            littleDistance: littleDistance,
            indexMiddleSpread: indexMiddleSpread,
            middleRingSpread: middleRingSpread,
            ringLittleSpread: ringLittleSpread
        ) {
            let confidence = minimumConfidence([thumbTip, indexTip, middleTip, ringTip, littleTip])
            return GestureCandidate(event: .openPalm, confidence: confidence)
        }

        if isFist(
            thumbDistance: thumbDistance,
            indexDistance: indexDistance,
            middleDistance: middleDistance,
            ringDistance: ringDistance,
            littleDistance: littleDistance
        ) {
            let confidence = minimumConfidence([thumbTip, indexTip, middleTip, ringTip, littleTip])
            return GestureCandidate(event: .fist, confidence: confidence)
        }

        if isOK(
            thumbIndexDistance: thumbIndexDistance,
            middleDistance: middleDistance,
            ringDistance: ringDistance,
            littleDistance: littleDistance,
            middleRingSpread: middleRingSpread,
            ringLittleSpread: ringLittleSpread
        ) {
            let confidence = minimumConfidence([thumbTip, indexTip, middleTip, ringTip, littleTip])
            return GestureCandidate(event: .ok, confidence: confidence)
        }

        return nil
    }

    private func isOpenPalm(
        thumbDistance: Double,
        indexDistance: Double,
        middleDistance: Double,
        ringDistance: Double,
        littleDistance: Double,
        indexMiddleSpread: Double,
        middleRingSpread: Double,
        ringLittleSpread: Double
    ) -> Bool {
        thumbDistance > 1.1 &&
        indexDistance > 1.7 &&
        middleDistance > 1.9 &&
        ringDistance > 1.7 &&
        littleDistance > 1.5 &&
        indexMiddleSpread > 0.35 &&
        middleRingSpread > 0.28 &&
        ringLittleSpread > 0.25
    }

    private func isFist(
        thumbDistance: Double,
        indexDistance: Double,
        middleDistance: Double,
        ringDistance: Double,
        littleDistance: Double
    ) -> Bool {
        thumbDistance < 1.35 &&
        indexDistance < 1.2 &&
        middleDistance < 1.2 &&
        ringDistance < 1.2 &&
        littleDistance < 1.2
    }

    private func isOK(
        thumbIndexDistance: Double,
        middleDistance: Double,
        ringDistance: Double,
        littleDistance: Double,
        middleRingSpread: Double,
        ringLittleSpread: Double
    ) -> Bool {
        thumbIndexDistance < 0.75 &&
        middleDistance > 1.7 &&
        ringDistance > 1.6 &&
        littleDistance > 1.5 &&
        middleRingSpread > 0.2 &&
        ringLittleSpread > 0.18
    }

    private func makeLookup(points: [HandPosePoint]) -> [String: HandPosePoint] {
        Dictionary(uniqueKeysWithValues: points.map { (normalizedName($0.name), $0) })
    }

    private func point(namedLike name: String, in lookup: [String: HandPosePoint]) -> HandPosePoint? {
        if let exact = lookup[normalizedName(name)] {
            return exact
        }

        let normalizedTarget = normalizedName(name)
        return lookup.first(where: { key, _ in key.contains(normalizedTarget) })?.value
    }

    private func normalizedName(_ value: String) -> String {
        value.lowercased().filter { $0.isLetter || $0.isNumber }
    }

    private func average(of points: [HandPosePoint]) -> Vec2 {
        let count = Double(points.count)
        let x = points.reduce(0.0) { $0 + Double($1.x) } / count
        let y = points.reduce(0.0) { $0 + Double($1.y) } / count
        return Vec2(x: x, y: y)
    }

    private func normalizedDistance(_ lhs: HandPosePoint, _ rhs: HandPosePoint, scale: Double) -> Double {
        let dx = Double(lhs.x - rhs.x)
        let dy = Double(lhs.y - rhs.y)
        return sqrt(dx * dx + dy * dy) / scale
    }

    private func normalizedDistance(_ lhs: HandPosePoint, _ rhs: Vec2, scale: Double) -> Double {
        let dx = Double(lhs.x) - rhs.x
        let dy = Double(lhs.y) - rhs.y
        return sqrt(dx * dx + dy * dy) / scale
    }

    private func distance(_ lhs: HandPosePoint, _ rhs: HandPosePoint) -> Double {
        let dx = Double(lhs.x - rhs.x)
        let dy = Double(lhs.y - rhs.y)
        return sqrt(dx * dx + dy * dy)
    }

    private func minimumConfidence(_ points: [HandPosePoint]) -> Float {
        points.map(\.confidence).min() ?? 0
    }
}
