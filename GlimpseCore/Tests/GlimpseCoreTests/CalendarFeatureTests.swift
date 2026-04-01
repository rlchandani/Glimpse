import ComposableArchitecture
import Foundation
import Testing

@testable import GlimpseCore

@MainActor
struct CalendarFeatureTests {

    @Test
    func onAppear_loadsDaysAndPreferences() async {
        let testDays = [
            CalendarDay(date: Date(), isCurrentMonth: true)
        ]

        let store = TestStore(
            initialState: CalendarFeature.State()
        ) {
            CalendarFeature()
        } withDependencies: {
            $0.preferencesClient.loadStartOfWeekday = { 2 }
            $0.preferencesClient.loadWorkdays = { [2, 3, 4, 5] }
            $0.calendarClient.calendarDays = { _, _ in testDays }
            $0.calendarClient.gridInfo = { _ in GridInfo(startCol: 0, endCol: 2, endRow: 4) }
            $0.eventKitClient.authorizationStatus = { .notDetermined }
        }

        await store.send(.onAppear) {
            $0.startOfWeekday = 2
            $0.workdays = [2, 3, 4, 5]
            $0.days = testDays
            $0.gridInfo = GridInfo(startCol: 0, endCol: 2, endRow: 4)
        }
    }

    @Test
    func goToNextMonth_advancesMonth() async {
        let cal = Calendar.current
        let jan = cal.date(from: DateComponents(year: 2026, month: 1, day: 15))!
        let feb = cal.date(from: DateComponents(year: 2026, month: 2, day: 15))!

        let store = TestStore(
            initialState: CalendarFeature.State(displayedMonth: jan)
        ) {
            CalendarFeature()
        } withDependencies: {
            $0.calendarClient.calendarDays = { _, _ in [] }
            $0.calendarClient.gridInfo = { _ in GridInfo(startCol: 0, endCol: 6, endRow: 5) }
        }

        await store.send(.goToNextMonth) {
            $0.displayedMonth = feb
        }
    }

    @Test
    func goToPreviousMonth_goesBack() async {
        let cal = Calendar.current
        let feb = cal.date(from: DateComponents(year: 2026, month: 2, day: 15))!
        let jan = cal.date(from: DateComponents(year: 2026, month: 1, day: 15))!

        let store = TestStore(
            initialState: CalendarFeature.State(displayedMonth: feb)
        ) {
            CalendarFeature()
        } withDependencies: {
            $0.calendarClient.calendarDays = { _, _ in [] }
            $0.calendarClient.gridInfo = { _ in GridInfo(startCol: 0, endCol: 6, endRow: 5) }
        }

        await store.send(.goToPreviousMonth) {
            $0.displayedMonth = jan
        }
    }

    @Test
    func goToNextYear_advancesYear() async {
        let cal = Calendar.current
        let mar2026 = cal.date(from: DateComponents(year: 2026, month: 3, day: 15))!
        let mar2027 = cal.date(from: DateComponents(year: 2027, month: 3, day: 15))!

        let store = TestStore(
            initialState: CalendarFeature.State(displayedMonth: mar2026)
        ) {
            CalendarFeature()
        } withDependencies: {
            $0.calendarClient.calendarDays = { _, _ in [] }
            $0.calendarClient.gridInfo = { _ in GridInfo(startCol: 0, endCol: 6, endRow: 5) }
        }

        await store.send(.goToNextYear) {
            $0.displayedMonth = mar2027
        }
    }

    @Test
    func goToPreviousYear_goesBack() async {
        let cal = Calendar.current
        let mar2026 = cal.date(from: DateComponents(year: 2026, month: 3, day: 15))!
        let mar2025 = cal.date(from: DateComponents(year: 2025, month: 3, day: 15))!

        let store = TestStore(
            initialState: CalendarFeature.State(displayedMonth: mar2026)
        ) {
            CalendarFeature()
        } withDependencies: {
            $0.calendarClient.calendarDays = { _, _ in [] }
            $0.calendarClient.gridInfo = { _ in GridInfo(startCol: 0, endCol: 6, endRow: 5) }
        }

        await store.send(.goToPreviousYear) {
            $0.displayedMonth = mar2025
        }
    }

    @Test
    func togglePin_togglesState() async {
        let store = TestStore(
            initialState: CalendarFeature.State()
        ) {
            CalendarFeature()
        }

        await store.send(.togglePin) {
            $0.isPinned = true
        }

        await store.send(.togglePin) {
            $0.isPinned = false
        }
    }

    @Test
    func togglePreferences_togglesState() async {
        let store = TestStore(
            initialState: CalendarFeature.State()
        ) {
            CalendarFeature()
        }

        await store.send(.togglePreferences) {
            $0.showingPreferences = true
        }

        await store.send(.togglePreferences) {
            $0.showingPreferences = false
        }
    }

