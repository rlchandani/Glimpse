import ComposableArchitecture
import Foundation
import Testing

@testable import GlimpseCore

@MainActor
struct MenuBarFeatureTests {

    @Test
    func onAppear_loadsOptionsAndDateString() async {
        let options = MenuBarDisplayOptions(showDayOfWeek: true, showMonth: true, showDate: true)

        let store = TestStore(
            initialState: MenuBarFeature.State()
        ) {
            MenuBarFeature()
        } withDependencies: {
            $0.preferencesClient.loadDisplayOptions = { options }
            $0.calendarClient.menuBarDateString = { _, _ in "Fri, Mar 20" }
        }

        await store.send(.onAppear) {
            $0.displayOptions = options
            $0.dateString = "Fri, Mar 20"
        }
    }

    @Test
    func updateDisplay_refreshesDateString() async {
        let store = TestStore(
            initialState: MenuBarFeature.State()
        ) {
            MenuBarFeature()
        } withDependencies: {
            $0.calendarClient.menuBarDateString = { _, _ in "Sat, Mar 21" }
        }

        await store.send(.updateDisplay) {
            $0.dateString = "Sat, Mar 21"
        }
    }

    @Test
    func displayOptionsChanged_updatesOptionsAndString() async {
        let newOptions = MenuBarDisplayOptions(showIcon: false, showDate: true)

        let store = TestStore(
            initialState: MenuBarFeature.State()
        ) {
            MenuBarFeature()
        } withDependencies: {
            $0.calendarClient.menuBarDateString = { _, _ in "20" }
        }

        await store.send(.displayOptionsChanged(newOptions)) {
            $0.displayOptions = newOptions
            $0.dateString = "20"
        }
    }
}
