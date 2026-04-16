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
        public var todayEvents: [CalendarEvent] = []
        public var calendarAccessGranted: Bool = false
        public var selectedDate: Date?
        public var showAISearch: Bool = true

        public var selectedDateInfo: String? {
            guard let date = selectedDate else { return nil }
            let cal = Calendar.current
            let week = cal.component(.weekOfYear, from: date)
            let formatted = date.formatted(.dateTime.weekday(.wide).month(.wide).day().year())
            return "\(formatted) - Week \(week)"
        }

        public var calendar: Calendar {
            var cal = Calendar.current
            cal.firstWeekday = startOfWeekday
            return cal
        }

        public var isShowingCurrentMonth: Bool {
            Calendar.current.isDate(displayedMonth, equalTo: .now, toGranularity: .month)
        }

        public var monthYearString: String {
            displayedMonth.formatted(.dateTime.month(.wide).year())
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
        case dateTapped(Date)
        case togglePin
        case togglePreferences
        case closePanel
        case onDisappear
        case requestCalendarAccess
        case calendarAccessResult(Bool)
        case eventsLoaded([CalendarEvent])
        case aiDateResult(Date?)
        case reloadPreferences
    }

    @Dependency(\.date) var date
    @Dependency(\.calendarClient) var calendarClient
    @Dependency(\.preferencesClient) var preferencesClient
    @Dependency(\.eventKitClient) var eventKitClient

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.startOfWeekday = preferencesClient.loadStartOfWeekday()
                state.workdays = preferencesClient.loadWorkdays()
                state.showAISearch = preferencesClient.loadShowAISearch()
                recomputeDays(&state)
                let status = eventKitClient.authorizationStatus()
                if status == .fullAccess {
                    state.calendarAccessGranted = true
                    return .run { send in
                        let events = await eventKitClient.fetchTodayEvents()
                        await send(.eventsLoaded(events))
                    }
                }
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
                state.displayedMonth = date.now
                state.selectedDate = date.now
                recomputeDays(&state)
                return .none

            case let .dateTapped(date):
                // Toggle selection: tap again to deselect
                if let current = state.selectedDate,
                   state.calendar.isDate(current, inSameDayAs: date) {
                    state.selectedDate = nil
                } else {
                    state.selectedDate = date
                }
                // Fetch events for the selected/deselected date
                if state.calendarAccessGranted {
                    if let selected = state.selectedDate {
                        return .run { [selected, calendar = state.calendar] send in
                            let events = await eventKitClient.fetchTodayEvents()
                            let filtered = events.filter { event in
                                calendar.isDate(event.startDate, inSameDayAs: selected) ||
                                calendar.isDate(event.endDate, inSameDayAs: selected) ||
                                (event.startDate < selected && event.endDate > selected)
                            }
                            await send(.eventsLoaded(filtered))
                        }
                    } else {
                        // Deselected — restore today's events
                        return .run { send in
                            let events = await eventKitClient.fetchTodayEvents()
                            await send(.eventsLoaded(events))
                        }
                    }
                }
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

            case .requestCalendarAccess:
                return .run { send in
                    let granted = await eventKitClient.requestAccess()
                    await send(.calendarAccessResult(granted))
                }

            case let .calendarAccessResult(granted):
                state.calendarAccessGranted = granted
                if granted {
                    return .run { send in
                        let events = await eventKitClient.fetchTodayEvents()
                        await send(.eventsLoaded(events))
                    }
                }
                return .none

            case let .eventsLoaded(events):
                state.todayEvents = events
                return .none

            case .reloadPreferences:
                state.startOfWeekday = preferencesClient.loadStartOfWeekday()
                state.workdays = preferencesClient.loadWorkdays()
                state.showAISearch = preferencesClient.loadShowAISearch()
                recomputeDays(&state)
                return .none

            case let .aiDateResult(date):
                if let date {
                    state.displayedMonth = date
                    state.selectedDate = date
                    recomputeDays(&state)
                }
                return .none

            case .onDisappear:
                state.showingPreferences = false
                state.displayedMonth = date.now
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
