import Foundation

public struct GestureStabilizer: Sendable {
    public private(set) var framesRequired: Int
    public private(set) var cooldown: TimeInterval

    private var currentCandidate: GestureEvent?
    private var consecutiveFrames = 0
    private var lastTriggerAt: Date?

    public init(framesRequired: Int, cooldown: TimeInterval) {
        self.framesRequired = max(1, framesRequired)
        self.cooldown = max(0, cooldown)
    }

    public mutating func update(framesRequired: Int, cooldown: TimeInterval) {
        self.framesRequired = max(1, framesRequired)
        self.cooldown = max(0, cooldown)
        reset()
    }

    public mutating func process(candidate: GestureEvent?, now: Date = Date()) -> GestureEvent? {
        guard let candidate else {
            currentCandidate = nil
            consecutiveFrames = 0
            return nil
        }

        if currentCandidate == candidate {
            consecutiveFrames += 1
        } else {
            currentCandidate = candidate
            consecutiveFrames = 1
        }

        guard consecutiveFrames >= framesRequired else {
            return nil
        }

        if let lastTriggerAt, now.timeIntervalSince(lastTriggerAt) < cooldown {
            return nil
        }

        lastTriggerAt = now
        consecutiveFrames = 0
        return candidate
    }

    public mutating func reset() {
        currentCandidate = nil
        consecutiveFrames = 0
    }
}

