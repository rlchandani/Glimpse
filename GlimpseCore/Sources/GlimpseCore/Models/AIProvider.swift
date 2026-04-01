import Foundation

public enum AIProvider: String, Equatable, Sendable, CaseIterable, Codable {
    case auto = "auto"
    case groq = "groq"
    case onDevice = "onDevice"

    public var displayName: String {
        switch self {
        case .auto: "Auto"
        case .groq: "Groq"
        case .onDevice: "On-device AI"
        }
    }
}
