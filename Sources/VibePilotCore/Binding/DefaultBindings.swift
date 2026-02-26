import Foundation

public enum DefaultBindings {
    public static func make() -> [GestureEvent: BindingAction] {
        [
            .ok: .keyboard(KeyBinding(keyCode: 36)),
            .fist: .keyboard(KeyBinding(keyCode: 53)),
            .openPalm: .none,
            .nod: .keyboard(KeyBinding(keyCode: 36)),
            .shake: .keyboard(KeyBinding(keyCode: 53))
        ]
    }
}
