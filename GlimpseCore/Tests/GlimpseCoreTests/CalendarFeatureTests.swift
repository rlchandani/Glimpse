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
        var state = CalendarFeature.State()
        state.showingPreferences = true

        let store = TestStore(initialState: state) {
            CalendarFeature()
        } withDependencies: {
            $0.calendarClient.calendarDays = { _, _ in [] }
            $0.calendarClient.gridInfo = { _ in GridInfo(startCol: 0, endCol: 6, endRow: 5) }
        }

        // Use exhaustivity off since displayedMonth = Date() varies by millisecond
        store.exhaustivity = .off

        await store.send(.onDisappear) {
            $0.showingPreferences = false
        }
    }
}
