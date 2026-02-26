import Foundation
import SwiftUI

public struct SettingsView: View {
    private let settings: AppSettings
    private let bindings: [GestureEvent: BindingAction]

    public init(settings: AppSettings, bindings: [GestureEvent: BindingAction]) {
        self.settings = settings
        self.bindings = bindings
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

            Spacer()

            Text("This is a scaffold view. Binding editor and live settings apply are TODO.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(width: 440, height: 380)
    }
}
