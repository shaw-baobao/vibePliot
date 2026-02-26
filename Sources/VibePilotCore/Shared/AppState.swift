import Foundation

public final class AppState {
    public var isRecognitionRunning: Bool
    public var isRecognitionPaused: Bool
    public var latestTrigger: GestureTrigger?
    public var statusMessage: String?
    public var lastErrorMessage: String?

    public init(
        isRecognitionRunning: Bool = false,
        isRecognitionPaused: Bool = false,
        latestTrigger: GestureTrigger? = nil,
        statusMessage: String? = nil,
        lastErrorMessage: String? = nil
    ) {
        self.isRecognitionRunning = isRecognitionRunning
        self.isRecognitionPaused = isRecognitionPaused
        self.latestTrigger = latestTrigger
        self.statusMessage = statusMessage
        self.lastErrorMessage = lastErrorMessage
    }
}
