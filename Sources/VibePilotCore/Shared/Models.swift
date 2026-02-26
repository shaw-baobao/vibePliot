import Foundation
import ApplicationServices

public enum GestureEvent: String, CaseIterable, Codable, Hashable, Sendable {
    case ok
    case fist
    case openPalm
    case nod
    case shake

    public var displayName: String {
        switch self {
        case .ok:
            return "OK"
        case .fist:
            return "Fist"
        case .openPalm:
            return "Open Palm"
        case .nod:
            return "Nod"
        case .shake:
            return "Shake"
        }
    }
}

public enum KeyModifier: String, CaseIterable, Codable, Sendable {
    case command
    case control
    case option
    case shift

    var cgEventFlag: CGEventFlags {
        switch self {
        case .command:
            return .maskCommand
        case .control:
            return .maskControl
        case .option:
            return .maskAlternate
        case .shift:
            return .maskShift
        }
    }
}

public struct KeyBinding: Codable, Equatable, Sendable {
    public var keyCode: UInt16
    public var modifiers: [KeyModifier]

    public init(keyCode: UInt16, modifiers: [KeyModifier] = []) {
        self.keyCode = keyCode
        self.modifiers = modifiers
    }

    public var cgEventFlags: CGEventFlags {
        modifiers.reduce(into: []) { partialResult, modifier in
            partialResult.insert(modifier.cgEventFlag)
        }
    }
}

public enum MouseActionType: String, Codable, Sendable {
    case leftClick
    case rightClick
}

public struct MouseBinding: Codable, Equatable, Sendable {
    public var action: MouseActionType

    public init(action: MouseActionType) {
        self.action = action
    }
}

public enum BindingAction: Equatable, Sendable {
    case none
    case keyboard(KeyBinding)
    case mouse(MouseBinding)
}

extension BindingAction: Codable {
    private enum CodingKeys: String, CodingKey {
        case type
        case keyBinding
        case mouseBinding
    }

    private enum Kind: String, Codable {
        case none
        case keyboard
        case mouse
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let kind = try container.decode(Kind.self, forKey: .type)

        switch kind {
        case .none:
            self = .none
        case .keyboard:
            self = .keyboard(try container.decode(KeyBinding.self, forKey: .keyBinding))
        case .mouse:
            self = .mouse(try container.decode(MouseBinding.self, forKey: .mouseBinding))
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .none:
            try container.encode(Kind.none, forKey: .type)
        case .keyboard(let keyBinding):
            try container.encode(Kind.keyboard, forKey: .type)
            try container.encode(keyBinding, forKey: .keyBinding)
        case .mouse(let mouseBinding):
            try container.encode(Kind.mouse, forKey: .type)
            try container.encode(mouseBinding, forKey: .mouseBinding)
        }
    }
}

public extension BindingAction {
    var displayText: String {
        switch self {
        case .none:
            return "No Action"
        case .keyboard(let binding):
            let modifiersText = binding.modifiers.map { $0.rawValue.capitalized }.joined(separator: "+")
            let keyText = "KeyCode(\(binding.keyCode))"
            return modifiersText.isEmpty ? keyText : "\(modifiersText)+\(keyText)"
        case .mouse(let binding):
            return binding.action.rawValue
        }
    }
}

public struct AppSettings: Codable, Equatable, Sendable {
    public var confidenceThreshold: Float
    public var framesRequired: Int
    public var cooldownMs: Int
    public var fps: Int

    public init(
        confidenceThreshold: Float = 0.3,
        framesRequired: Int = 5,
        cooldownMs: Int = 800,
        fps: Int = 15
    ) {
        self.confidenceThreshold = confidenceThreshold
        self.framesRequired = framesRequired
        self.cooldownMs = cooldownMs
        self.fps = fps
    }

    public static let `default` = AppSettings()
}

public struct GestureTrigger: Equatable, Sendable {
    public var event: GestureEvent
    public var confidence: Float
    public var timestamp: Date

    public init(event: GestureEvent, confidence: Float, timestamp: Date = Date()) {
        self.event = event
        self.confidence = confidence
        self.timestamp = timestamp
    }
}

public struct HandPosePoint: Codable, Equatable, Sendable {
    public var name: String
    public var x: Float
    public var y: Float
    public var confidence: Float

    public init(name: String, x: Float, y: Float, confidence: Float) {
        self.name = name
        self.x = x
        self.y = y
        self.confidence = confidence
    }
}

public struct HandPoseFrame: Codable, Equatable, Sendable {
    public var points: [HandPosePoint]
    public var timestamp: Date

    public init(points: [HandPosePoint], timestamp: Date = Date()) {
        self.points = points
        self.timestamp = timestamp
    }
}

public struct FacePoseFrame: Codable, Equatable, Sendable {
    public var centerX: Float
    public var centerY: Float
    public var width: Float
    public var height: Float
    public var confidence: Float
    public var timestamp: Date

    public init(
        centerX: Float,
        centerY: Float,
        width: Float,
        height: Float,
        confidence: Float,
        timestamp: Date = Date()
    ) {
        self.centerX = centerX
        self.centerY = centerY
        self.width = width
        self.height = height
        self.confidence = confidence
        self.timestamp = timestamp
    }
}

public struct VisionAnalysisFrame: Equatable, Sendable {
    public var handPose: HandPoseFrame?
    public var facePose: FacePoseFrame?
    public var timestamp: Date

    public init(handPose: HandPoseFrame?, facePose: FacePoseFrame?, timestamp: Date = Date()) {
        self.handPose = handPose
        self.facePose = facePose
        self.timestamp = timestamp
    }
}
