import ComposableArchitecture
import Foundation

@Reducer
public struct CalendarFeature: Sendable {

    @ObservableState
    public struct State: Equatable {
        public var displayedMonth: Date
        public var days: [CalendarDay] = []
        public var gridInfo: GridInfo = GridInfo(startCol: 0, endCol: 6, endRow: 5)
        public var startOfWeekday: Int = 1
        public var workdays: Set<Int> = [2, 3, 4, 5, 6]
        public var isPinned: Bool = false
        public var showingPreferences: Bool = false

        public var calendar: Calendar {
            var cal = Calendar.current
            cal.firstWeekday = startOfWeekday
            return cal
        }

        public var isShowingCurrentMonth: Bool {
            Calendar.current.isDate(displayedMonth, equalTo: Date(), toGranularity: .month)
        }

        public var monthYearString: String {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM yyyy"
            return formatter.string(from: displayedMonth)
        }

        public init(displayedMonth: Date = Date()) {
            self.displayedMonth = displayedMonth
        }
    }

    public enum Action: Sendable {
        case onAppear
        case goToPreviousMonth
        case goToNextMonth
        case goToPreviousYear
        case goToNextYear
        case goToToday
        case togglePin
        case togglePreferences
        case closePanel
        case onDisappear
    }

    @Dependency(\.calendarClient) var calendarClient
    @Dependency(\.preferencesClient) var preferencesClient

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.startOfWeekday = preferencesClient.loadStartOfWeekday()
                state.workdays = preferencesClient.loadWorkdays()
                recomputeDays(&state)
                return .none

            case .goToPreviousMonth:
                if let prev = state.calendar.date(
                    byAdding: .month, value: -1, to: state.displayedMonth
                ) {
                    state.displayedMonth = prev
                    recomputeDays(&state)
                }
                return .none

            case .goToNextMonth:
                if let next = state.calendar.date(
                    byAdding: .month, value: 1, to: state.displayedMonth
                ) {
                    state.displayedMonth = next
                    recomputeDays(&state)
                }
                return .none

            case .goToPreviousYear:
                if let prev = state.calendar.date(
                    byAdding: .year, value: -1, to: state.displayedMonth
                ) {
                    state.displayedMonth = prev
                    recomputeDays(&state)
                }
                return .none

            case .goToNextYear:
                if let next = state.calendar.date(
                    byAdding: .year, value: 1, to: state.displayedMonth
                ) {
                    state.displayedMonth = next
                    recomputeDays(&state)
                }
                return .none

            case .goToToday:
                state.displayedMonth = Date()
                recomputeDays(&state)
                return .none

            case .togglePin:
                state.isPinned.toggle()
                return .none

            case .togglePreferences:
                state.showingPreferences.toggle()
                return .none

            case .closePanel:
                state.isPinned = false
                return .none

            case .onDisappear:
                state.showingPreferences = false
                state.displayedMonth = Date()
                recomputeDays(&state)
                return .none
            }
        }
    }

    private func recomputeDays(_ state: inout State) {
        state.days = calendarClient.calendarDays(state.displayedMonth, state.calendar)
        state.gridInfo = calendarClient.gridInfo(state.days)
    }
}
