import Foundation

public final class BindingManager {
    private let store: SettingsStore

    public private(set) var settings: AppSettings
    public private(set) var bindings: [GestureEvent: BindingAction]

    public init(store: SettingsStore = SettingsStore()) {
        self.store = store
        let configuration = store.loadConfiguration()
        self.settings = configuration.settings
        self.bindings = Self.mergedBindings(configuration.bindings)
    }

    public func reload() {
        let configuration = store.loadConfiguration()
        settings = configuration.settings
        bindings = Self.mergedBindings(configuration.bindings)
    }

    public func binding(for event: GestureEvent) -> BindingAction {
        bindings[event] ?? .none
    }

    public func updateBinding(_ action: BindingAction, for event: GestureEvent) {
        bindings[event] = action
    }

    public func updateSettings(_ update: (inout AppSettings) -> Void) {
        update(&settings)
    }

    public func save() throws {
        let configuration = PersistedConfiguration(
            schemaVersion: SettingsMigration.currentSchemaVersion,
            settings: settings,
            bindings: bindings
        )
        try store.saveConfiguration(configuration)
    }

    private static func mergedBindings(_ existing: [GestureEvent: BindingAction]) -> [GestureEvent: BindingAction] {
        var merged = DefaultBindings.make()
        for (event, action) in existing {
            merged[event] = action
        }
        return merged
    }
}
