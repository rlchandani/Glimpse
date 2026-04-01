import ComposableArchitecture
import Foundation
import Testing

@testable import GlimpseCore

@MainActor
struct PreferencesFeatureTests {

    @Test
    func onAppear_loadsAllPreferences() async {
        let store = TestStore(
            initialState: PreferencesFeature.State()
        ) {
            PreferencesFeature()
        } withDependencies: {
            $0.preferencesClient.loadStartOfWeekday = { 2 }
            $0.preferencesClient.loadWorkdays = { [2, 3] }
            $0.preferencesClient.loadDisplayOptions = {
                MenuBarDisplayOptions(showIcon: false, showYear: true)
            }
            $0.preferencesClient.loadShowAISearch = { false }
            $0.preferencesClient.loadAIProvider = { .proxy }
            $0.launchAtLoginClient.isEnabled = { true }
        }

        await store.send(.onAppear) {
            $0.startOfWeekday = 2
            $0.workdays = [2, 3]
            $0.displayOptions = MenuBarDisplayOptions(showIcon: false, showYear: true)
            $0.launchAtLogin = true
            $0.aiProvider = .proxy
            $0.showAISearch = false
        }
    }

    @Test
    func setStartOfWeekday_savesAndNotifies() async {
        let store = TestStore(
            initialState: PreferencesFeature.State()
        ) {
            PreferencesFeature()
        } withDependencies: {
            $0.preferencesClient.saveStartOfWeekday = { _ in }
        }

        await store.send(.setStartOfWeekday(2)) {
            $0.startOfWeekday = 2
        }

        await store.receive(\.delegate.preferencesChanged)
    }

    @Test
    func toggleWorkday_addsAndRemoves() async {
        var state = PreferencesFeature.State()
        state.workdays = [2, 3, 4, 5, 6]

        let store = TestStore(initialState: state) {
            PreferencesFeature()
        } withDependencies: {
            $0.preferencesClient.saveWorkdays = { _ in }
        }

        await store.send(.toggleWorkday(7)) {
            $0.workdays = [2, 3, 4, 5, 6, 7]
        }

        await store.receive(\.delegate.preferencesChanged)

        await store.send(.toggleWorkday(6)) {
            $0.workdays = [2, 3, 4, 5, 7]
        }

        await store.receive(\.delegate.preferencesChanged)
    }

    @Test
    func setShowIcon_savesAndNotifies() async {
        let store = TestStore(
            initialState: PreferencesFeature.State()
        ) {
            PreferencesFeature()
        } withDependencies: {
            $0.preferencesClient.saveDisplayOptions = { _ in }
        }

        await store.send(.setShowIcon(false)) {
            $0.displayOptions.showIcon = false
        }

        await store.receive(\.delegate.displayOptionsChanged)
    }

    @Test
    func setShowDayOfWeek_savesAndNotifies() async {
        let store = TestStore(
            initialState: PreferencesFeature.State()
        ) {
            PreferencesFeature()
        } withDependencies: {
            $0.preferencesClient.saveDisplayOptions = { _ in }
        }

        await store.send(.setShowDayOfWeek(false)) {
            $0.displayOptions.showDayOfWeek = false
        }

        await store.receive(\.delegate.displayOptionsChanged)
    }

    @Test
    func setShowMonth_savesAndNotifies() async {
        let store = TestStore(
            initialState: PreferencesFeature.State()
        ) {
            PreferencesFeature()
        } withDependencies: {
            $0.preferencesClient.saveDisplayOptions = { _ in }
        }

        await store.send(.setShowMonth(false)) {
            $0.displayOptions.showMonth = false
        }

        await store.receive(\.delegate.displayOptionsChanged)
    }

    @Test
    func setShowDate_savesAndNotifies() async {
        let store = TestStore(
            initialState: PreferencesFeature.State()
        ) {
            PreferencesFeature()
        } withDependencies: {
            $0.preferencesClient.saveDisplayOptions = { _ in }
        }

        await store.send(.setShowDate(false)) {
            $0.displayOptions.showDate = false
        }

        await store.receive(\.delegate.displayOptionsChanged)
    }

    @Test
    func setShowYear_savesAndNotifies() async {
        let store = TestStore(
            initialState: PreferencesFeature.State()
        ) {
            PreferencesFeature()
        } withDependencies: {
            $0.preferencesClient.saveDisplayOptions = { _ in }
        }

        await store.send(.setShowYear(true)) {
            $0.displayOptions.showYear = true
        }

        await store.receive(\.delegate.displayOptionsChanged)
    }

    @Test
    func setLaunchAtLogin_success() async {
        let store = TestStore(
            initialState: PreferencesFeature.State()
        ) {
            PreferencesFeature()
        } withDependencies: {
            $0.launchAtLoginClient.setEnabled = { _ in }
        }

        await store.send(.setLaunchAtLogin(true)) {
            $0.launchAtLogin = true
        }

        await store.receive(\.launchAtLoginSucceeded)
    }

    @Test
    func setLaunchAtLogin_failure_reverts() async {
        struct TestError: Error, LocalizedError {
            var errorDescription: String? { "test error" }
        }

        let store = TestStore(
            initialState: PreferencesFeature.State()
        ) {
            PreferencesFeature()
        } withDependencies: {
            $0.launchAtLoginClient.setEnabled = { _ in throw TestError() }
            $0.launchAtLoginClient.isEnabled = { false }
        }

        await store.send(.setLaunchAtLogin(true)) {
            $0.launchAtLogin = true
        }

        await store.receive(\.launchAtLoginFailed) {
            $0.launchAtLoginError = "test error"
            $0.launchAtLogin = false
        }
    }

    // MARK: - AI Search Toggle

    @Test
    func setShowAISearch_savesAndNotifies() async {
        let store = TestStore(
            initialState: PreferencesFeature.State()
        ) {
            PreferencesFeature()
        } withDependencies: {
            $0.preferencesClient.saveShowAISearch = { _ in }
        }

        await store.send(.setShowAISearch(false)) {
            $0.showAISearch = false
        }

        await store.receive(\.delegate.preferencesChanged)
    }


}
