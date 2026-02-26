import AVFoundation
import CoreMedia
import Foundation

public enum CameraManagerError: LocalizedError {
    case noCameraAvailable
    case failedToCreateInput
    case failedToAddInput
    case failedToAddOutput
    case configurationFailed(String)

    public var errorDescription: String? {
        switch self {
        case .noCameraAvailable:
            return "No camera device is available."
        case .failedToCreateInput:
            return "Failed to create camera input."
        case .failedToAddInput:
            return "Failed to attach camera input to capture session."
        case .failedToAddOutput:
            return "Failed to attach camera output to capture session."
        case .configurationFailed(let message):
            return message
        }
    }
}

public final class CameraManager: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    public let session = AVCaptureSession()
    public var preferredFPS: Int
    public var onSampleBuffer: ((CMSampleBuffer) -> Void)?

    private let sessionQueue = DispatchQueue(label: "com.vibepilot.camera.session")
    private let sampleBufferQueue = DispatchQueue(label: "com.vibepilot.camera.samples")
    private let videoOutput = AVCaptureVideoDataOutput()
    private var isConfigured = false

    public override init() {
        self.preferredFPS = AppSettings.default.fps
        super.init()
        session.sessionPreset = .medium
    }

    public func start() throws {
        try configureIfNeeded()

        sessionQueue.async { [weak self] in
            guard let self else { return }
            guard !self.session.isRunning else { return }
            self.session.startRunning()
        }
    }

    public func stop() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            guard self.session.isRunning else { return }
            self.session.stopRunning()
        }
    }

    private func configureIfNeeded() throws {
        guard !isConfigured else { return }

        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera, .externalUnknown],
            mediaType: .video,
            position: .unspecified
        )

        guard let cameraDevice = discoverySession.devices.first ?? AVCaptureDevice.default(for: .video) else {
            throw CameraManagerError.noCameraAvailable
        }

        guard let input = try? AVCaptureDeviceInput(device: cameraDevice) else {
            throw CameraManagerError.failedToCreateInput
        }

        session.beginConfiguration()
        defer { session.commitConfiguration() }

        if session.canAddInput(input) {
            session.addInput(input)
        } else {
            throw CameraManagerError.failedToAddInput
        }

        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.setSampleBufferDelegate(self, queue: sampleBufferQueue)
        videoOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)
        ]

        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
        } else {
            throw CameraManagerError.failedToAddOutput
        }

        if let connection = videoOutput.connection(with: .video), connection.isVideoOrientationSupported {
            connection.videoOrientation = .portrait
        }

        try applyPreferredFPS(to: cameraDevice)

        isConfigured = true
    }

    private func applyPreferredFPS(to device: AVCaptureDevice) throws {
        let fps = max(5, min(60, preferredFPS))
        let targetFPS = Double(fps)
        let supportsFPS = device.activeFormat.videoSupportedFrameRateRanges.contains { range in
            range.minFrameRate <= targetFPS && targetFPS <= range.maxFrameRate
        }

        guard supportsFPS else { return }

        do {
            try device.lockForConfiguration()
            defer { device.unlockForConfiguration() }

            let duration = CMTime(value: 1, timescale: CMTimeScale(fps))
            device.activeVideoMinFrameDuration = duration
            device.activeVideoMaxFrameDuration = duration
        } catch {
            throw CameraManagerError.configurationFailed("Failed to set camera FPS.")
        }
    }

    public func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        _ = output
        _ = connection
        onSampleBuffer?(sampleBuffer)
    }
}
