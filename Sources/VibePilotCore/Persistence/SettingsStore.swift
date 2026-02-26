import Foundation

public struct PersistedConfiguration: Codable, Equatable, Sendable {
    public var schemaVersion: Int
    public var settings: AppSettings
    public var bindings: [GestureEvent: BindingAction]

    public init(
        schemaVersion: Int,
        settings: AppSettings,
        bindings: [GestureEvent: BindingAction]
    ) {
        self.schemaVersion = schemaVersion
        self.settings = settings
        self.bindings = bindings
    }

    public static let defaultValue = PersistedConfiguration(
        schemaVersion: SettingsMigration.currentSchemaVersion,
        settings: .default,
        bindings: DefaultBindings.make()
    )
}

public final class SettingsStore {
    private let defaults: UserDefaults
    private let configurationKey = "vibepilot.configuration"
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func loadConfiguration() -> PersistedConfiguration {
        guard let data = defaults.data(forKey: configurationKey) else {
            return .defaultValue
        }

        guard let configuration = try? decoder.decode(PersistedConfiguration.self, from: data) else {
            return .defaultValue
        }

        if configuration.schemaVersion != SettingsMigration.currentSchemaVersion {
            return .defaultValue
        }

        return configuration
    }

    public func saveConfiguration(_ configuration: PersistedConfiguration) throws {
        let data = try encoder.encode(configuration)
        defaults.set(data, forKey: configurationKey)
    }
}

