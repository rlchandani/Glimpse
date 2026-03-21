import ComposableArchitecture
import ServiceManagement

@DependencyClient
public struct LaunchAtLoginClient: Sendable {
    public var isEnabled: @Sendable () -> Bool = { false }
    public var setEnabled: @Sendable (Bool) throws -> Void
}

extension LaunchAtLoginClient: DependencyKey {
    public static var liveValue: Self {
        Self(
            isEnabled: {
                SMAppService.mainApp.status == .enabled
            },
            setEnabled: { enabled in
                if enabled {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            }
        )
    }

    public static let testValue = Self()
}

extension DependencyValues {
    public var launchAtLoginClient: LaunchAtLoginClient {
        get { self[LaunchAtLoginClient.self] }
        set { self[LaunchAtLoginClient.self] = newValue }
    }
}
