import AVFoundation
import Foundation
import ImageIO
import Vision

public final class VisionEngine {
    private let handPoseRequest: VNDetectHumanHandPoseRequest
    private let faceRectanglesRequest: VNDetectFaceRectanglesRequest

    public init() {
        let handRequest = VNDetectHumanHandPoseRequest()
        handRequest.maximumHandCount = 1
        self.handPoseRequest = handRequest
        self.faceRectanglesRequest = VNDetectFaceRectanglesRequest()
    }

    public func analyze(_ sampleBuffer: CMSampleBuffer) -> VisionAnalysisFrame? {
        let timestamp = Date()
        let handler = VNImageRequestHandler(
            cmSampleBuffer: sampleBuffer,
            orientation: .up,
            options: [:]
        )

        do {
            try handler.perform([handPoseRequest, faceRectanglesRequest])

            let handPose = try makeHandPoseFrame(timestamp: timestamp)
            let facePose = makeFacePoseFrame(timestamp: timestamp)

            guard handPose != nil || facePose != nil else {
                return nil
            }

            return VisionAnalysisFrame(handPose: handPose, facePose: facePose, timestamp: timestamp)
        } catch {
            return nil
        }
    }

    private func makeHandPoseFrame(timestamp: Date) throws -> HandPoseFrame? {
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

        return HandPoseFrame(points: points, timestamp: timestamp)
    }

    private func makeFacePoseFrame(timestamp: Date) -> FacePoseFrame? {
        guard
            let face = faceRectanglesRequest.results?
                .max(by: { $0.boundingBox.width * $0.boundingBox.height < $1.boundingBox.width * $1.boundingBox.height })
        else {
            return nil
        }

        let boundingBox = face.boundingBox
        let centerX = boundingBox.origin.x + (boundingBox.width / 2)
        let centerY = boundingBox.origin.y + (boundingBox.height / 2)

        return FacePoseFrame(
            centerX: Float(centerX),
            centerY: Float(centerY),
            width: Float(boundingBox.width),
            height: Float(boundingBox.height),
            confidence: face.confidence,
            timestamp: timestamp
        )
    }
}
