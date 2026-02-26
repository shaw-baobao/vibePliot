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
    private lazy var menuBarController = MenuBarController(state: appState)
    private lazy var gestureRecognizer = GestureRecognizer(settings: bindingManager.settings)

    private var settingsWindowController: NSWindowController?
    private var hasReceivedCameraFrame = false
    private var lastNoHandStatusAt = Date.distantPast

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
                onOpenCameraPrivacySettings: { [weak self] in
                    self?.permissionManager.openCameraPrivacySettings()
                },
                onOpenAccessibilityPrivacySettings: { [weak self] in
                    self?.permissionManager.openAccessibilityPrivacySettings()
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

        NSLog("VibePilot launched. Menu bar app is ready.")
        menuBarController.refresh()
    }

    func applicationWillTerminate(_ notification: Notification) {
        cameraManager.stop()
        do {
            try bindingManager.save()
        } catch {
            NSLog("Failed to save settings: \(error.localizedDescription)")
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
        let view = SettingsView(settings: bindingManager.settings, bindings: bindingManager.bindings)
        let hostingController = NSHostingController(rootView: view)

        let window: NSWindow
        if let existingWindow = settingsWindowController?.window {
            window = existingWindow
            window.contentViewController = hostingController
        } else {
            window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 460, height: 420),
                styleMask: [.titled, .closable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            window.title = "VibePilot Settings"
            window.isReleasedWhenClosed = false
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
        menuBarController.refresh()

        switch permissionManager.cameraAuthorizationStatus() {
        case .authorized:
            startRecognitionSession()
        case .notDetermined:
            appState.statusMessage = "Requesting camera permission..."
            menuBarController.refresh()

            permissionManager.requestCameraPermission { [weak self] granted in
                DispatchQueue.main.async {
                    guard let self else { return }
                    guard self.appState.isRecognitionRunning else { return }

                    if granted {
                        self.startRecognitionSession()
                    } else {
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
        switch permissionManager.cameraAuthorizationStatus() {
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

        if !permissionManager.isAccessibilityTrusted() {
            _ = permissionManager.promptAccessibilityPermission()
            appState.lastErrorMessage = "Accessibility not granted. Gesture detection will run, but keyboard/mouse injection may fail."
        } else {
            appState.lastErrorMessage = nil
        }

        gestureRecognizer.update(settings: bindingManager.settings)
        cameraManager.preferredFPS = bindingManager.settings.fps

        do {
            try cameraManager.start()
            appState.statusMessage = "Starting camera..."
            NSLog("VibePilot recognition started.")
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
        NSLog("VibePilot recognition stopped.")
        menuBarController.refresh()
    }

    private func failRecognitionStart(message: String) {
        cameraManager.stop()
        appState.isRecognitionRunning = false
        appState.isRecognitionPaused = false
        appState.statusMessage = "Start failed"
        appState.lastErrorMessage = message
        NSLog("VibePilot failed to start: \(message)")
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
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.appState.statusMessage = self.appState.isRecognitionPaused
                    ? "Camera active (paused)"
                    : "Camera active. Looking for hand..."
                self.menuBarController.refresh()
            }
        }

        guard let handPoseFrame = visionEngine.analyze(sampleBuffer) else {
            let now = Date()
            if now.timeIntervalSince(lastNoHandStatusAt) > 1.5 {
                lastNoHandStatusAt = now
                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }
                    guard self.appState.isRecognitionRunning else { return }
                    if !self.appState.isRecognitionPaused {
                        self.appState.statusMessage = "Camera active. No hand detected."
                        self.menuBarController.refresh()
                    }
                }
            }
            return
        }

        if let trigger = gestureRecognizer.process(frame: handPoseFrame, now: handPoseFrame.timestamp) {
            DispatchQueue.main.async { [weak self] in
                self?.handleGestureTrigger(trigger)
            }
        } else {
            let isPaused = DispatchQueue.main.sync { appState.isRecognitionPaused }
            if !isPaused {
                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }
                    guard self.appState.isRecognitionRunning, !self.appState.isRecognitionPaused else { return }
                    self.appState.statusMessage = "Hand detected. Waiting for gesture..."
                    self.menuBarController.refresh()
                }
            }
        }
    }

    private func handleGestureTrigger(_ trigger: GestureTrigger) {
        guard appState.isRecognitionRunning else {
            return
        }

        appState.latestTrigger = trigger
        let confidencePercent = Int((trigger.confidence * 100).rounded())
        NSLog("Gesture detected: \(trigger.event.rawValue) (\(confidencePercent)%)")

        if trigger.event == .openPalm {
            appState.isRecognitionPaused.toggle()
            appState.statusMessage = appState.isRecognitionPaused
                ? "Paused by Open Palm"
                : "Resumed by Open Palm"
            menuBarController.refresh()
            return
        }

        if appState.isRecognitionPaused {
            appState.statusMessage = "Paused (Open Palm to resume)"
            menuBarController.refresh()
            return
        }

        let action = bindingManager.binding(for: trigger.event)
        if case .none = action {
            appState.statusMessage = "Gesture \(trigger.event.displayName) detected (no binding)"
            menuBarController.refresh()
            return
        }

        do {
            try inputInjector.inject(action)
            appState.statusMessage = "Triggered \(trigger.event.displayName) -> \(action.displayText)"
            appState.lastErrorMessage = nil
        } catch {
            appState.statusMessage = "Gesture detected, injection failed"
            appState.lastErrorMessage = error.localizedDescription
        }

        menuBarController.refresh()
    }
}
