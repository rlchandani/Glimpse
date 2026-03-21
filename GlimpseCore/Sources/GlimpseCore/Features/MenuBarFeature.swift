import ComposableArchitecture
import Foundation

@Reducer
public struct MenuBarFeature: Sendable {

    @ObservableState
    public struct State: Equatable {
        public var displayOptions: MenuBarDisplayOptions = .default
        public var dateString: String = ""

        public init() {}
    }

    public enum Action: Sendable {
        case onAppear
        case updateDisplay
        case displayOptionsChanged(MenuBarDisplayOptions)
    }

    @Dependency(\.preferencesClient) var preferencesClient
    @Dependency(\.calendarClient) var calendarClient

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.displayOptions = preferencesClient.loadDisplayOptions()
                state.dateString = calendarClient.menuBarDateString(
                    Date(), state.displayOptions
                )
                return .none

            case .updateDisplay:
                state.dateString = calendarClient.menuBarDateString(
                    Date(), state.displayOptions
                )
                return .none

            case let .displayOptionsChanged(options):
                state.displayOptions = options
                state.dateString = calendarClient.menuBarDateString(Date(), options)
                return .none
            }
        }
    }
}
