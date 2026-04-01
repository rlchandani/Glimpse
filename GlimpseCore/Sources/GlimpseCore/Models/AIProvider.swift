import Foundation

public enum AIProvider: String, Equatable, Sendable, CaseIterable, Codable {
    case auto = "auto"
    case proxy = "proxy"
    case onDevice = "onDevice"

    public var displayName: String {
        switch self {
        case .auto: "Auto"
        case .proxy: "Cloud AI"
        case .onDevice: "On-device AI"
        }
    }
}