    @Test
    func closePanel_resetsPinned() async {
        var state = CalendarFeature.State()
        state.isPinned = true

        let store = TestStore(initialState: state) {
            CalendarFeature()
        }

        await store.send(.closePanel) {
            $0.isPinned = false
        }
    }

    @Test
    func onDisappear_resetsPreferencesFlag() async {
        let now = Date(timeIntervalSince1970: 1000000)
        var state = CalendarFeature.State()
        state.showingPreferences = true

        let store = TestStore(initialState: state) {
            CalendarFeature()
        } withDependencies: {
            $0.date = .constant(now)
            $0.calendarClient.calendarDays = { _, _ in [] }
            $0.calendarClient.gridInfo = { _ in GridInfo(startCol: 0, endCol: 6, endRow: 5) }
        }

        store.exhaustivity = .off

        await store.send(.onDisappear) {
            $0.showingPreferences = false
            $0.displayedMonth = now
        }
    }

    @Test
    func dateTapped_selectsDate() async {
        let cal = Calendar.current
        let march15 = cal.date(from: DateComponents(year: 2026, month: 3, day: 15))!

        let store = TestStore(
            initialState: CalendarFeature.State()
        ) {
            CalendarFeature()
        } withDependencies: {
            $0.eventKitClient.authorizationStatus = { .notDetermined }
        }

        await store.send(.dateTapped(march15)) {
            $0.selectedDate = march15
        }
    }

    @Test
    func dateTapped_togglesSelection() async {
        let cal = Calendar.current
        let march15 = cal.date(from: DateComponents(year: 2026, month: 3, day: 15))!

        var state = CalendarFeature.State()
        state.selectedDate = march15

        let store = TestStore(initialState: state) {
            CalendarFeature()
        } withDependencies: {
            $0.eventKitClient.authorizationStatus = { .notDetermined }
        }

        await store.send(.dateTapped(march15)) {
            $0.selectedDate = nil
        }
    }

    @Test
    func aiDateResult_navigatesAndSelects() async {
        let cal = Calendar.current
        let july4 = cal.date(from: DateComponents(year: 2026, month: 7, day: 4))!

        let store = TestStore(
            initialState: CalendarFeature.State()
        ) {
            CalendarFeature()
        } withDependencies: {
            $0.calendarClient.calendarDays = { _, _ in [] }
            $0.calendarClient.gridInfo = { _ in GridInfo(startCol: 0, endCol: 6, endRow: 5) }
        }

        store.exhaustivity = .off

        await store.send(.aiDateResult(july4)) {
            $0.displayedMonth = july4
            $0.selectedDate = july4
        }
    }

    @Test
    func aiDateResult_nilDoesNothing() async {
        let store = TestStore(
            initialState: CalendarFeature.State()
        ) {
            CalendarFeature()
        }

        await store.send(.aiDateResult(nil))
    }

    @Test
    func eventsLoaded_updatesState() async {
        let events = [
            CalendarEvent(
                id: "1", title: "Meeting",
                startDate: Date(), endDate: Date(),
                isAllDay: false
            )
        ]

        let store = TestStore(
            initialState: CalendarFeature.State()
        ) {
            CalendarFeature()
        }

        await store.send(.eventsLoaded(events)) {
            $0.todayEvents = events
        }
    }

    @Test
    func calendarAccessResult_granted_fetchesEvents() async {
        let store = TestStore(
            initialState: CalendarFeature.State()
        ) {
            CalendarFeature()
        } withDependencies: {
            $0.date = .constant(Date(timeIntervalSince1970: 0))
            $0.eventKitClient.fetchTodayEvents = { [] }
        }

        await store.send(.calendarAccessResult(true)) {
            $0.calendarAccessGranted = true
        }

        await store.receive(\.eventsLoaded)
    }

    @Test
    func calendarAccessResult_denied() async {
        let store = TestStore(
            initialState: CalendarFeature.State()
        ) {
            CalendarFeature()
        } withDependencies: {
            $0.date = .constant(Date(timeIntervalSince1970: 0))
        }

        await store.send(.calendarAccessResult(false))
    }


    @Test
    func reloadPreferences_updatesWeekdayAndWorkdays() async {
        let testDays = [
            CalendarDay(date: Date(), isCurrentMonth: true)
        ]

        // Start with defaults
        let store = TestStore(
            initialState: CalendarFeature.State()
        ) {
            CalendarFeature()
        } withDependencies: {
            $0.preferencesClient.loadStartOfWeekday = { 3 }
            $0.preferencesClient.loadWorkdays = { [2, 3, 4] }
            $0.calendarClient.calendarDays = { _, _ in testDays }
            $0.calendarClient.gridInfo = { _ in GridInfo(startCol: 0, endCol: 2, endRow: 4) }
        }

        await store.send(.reloadPreferences) {
            $0.startOfWeekday = 3
            $0.workdays = [2, 3, 4]
            $0.days = testDays
            $0.gridInfo = GridInfo(startCol: 0, endCol: 2, endRow: 4)
        }
    }
}
