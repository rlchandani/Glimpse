import ComposableArchitecture
import Foundation

@Reducer
public struct PreferencesFeature: Sendable {

    @ObservableState
    public struct State: Equatable {
        public var startOfWeekday: Int = 1
        public var workdays: Set<Int> = [2, 3, 4, 5, 6]
        public var displayOptions: MenuBarDisplayOptions = .default
        public var launchAtLogin: Bool = false
        public var launchAtLoginError: String?

        public init() {}
    }

    public enum Action: Sendable {
        case onAppear
        case setStartOfWeekday(Int)
        case toggleWorkday(Int)
        case setShowIcon(Bool)
        case setShowDayOfWeek(Bool)
        case setShowMonth(Bool)
        case setShowDate(Bool)
        case setShowYear(Bool)
        case setLaunchAtLogin(Bool)
        case launchAtLoginSucceeded
        case launchAtLoginFailed(String)

        // Delegate actions for parent to react to
        case delegate(Delegate)

        @CasePathable
        public enum Delegate: Sendable {
            case preferencesChanged
            case displayOptionsChanged(MenuBarDisplayOptions)
        }
    }

    @Dependency(\.preferencesClient) var preferencesClient
    @Dependency(\.launchAtLoginClient) var launchAtLoginClient

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.startOfWeekday = preferencesClient.loadStartOfWeekday()
                state.workdays = preferencesClient.loadWorkdays()
                state.displayOptions = preferencesClient.loadDisplayOptions()
                state.launchAtLogin = launchAtLoginClient.isEnabled()
                return .none

            case let .setStartOfWeekday(day):
                state.startOfWeekday = day
                preferencesClient.saveStartOfWeekday(day)
                return .send(.delegate(.preferencesChanged))

            case let .toggleWorkday(weekday):
                if state.workdays.contains(weekday) {
                    state.workdays.remove(weekday)
                } else {
                    state.workdays.insert(weekday)
                }
                preferencesClient.saveWorkdays(state.workdays)
                return .send(.delegate(.preferencesChanged))

            case let .setShowIcon(value):
                state.displayOptions.showIcon = value
                preferencesClient.saveDisplayOptions(state.displayOptions)
                return .send(.delegate(.displayOptionsChanged(state.displayOptions)))

            case let .setShowDayOfWeek(value):
                state.displayOptions.showDayOfWeek = value
                preferencesClient.saveDisplayOptions(state.displayOptions)
                return .send(.delegate(.displayOptionsChanged(state.displayOptions)))

            case let .setShowMonth(value):
                state.displayOptions.showMonth = value
                preferencesClient.saveDisplayOptions(state.displayOptions)
                return .send(.delegate(.displayOptionsChanged(state.displayOptions)))

            case let .setShowDate(value):
                state.displayOptions.showDate = value
                preferencesClient.saveDisplayOptions(state.displayOptions)
                return .send(.delegate(.displayOptionsChanged(state.displayOptions)))

            case let .setShowYear(value):
                state.displayOptions.showYear = value
                preferencesClient.saveDisplayOptions(state.displayOptions)
                return .send(.delegate(.displayOptionsChanged(state.displayOptions)))

            case let .setLaunchAtLogin(enabled):
                state.launchAtLogin = enabled
                return .run { send in
                    do {
                        try launchAtLoginClient.setEnabled(enabled)
                        await send(.launchAtLoginSucceeded)
                    } catch {
                        await send(.launchAtLoginFailed(error.localizedDescription))
                    }
                }

            case .launchAtLoginSucceeded:
                state.launchAtLoginError = nil
                return .none

            case let .launchAtLoginFailed(errorMessage):
                state.launchAtLoginError = errorMessage
                state.launchAtLogin = launchAtLoginClient.isEnabled()
                return .none

            case .delegate:
                return .none
            }
        }
    }
}
