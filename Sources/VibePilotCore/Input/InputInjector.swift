import AppKit
import ApplicationServices
import Foundation

public enum InputInjectorError: Error {
    case eventCreationFailed
}

public final class InputInjector {
    public init() {}

    public func inject(_ action: BindingAction) throws {
        switch action {
        case .none:
            return
        case .keyboard(let keyBinding):
            try injectKeyboard(binding: keyBinding)
        case .mouse(let mouseBinding):
            try injectMouse(binding: mouseBinding)
        }
    }

    private func injectKeyboard(binding: KeyBinding) throws {
        guard
            let keyDown = CGEvent(keyboardEventSource: nil, virtualKey: CGKeyCode(binding.keyCode), keyDown: true),
            let keyUp = CGEvent(keyboardEventSource: nil, virtualKey: CGKeyCode(binding.keyCode), keyDown: false)
        else {
            throw InputInjectorError.eventCreationFailed
        }

        keyDown.flags = binding.cgEventFlags
        keyUp.flags = binding.cgEventFlags

        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)
    }

    private func injectMouse(binding: MouseBinding) throws {
        let location = NSEvent.mouseLocation
        let mouseType: CGEventType
        let mouseButton: CGMouseButton

        switch binding.action {
        case .leftClick:
            mouseType = .leftMouseDown
            mouseButton = .left
        case .rightClick:
            mouseType = .rightMouseDown
            mouseButton = .right
        }

        guard
            let downEvent = CGEvent(
                mouseEventSource: nil,
                mouseType: mouseType,
                mouseCursorPosition: location,
                mouseButton: mouseButton
            )
        else {
            throw InputInjectorError.eventCreationFailed
        }

        let upType: CGEventType = (binding.action == .leftClick) ? .leftMouseUp : .rightMouseUp
        guard
            let upEvent = CGEvent(
                mouseEventSource: nil,
                mouseType: upType,
                mouseCursorPosition: location,
                mouseButton: mouseButton
            )
        else {
            throw InputInjectorError.eventCreationFailed
        }

        downEvent.post(tap: .cghidEventTap)
        upEvent.post(tap: .cghidEventTap)
    }
}

