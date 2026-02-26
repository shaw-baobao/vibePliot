import Foundation
import Combine
import SwiftUI

public struct SettingsView: View {
    private let settings: AppSettings
    private let bindings: [GestureEvent: BindingAction]
    private let cameraPermissionProvider: (() -> String)?
    private let accessibilityPermissionProvider: (() -> String)?
    private let logFilePath: String
    private let onOpenCameraPrivacySettings: (() -> Void)?
    private let onOpenAccessibilityPrivacySettings: (() -> Void)?
    private let onOpenLogFile: (() -> Void)?

    @State private var logText = "No logs yet."
    @State private var cameraPermissionText = "Unknown"
    @State private var accessibilityPermissionText = "Unknown"
    private let refreshTimer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()

    public init(
        settings: AppSettings,
        bindings: [GestureEvent: BindingAction],
        cameraPermissionProvider: (() -> String)? = nil,
        accessibilityPermissionProvider: (() -> String)? = nil,
        logFilePath: String,
        onOpenCameraPrivacySettings: (() -> Void)? = nil,
        onOpenAccessibilityPrivacySettings: (() -> Void)? = nil,
        onOpenLogFile: (() -> Void)? = nil
    ) {
        self.settings = settings
        self.bindings = bindings
        self.cameraPermissionProvider = cameraPermissionProvider
        self.accessibilityPermissionProvider = accessibilityPermissionProvider
        self.logFilePath = logFilePath
        self.onOpenCameraPrivacySettings = onOpenCameraPrivacySettings
        self.onOpenAccessibilityPrivacySettings = onOpenAccessibilityPrivacySettings
        self.onOpenLogFile = onOpenLogFile
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("VibePilot Settings")
                .font(.title2)
                .fontWeight(.semibold)

            GroupBox("Recognition") {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Confidence Threshold")
                        Spacer()
                        Text(String(format: "%.2f", settings.confidenceThreshold))
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Frames Required")
                        Spacer()
                        Text("\(settings.framesRequired)")
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Cooldown")
                        Spacer()
                        Text("\(settings.cooldownMs) ms")
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Camera FPS")
                        Spacer()
                        Text("\(settings.fps)")
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            GroupBox("Bindings") {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(GestureEvent.allCases, id: \.self) { event in
                        HStack {
                            Text(event.displayName)
                            Spacer()
                            Text((bindings[event] ?? .none).displayText)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            GroupBox("Permissions") {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Camera")
                        Spacer()
                        Text(cameraPermissionText)
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("Accessibility")
                        Spacer()
                        Text(accessibilityPermissionText)
                            .foregroundStyle(.secondary)
                    }

                    HStack(spacing: 10) {
                        Button("Open Camera Privacy Settings") {
                            onOpenCameraPrivacySettings?()
                            reloadPermissions()
                        }

                        Button("Open Accessibility Privacy Settings") {
                            onOpenAccessibilityPrivacySettings?()
                            reloadPermissions()
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            GroupBox("Recent Logs") {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(logFilePath)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                        Spacer()
                        Button("Open Log File") {
                            onOpenLogFile?()
                        }
                        Button("Refresh") {
                            reloadLogs()
                        }
                    }

                    ScrollView {
                        Text(logText)
                            .font(.system(size: 11, weight: .regular, design: .monospaced))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .textSelection(.enabled)
                    }
                    .frame(minHeight: 120, maxHeight: 160)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Spacer()

            Text("Settings editor is still a scaffold. Logs refresh automatically every second while this window is open.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(width: 560, height: 620)
        .onAppear {
            reloadAll()
        }
        .onReceive(refreshTimer) { _ in
            reloadAll()
        }
    }

    private func reloadAll() {
        reloadPermissions()
        reloadLogs()
    }

    private func reloadPermissions() {
        cameraPermissionText = cameraPermissionProvider?() ?? "Unknown"
        accessibilityPermissionText = accessibilityPermissionProvider?() ?? "Unknown"
    }

    private func reloadLogs() {
        guard let content = try? String(contentsOfFile: logFilePath, encoding: .utf8) else {
            logText = "No log file found yet."
            return
        }

        let lines = content
            .split(separator: "\n", omittingEmptySubsequences: false)
            .suffix(80)
            .map(String.init)

        logText = lines.isEmpty ? "No logs yet." : lines.joined(separator: "\n")
    }
}
