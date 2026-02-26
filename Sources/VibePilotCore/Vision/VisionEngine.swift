import AVFoundation
import Foundation
import ImageIO
import Vision

public final class VisionEngine {
    private let handPoseRequest: VNDetectHumanHandPoseRequest

    public init() {
        let request = VNDetectHumanHandPoseRequest()
        request.maximumHandCount = 1
        self.handPoseRequest = request
    }

    public func analyze(_ sampleBuffer: CMSampleBuffer) -> HandPoseFrame? {
        let handler = VNImageRequestHandler(
            cmSampleBuffer: sampleBuffer,
            orientation: .up,
            options: [:]
        )

        do {
            try handler.perform([handPoseRequest])
            guard let observation = handPoseRequest.results?.first else {
                return nil
            }

            let recognizedPoints = try observation.recognizedPoints(.all)
            let points = recognizedPoints.map { key, point in
                HandPosePoint(
                    name: String(describing: key),
                    x: Float(point.location.x),
                    y: Float(point.location.y),
                    confidence: point.confidence
                )
            }

            guard !points.isEmpty else {
                return nil
            }

            return HandPoseFrame(points: points, timestamp: Date())
        } catch {
            return nil
        }
    }
}
