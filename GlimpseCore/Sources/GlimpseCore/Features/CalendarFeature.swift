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

        public var selectedDateInfo: String? {
            guard let date = selectedDate else { return nil }
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE, MMMM d, yyyy"
            let cal = Calendar.current
            let week = cal.component(.weekOfYear, from: date)
            return "\(formatter.string(from: date)) — Week \(week)"
        }
        public var aiQuery: String = ""
        public var aiIsProcessing: Bool = false
        public var aiError: String?

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
        case dateTapped(Date)
        case togglePin
        case togglePreferences
        case closePanel
        case onDisappear
        case requestCalendarAccess
        case calendarAccessResult(Bool)
        case eventsLoaded([CalendarEvent])
        case aiQueryChanged(String)
        case aiQuerySubmitted
        case aiDateResult(Date?)
        case aiDismissError
    }

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
                state.displayedMonth = Date()
                state.selectedDate = Date()
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
                // Fetch events for the selected date if access is granted
                if state.calendarAccessGranted, state.selectedDate != nil {
                    return .run { [date] send in
                        let events = await eventKitClient.fetchTodayEvents()
                        // Filter events to selected date
                        let cal = Calendar.current
                        let filtered = events.filter { event in
                            cal.isDate(event.startDate, inSameDayAs: date) ||
                            cal.isDate(event.endDate, inSameDayAs: date) ||
                            (event.startDate < date && event.endDate > date)
                        }
                        await send(.eventsLoaded(filtered))
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

            case let .aiQueryChanged(query):
                state.aiQuery = query
                state.aiError = nil
                return .none

            case .aiQuerySubmitted:
                let query = state.aiQuery.trimmingCharacters(in: .whitespaces)
                guard !query.isEmpty else { return .none }
                state.aiIsProcessing = true
                state.aiError = nil
                return .none // The view handles calling AIDateHelper since it's app-level

            case let .aiDateResult(date):
                state.aiIsProcessing = false
                if let date {
                    state.displayedMonth = date
                    state.selectedDate = date
                    state.aiQuery = ""
                    recomputeDays(&state)
                } else {
                    state.aiError = "Couldn't understand that date"
                }
                return .none

            case .aiDismissError:
                state.aiError = nil
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
