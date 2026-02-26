import Foundation

public final class HeadGestureRecognizer {
    private struct Sample {
        let x: Double
        let y: Double
        let width: Double
        let height: Double
        let confidence: Float
        let timestamp: Date
    }

    private var samples: [Sample] = []
    private var lastTriggerAt: Date?

    private var windowSeconds: TimeInterval
    private var cooldownSeconds: TimeInterval

    public init(settings: AppSettings = .default) {
        self.windowSeconds = 0.9
        self.cooldownSeconds = max(0.5, TimeInterval(settings.cooldownMs) / 1000)
    }

    public func update(settings: AppSettings) {
        cooldownSeconds = max(0.5, TimeInterval(settings.cooldownMs) / 1000)
        // Keep a stable window independent from frame count for head motion sequences.
        windowSeconds = 0.9
        samples.removeAll(keepingCapacity: true)
    }

    public func process(face: FacePoseFrame, now: Date = Date()) -> GestureTrigger? {
        let sample = Sample(
            x: Double(face.centerX),
            y: Double(face.centerY),
            width: max(Double(face.width), 0.0001),
            height: max(Double(face.height), 0.0001),
            confidence: face.confidence,
            timestamp: now
        )

        samples.append(sample)
        trimSamples(now: now)

        guard samples.count >= 6 else {
            return nil
        }

        if let lastTriggerAt, now.timeIntervalSince(lastTriggerAt) < cooldownSeconds {
            return nil
        }

        guard let event = classify() else {
            return nil
        }

        lastTriggerAt = now
        samples.removeAll(keepingCapacity: true)
        return GestureTrigger(event: event, confidence: face.confidence, timestamp: now)
    }

    private func trimSamples(now: Date) {
        let cutoff = now.addingTimeInterval(-windowSeconds)
        samples.removeAll { $0.timestamp < cutoff }
    }

    private func classify() -> GestureEvent? {
        guard !samples.isEmpty else { return nil }

        let avgWidth = samples.map(\.width).reduce(0, +) / Double(samples.count)
        let avgHeight = samples.map(\.height).reduce(0, +) / Double(samples.count)
        guard avgWidth > 0.0001, avgHeight > 0.0001 else { return nil }

        let xs = samples.map(\.x)
        let ys = samples.map(\.y)

        guard let minX = xs.min(), let maxX = xs.max(), let minY = ys.min(), let maxY = ys.max() else {
            return nil
        }

        let xRange = (maxX - minX) / avgWidth
        let yRange = (maxY - minY) / avgHeight

        let xTurns = directionTurnCount(values: xs, noiseThreshold: avgWidth * 0.02)
        let yTurns = directionTurnCount(values: ys, noiseThreshold: avgHeight * 0.02)

        // Shake: stronger horizontal motion with back-and-forth pattern.
        if xRange > 0.18, xTurns >= 2, xRange > yRange * 1.25 {
            return .shake
        }

        // Nod: stronger vertical motion with back-and-forth pattern.
        if yRange > 0.16, yTurns >= 2, yRange > xRange * 1.15 {
            return .nod
        }

        return nil
    }

    private func directionTurnCount(values: [Double], noiseThreshold: Double) -> Int {
        guard values.count >= 3 else { return 0 }

        var lastDirection = 0
        var turns = 0

        for index in 1..<values.count {
            let delta = values[index] - values[index - 1]
            if abs(delta) < noiseThreshold {
                continue
            }

            let direction = delta > 0 ? 1 : -1
            if lastDirection != 0, direction != lastDirection {
                turns += 1
            }
            lastDirection = direction
        }

        return turns
    }
}

