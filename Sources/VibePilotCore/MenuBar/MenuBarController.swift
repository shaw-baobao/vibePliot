import AppKit
import Foundation

public final class MenuBarController: NSObject {
    public struct Callbacks {
        public var onToggleRecognition: ((Bool) -> Void)?
        public var onTogglePause: ((Bool) -> Void)?
        public var onOpenSettings: (() -> Void)?
        public var onOpenCameraPrivacySettings: (() -> Void)?
        public var onOpenAccessibilityPrivacySettings: (() -> Void)?
        public var onQuit: (() -> Void)?
        public var cameraPermissionSummary: (() -> String)?
        public var accessibilityPermissionSummary: (() -> String)?

        public init(
            onToggleRecognition: ((Bool) -> Void)? = nil,
            onTogglePause: ((Bool) -> Void)? = nil,
            onOpenSettings: (() -> Void)? = nil,
            onOpenCameraPrivacySettings: (() -> Void)? = nil,
            onOpenAccessibilityPrivacySettings: (() -> Void)? = nil,
            onQuit: (() -> Void)? = nil,
            cameraPermissionSummary: (() -> String)? = nil,
            accessibilityPermissionSummary: (() -> String)? = nil
        ) {
            self.onToggleRecognition = onToggleRecognition
            self.onTogglePause = onTogglePause
            self.onOpenSettings = onOpenSettings
            self.onOpenCameraPrivacySettings = onOpenCameraPrivacySettings
            self.onOpenAccessibilityPrivacySettings = onOpenAccessibilityPrivacySettings
            self.onQuit = onQuit
            self.cameraPermissionSummary = cameraPermissionSummary
            self.accessibilityPermissionSummary = accessibilityPermissionSummary
        }
    }

    private let state: AppState
    private let statusItem: NSStatusItem
    private let menu = NSMenu()
    private var callbacks = Callbacks()

    public init(state: AppState) {
        self.state = state
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        super.init()
    }

    public func install(callbacks: Callbacks) {
        self.callbacks = callbacks
        statusItem.button?.title = "VP"
        statusItem.menu = menu
        rebuildMenu()
    }

    public func refresh() {
        statusItem.button?.title = titleForCurrentState()
        rebuildMenu()
    }

    private func titleForCurrentState() -> String {
        if state.isRecognitionPaused {
            return "VP Paused"
        }
        if state.isRecognitionRunning {
            return "VP On"
        }
        return "VP Off"
    }

    private func rebuildMenu() {
        menu.removeAllItems()

        menu.addItem(makeInfoItem())
        menu.addItem(NSMenuItem.separator())
        menu.addItem(makePermissionSummaryItem(title: "Camera", text: callbacks.cameraPermissionSummary?() ?? "Unknown"))
        menu.addItem(makePermissionSummaryItem(title: "Accessibility", text: callbacks.accessibilityPermissionSummary?() ?? "Unknown"))
        menu.addItem(makeOpenCameraPrivacyItem())
        menu.addItem(makeOpenAccessibilityPrivacyItem())
        menu.addItem(NSMenuItem.separator())
        menu.addItem(makeToggleRecognitionItem())
        menu.addItem(makeTogglePauseItem())
        menu.addItem(NSMenuItem.separator())
        menu.addItem(makeSettingsItem())
        menu.addItem(NSMenuItem.separator())
        menu.addItem(makeQuitItem())
    }

    private func makeInfoItem() -> NSMenuItem {
        let text: String
        if let error = state.lastErrorMessage, !error.isEmpty {
            text = "Warning: \(error)"
        } else if let statusMessage = state.statusMessage, !statusMessage.isEmpty {
            text = statusMessage
        } else if let trigger = state.latestTrigger {
            text = "Last: \(trigger.event.displayName)"
        } else {
            text = "Ready"
        }

        let item = NSMenuItem(title: text, action: nil, keyEquivalent: "")
        item.isEnabled = false
        return item
    }

    private func makePermissionSummaryItem(title: String, text: String) -> NSMenuItem {
        let item = NSMenuItem(title: "\(title): \(text)", action: nil, keyEquivalent: "")
        item.isEnabled = false
        return item
    }

    private func makeOpenCameraPrivacyItem() -> NSMenuItem {
        let item = NSMenuItem(title: "Open Camera Privacy Settings", action: #selector(openCameraPrivacySettings), keyEquivalent: "")
        item.target = self
        return item
    }

    private func makeOpenAccessibilityPrivacyItem() -> NSMenuItem {
        let item = NSMenuItem(title: "Open Accessibility Privacy Settings", action: #selector(openAccessibilityPrivacySettings), keyEquivalent: "")
        item.target = self
        return item
    }

    private func makeToggleRecognitionItem() -> NSMenuItem {
        let title = state.isRecognitionRunning ? "Stop Recognition" : "Start Recognition"
        let item = NSMenuItem(title: title, action: #selector(toggleRecognition), keyEquivalent: "")
        item.target = self
        return item
    }

    private func makeTogglePauseItem() -> NSMenuItem {
        let title = state.isRecognitionPaused ? "Resume Recognition" : "Pause Recognition"
        let item = NSMenuItem(title: title, action: #selector(togglePause), keyEquivalent: "")
        item.target = self
        item.isEnabled = state.isRecognitionRunning
        return item
    }

    private func makeSettingsItem() -> NSMenuItem {
        let item = NSMenuItem(title: "Open Settings…", action: #selector(openSettings), keyEquivalent: ",")
        item.target = self
        return item
    }

    private func makeQuitItem() -> NSMenuItem {
        let item = NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q")
        item.target = self
        return item
    }

    @objc
    private func toggleRecognition() {
        state.isRecognitionRunning.toggle()
        if !state.isRecognitionRunning {
            state.isRecognitionPaused = false
        }
        callbacks.onToggleRecognition?(state.isRecognitionRunning)
        refresh()
    }

    @objc
    private func togglePause() {
        guard state.isRecognitionRunning else {
            return
        }
        state.isRecognitionPaused.toggle()
        callbacks.onTogglePause?(state.isRecognitionPaused)
        refresh()
    }

    @objc
    private func openSettings() {
        callbacks.onOpenSettings?()
    }

    @objc
    private func openCameraPrivacySettings() {
        callbacks.onOpenCameraPrivacySettings?()
    }

    @objc
    private func openAccessibilityPrivacySettings() {
        callbacks.onOpenAccessibilityPrivacySettings?()
    }

    @objc
    private func quitApp() {
        callbacks.onQuit?()
    }
}
