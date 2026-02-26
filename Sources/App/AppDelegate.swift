import AppKit
import AVFoundation
import SwiftUI
import VibePilotCore

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let appState = AppState()
    private let bindingManager = BindingManager()
    private let permissionManager = PermissionManager()
    private let cameraManager = CameraManager()
    private let visionEngine = VisionEngine()
    private let inputInjector = InputInjector()
    private let logger = VibePilotLogger()
    private lazy var menuBarController = MenuBarController(state: appState)
    private lazy var gestureRecognizer = GestureRecognizer(settings: bindingManager.settings)
    private lazy var headGestureRecognizer = HeadGestureRecognizer(settings: bindingManager.settings)

    private var settingsWindowController: NSWindowController?
    private var hasReceivedCameraFrame = false
    private var lastNoHandStatusAt = Date.distantPast
    private var lastHandSeenStatusAt = Date.distantPast
    private var lastFaceSeenStatusAt = Date.distantPast

    func applicationDidFinishLaunching(_ notification: Notification) {
        cameraManager.preferredFPS = bindingManager.settings.fps
        cameraManager.onSampleBuffer = { [weak self] sampleBuffer in
            self?.handleCameraSampleBuffer(sampleBuffer)
        }

        appState.statusMessage = "Idle"

        menuBarController.install(
            callbacks: .init(
                onToggleRecognition: { [weak self] isEnabled in
                    self?.handleRecognitionToggle(isEnabled: isEnabled)
                },
                onTogglePause: { [weak self] isPaused in
                    self?.appState.isRecognitionPaused = isPaused
                    self?.menuBarController.refresh()
                },
                onOpenSettings: { [weak self] in
                    self?.showSettingsWindow()
                },
                onQuit: {
                    NSApp.terminate(nil)
                },
                cameraPermissionSummary: { [weak self] in
                    self?.cameraPermissionSummary() ?? "Unknown"
                },
                accessibilityPermissionSummary: { [weak self] in
                    self?.accessibilityPermissionSummary() ?? "Unknown"
                }
            )
        )

        log("Session log file: \(logger.logFileURL.path)")
        log("App launched. Menu bar app is ready.")
        menuBarController.refresh()
    }

    func applicationWillTerminate(_ notification: Notification) {
        cameraManager.stop()
        do {
            try bindingManager.save()
        } catch {
            log("Failed to save settings: \(error.localizedDescription)")
        }
    }

    private func handleRecognitionToggle(isEnabled: Bool) {
        if isEnabled {
            requestRecognitionStart()
        } else {
            stopRecognition()
        }
    }

    private func showSettingsWindow() {
        log("Open Settings window.")

        let view = SettingsView(
            settings: bindingManager.settings,
            bindings: bindingManager.bindings,
            cameraPermissionProvider: { [weak self] in
                self?.cameraPermissionSummary() ?? "Unknown"
            },
            accessibilityPermissionProvider: { [weak self] in
                self?.accessibilityPermissionSummary() ?? "Unknown"
            },
            logFilePath: logger.logFileURL.path,
            onOpenCameraPrivacySettings: { [weak self] in
                self?.log("Open Camera Privacy Settings requested.")
                self?.permissionManager.openCameraPrivacySettings()
            },
            onOpenAccessibilityPrivacySettings: { [weak self] in
                self?.log("Open Accessibility Privacy Settings requested.")
                self?.permissionManager.openAccessibilityPrivacySettings()
            },
            onOpenLogFile: { [weak self] in
                guard let self else { return }
                self.log("Open log file requested.")
                NSWorkspace.shared.open(self.logger.logFileURL)
            }
        )
        let hostingController = NSHostingController(rootView: view)

        let window: NSWindow
        if let existingWindow = settingsWindowController?.window {
            window = existingWindow
            window.contentViewController = hostingController
        } else {
            window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 620, height: 720),
                styleMask: [.titled, .closable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            window.title = "VibePilot Settings"
            window.isReleasedWhenClosed = false
            window.minSize = NSSize(width: 580, height: 660)
            window.contentViewController = hostingController
            settingsWindowController = NSWindowController(window: window)
        }

        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func requestRecognitionStart() {
        appState.isRecognitionRunning = true
        appState.lastErrorMessage = nil
        appState.statusMessage = "Checking camera permission..."
        log("Start recognition requested.")
        menuBarController.refresh()

        let cameraStatus = permissionManager.cameraAuthorizationStatus()
        log("Camera permission status: \(cameraPermissionSummary(for: cameraStatus))")

        switch cameraStatus {
        case .authorized:
            startRecognitionSession()
        case .notDetermined:
            appState.statusMessage = "Requesting camera permission..."
            log("Requesting camera permission...")
            menuBarController.refresh()

            permissionManager.requestCameraPermission { [weak self] granted in
                DispatchQueue.main.async {
                    guard let self else { return }
                    guard self.appState.isRecognitionRunning else { return }

                    if granted {
                        self.log("Camera permission granted.")
                        self.startRecognitionSession()
                    } else {
                        self.log("Camera permission denied by user.")
                        self.failRecognitionStart(message: "Camera permission denied. Open System Settings > Privacy & Security > Camera.")
                    }
                }
            }
        case .denied, .restricted:
            failRecognitionStart(message: "Camera permission denied. Open System Settings > Privacy & Security > Camera.")
        @unknown default:
            failRecognitionStart(message: "Unknown camera permission state.")
        }
    }

    private func cameraPermissionSummary() -> String {
        cameraPermissionSummary(for: permissionManager.cameraAuthorizationStatus())
    }

    private func cameraPermissionSummary(for status: AVAuthorizationStatus) -> String {
        switch status {
        case .authorized:
            return "Authorized"
        case .notDetermined:
            return "Not Determined"
        case .denied:
            return "Denied"
        case .restricted:
            return "Restricted"
        @unknown default:
            return "Unknown"
        }
    }

    private func accessibilityPermissionSummary() -> String {
        permissionManager.isAccessibilityTrusted() ? "Authorized" : "Not Authorized"
    }

    private func startRecognitionSession() {
        hasReceivedCameraFrame = false
        lastNoHandStatusAt = .distantPast
        lastHandSeenStatusAt = .distantPast
        lastFaceSeenStatusAt = .distantPast

        if !permissionManager.isAccessibilityTrusted() {
            _ = permissionManager.promptAccessibilityPermission()
            appState.lastErrorMessage = "Accessibility not granted. Gesture detection will run, but keyboard/mouse injection may fail."
            log("Accessibility not granted. Prompted user. Gesture detection can run; input injection may fail.")
        } else {
            appState.lastErrorMessage = nil
            log("Accessibility is authorized.")
        }

        gestureRecognizer.update(settings: bindingManager.settings)
        headGestureRecognizer.update(settings: bindingManager.settings)
        cameraManager.preferredFPS = bindingManager.settings.fps

        do {
            try cameraManager.start()
            appState.statusMessage = "Starting camera..."
            log("Recognition session started. Waiting for camera frames...")
        } catch {
            failRecognitionStart(message: error.localizedDescription)
            return
        }

        menuBarController.refresh()
    }

    private func stopRecognition() {
        cameraManager.stop()
        appState.isRecognitionRunning = false
        appState.isRecognitionPaused = false
        appState.statusMessage = "Stopped"
        appState.lastErrorMessage = nil
        log("Recognition stopped.")
        menuBarController.refresh()
    }

    private func failRecognitionStart(message: String) {
        cameraManager.stop()
        appState.isRecognitionRunning = false
        appState.isRecognitionPaused = false
        appState.statusMessage = "Start failed"
        appState.lastErrorMessage = message
        log("Failed to start recognition: \(message)")
        menuBarController.refresh()
    }

    private func handleCameraSampleBuffer(_ sampleBuffer: CMSampleBuffer) {
        let shouldProcess = DispatchQueue.main.sync {
            appState.isRecognitionRunning
        }

        guard shouldProcess else {
            return
        }

        if !hasReceivedCameraFrame {
            hasReceivedCameraFrame = true
            log("First camera frame received.")
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.appState.statusMessage = self.appState.isRecognitionPaused
                    ? "Camera active (paused)"
                    : "Camera active. Looking for hand..."
                self.menuBarController.refresh()
            }
        }

        guard let analysis = visionEngine.analyze(sampleBuffer) else {
            let now = Date()
            if now.timeIntervalSince(lastNoHandStatusAt) > 1.5 {
                lastNoHandStatusAt = now
                log("No hand/face detected in current frame window.")
                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }
                    guard self.appState.isRecognitionRunning else { return }
                    if !self.appState.isRecognitionPaused {
                        self.appState.statusMessage = "Camera active. No hand/face detected."
                        self.menuBarController.refresh()
                    }
                }
            }
            return
        }

        if let handPoseFrame = analysis.handPose,
           let trigger = gestureRecognizer.process(frame: handPoseFrame, now: analysis.timestamp) {
            DispatchQueue.main.async { [weak self] in
                self?.handleGestureTrigger(trigger)
            }
            return
        }

        if let facePoseFrame = analysis.facePose,
           let trigger = headGestureRecognizer.process(face: facePoseFrame, now: analysis.timestamp) {
            DispatchQueue.main.async { [weak self] in
                self?.handleGestureTrigger(trigger)
            }
            return
        }

        let isPaused = DispatchQueue.main.sync { appState.isRecognitionPaused }
        let now = Date()
        guard !isPaused else { return }

        if analysis.handPose != nil, now.timeIntervalSince(lastHandSeenStatusAt) > 1.5 {
            lastHandSeenStatusAt = now
            log("Hand landmarks detected. Waiting for stable gesture classification...")
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                guard self.appState.isRecognitionRunning, !self.appState.isRecognitionPaused else { return }
                self.appState.statusMessage = "Hand detected. Waiting for gesture..."
                self.menuBarController.refresh()
            }
            return
        }

        if analysis.facePose != nil, now.timeIntervalSince(lastFaceSeenStatusAt) > 1.5 {
            lastFaceSeenStatusAt = now
            log("Face detected. Waiting for head gesture classification (nod/shake)...")
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                guard self.appState.isRecognitionRunning, !self.appState.isRecognitionPaused else { return }
                self.appState.statusMessage = "Face detected. Waiting for nod/shake..."
                self.menuBarController.refresh()
            }
        }
    }

    private func handleGestureTrigger(_ trigger: GestureTrigger) {
        guard appState.isRecognitionRunning else {
            return
        }

        appState.latestTrigger = trigger
        let confidencePercent = Int((trigger.confidence * 100).rounded())
        log("Gesture detected: \(trigger.event.rawValue) (\(confidencePercent)%)")

        if trigger.event == .openPalm {
            appState.isRecognitionPaused.toggle()
            appState.statusMessage = appState.isRecognitionPaused
                ? "Paused by Open Palm"
                : "Resumed by Open Palm"
            log(appState.isRecognitionPaused ? "Recognition paused by Open Palm." : "Recognition resumed by Open Palm.")
            menuBarController.refresh()
            return
        }

        if appState.isRecognitionPaused {
            appState.statusMessage = "Paused (Open Palm to resume)"
            log("Gesture ignored because recognition is paused.")
            menuBarController.refresh()
            return
        }

        let action = bindingManager.binding(for: trigger.event)
        if case .none = action {
            appState.statusMessage = "Gesture \(trigger.event.displayName) detected (no binding)"
            log("Gesture \(trigger.event.rawValue) detected but no binding is configured.")
            menuBarController.refresh()
            return
        }

        do {
            try inputInjector.inject(action)
            appState.statusMessage = "Triggered \(trigger.event.displayName) -> \(action.displayText)"
            appState.lastErrorMessage = nil
            log("Input injection succeeded: \(trigger.event.rawValue) -> \(action.displayText)")
        } catch {
            appState.statusMessage = "Gesture detected, injection failed"
            appState.lastErrorMessage = error.localizedDescription
            log("Input injection failed for \(trigger.event.rawValue): \(error.localizedDescription)")
        }

        menuBarController.refresh()
    }

    @discardableResult
    private func log(_ message: String) -> String {
        logger.log(message)
    }
}
