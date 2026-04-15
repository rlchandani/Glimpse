import ComposableArchitecture
import EventKit
import Foundation

@DependencyClient
public struct EventKitClient: Sendable {
    public var requestAccess: @Sendable () async -> Bool = { false }
    public var fetchTodayEvents: @Sendable () async -> [CalendarEvent] = { [] }
    public var authorizationStatus: @Sendable () -> EKAuthorizationStatus = { .notDetermined }
}

extension EventKitClient: DependencyKey {
    public static var liveValue: Self {
        // Safety: EKEventStore is thread-safe for event queries. Static property — created once per app lifecycle.
        nonisolated(unsafe) let store = EKEventStore()

        return Self(
            requestAccess: {
                do {
                    return try await store.requestFullAccessToEvents()
                } catch {
                    return false
                }
            },
            fetchTodayEvents: {
                let status = EKEventStore.authorizationStatus(for: .event)
                guard status == .fullAccess else { return [] }

                let cal = Calendar.current
                let startOfDay = cal.startOfDay(for: Date())
                guard let endOfDay = cal.date(byAdding: .day, value: 1, to: startOfDay) else {
                    return []
                }

                let predicate = store.predicateForEvents(
                    withStart: startOfDay, end: endOfDay, calendars: nil
                )
                let ekEvents = store.events(matching: predicate)

                return ekEvents
                    .sorted { $0.startDate < $1.startDate }
                    .map { event in
                        CalendarEvent(
                            id: event.eventIdentifier,
                            title: event.title ?? "Untitled",
                            startDate: event.startDate,
                            endDate: event.endDate,
                            isAllDay: event.isAllDay
                        )
                    }
            },
            authorizationStatus: {
                EKEventStore.authorizationStatus(for: .event)
            }
        )
    }

    public static let testValue = Self()
}

extension DependencyValues {
    public var eventKitClient: EventKitClient {
        get { self[EventKitClient.self] }
        set { self[EventKitClient.self] = newValue }
    }
}
