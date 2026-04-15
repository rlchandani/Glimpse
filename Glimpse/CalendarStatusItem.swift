import AppKit
import Carbon
import GlimpseCore

extension Notification.Name {
    static let menuBarDisplayDidChange = Notification.Name("menuBarDisplayDidChange")
    static let calendarPreferencesDidChange = Notification.Name("calendarPreferencesDidChange")
    static let aiSearchSettingDidChange = Notification.Name("aiSearchSettingDidChange")
}

@MainActor
final class CalendarStatusItem {
    private var statusItem: NSStatusItem?
    private var statusItemView: StatusItemView?
    private var panel: CalendarPanel?
    private var midnightTimer: Timer?
    private var displayChangeObserver: Any?
    private var wakeObserver: Any?
    private var timeChangeObserver: Any?
    private let preferencesClient = PreferencesClient.liveValue
    private let calendarClient = CalendarClient.liveValue

    func setup() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        let view = StatusItemView(
            frame: NSRect(x: 0, y: 0, width: 30, height: AppDesign.StatusItem.height)
        )
        statusItemView = view
        statusItem?.button?.addSubview(view)
        statusItem?.button?.target = self
        statusItem?.button?.action = #selector(statusItemClicked)

        updateMenuBarDisplay()
        scheduleMidnightRefresh()
        registerGlobalHotkey()
        observeDisplayChanges()
        observeSystemEvents()
        AppLogger.statusItem.info("Status item configured")
    }

    private func observeDisplayChanges() {
        displayChangeObserver = NotificationCenter.default.addObserver(
            forName: .menuBarDisplayDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.updateMenuBarDisplay()
            }
        }
    }

    private func observeSystemEvents() {
        wakeObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.updateMenuBarDisplay()
                self?.scheduleMidnightRefresh()
                AppLogger.statusItem.info("Refreshed after wake")
            }
        }

        timeChangeObserver = NotificationCenter.default.addObserver(
            forName: .NSSystemClockDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.updateMenuBarDisplay()
                self?.scheduleMidnightRefresh()
                AppLogger.statusItem.info("Refreshed after system clock change")
            }
        }
    }

    private func registerGlobalHotkey() {
        let enabled = UserDefaults.standard.object(forKey: "hotkeyEnabled") != nil
            ? UserDefaults.standard.bool(forKey: "hotkeyEnabled")
            : true

        guard enabled else {
            AppLogger.statusItem.info("Global hotkey disabled by user")
            return
        }

        let combo = HotkeyCombo.load()
        GlobalHotkey.register(combo: combo) { [weak self] in
            self?.statusItemClicked()
        }
    }

    func updateMenuBarDisplay() {
        guard let button = statusItem?.button,
              let view = statusItemView
        else { return }

        let options = preferencesClient.loadDisplayOptions()
        let iconTextColor: NSColor = options.showFilledBackground
            ? NSColor(white: 0.1, alpha: 1.0)
            : .labelColor
        let icon = DateIconRenderer.render(textColor: iconTextColor)
        let dateString = calendarClient.menuBarDateString(Date(), options)
        let showIcon = options.showIcon || dateString.isEmpty

        view.update(icon: icon, text: dateString, showIcon: showIcon, filled: options.showFilledBackground)

        button.frame.size = view.frame.size
        statusItem?.length = view.frame.width
        view.frame = button.bounds
    }

    /// Compute the next midnight (00:00:01) after the given date.
    /// Visible for testing.
    nonisolated static func nextMidnight(after date: Date, calendar: Calendar = .current) -> Date? {
        guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: date),
              let midnight = calendar.date(bySettingHour: 0, minute: 0, second: 1, of: tomorrow)
        else { return nil }
        return midnight
    }

    private func scheduleMidnightRefresh() {
        midnightTimer?.invalidate()

        guard let midnight = Self.nextMidnight(after: Date()) else {
            AppLogger.statusItem.error("Failed to compute next midnight for refresh")
            return
        }

        let timer = Timer(fire: midnight, interval: 0, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.updateMenuBarDisplay()
                self?.scheduleMidnightRefresh()
                AppLogger.statusItem.info("Midnight refresh completed")
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        midnightTimer = timer
    }

    @objc func statusItemClicked() {
        guard let panel else {
            showPanel()
            return
        }

        let isVisible = panel.occlusionState.contains(.visible) && panel.isVisible

        if isVisible {
            if !isOnSameScreen(panel) {
                panel.orderOut(nil)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
                    self?.showPanel()
                }
                return
            }

            if !panel.isPinned {
                panel.orderOut(nil)
            }
        } else {
            showPanel()
        }
    }

    private func isOnSameScreen(_ panel: CalendarPanel) -> Bool {
        guard let panelScreen = panel.screen,
              let currentScreen = currentStatusItemScreen()
        else { return true }
        return NSEqualRects(panelScreen.frame, currentScreen.frame)
    }

    private func currentStatusItemScreen() -> NSScreen? {
        guard let button = statusItem?.button,
              let buttonWindow = button.window
        else { return NSScreen.main }

        let buttonRect = buttonWindow.convertToScreen(
            button.convert(button.bounds, to: nil)
        )

        let testPoint = NSPoint(x: buttonRect.midX, y: buttonRect.origin.y - 100)
        return NSScreen.screens.first { $0.frame.contains(testPoint) } ?? NSScreen.main
    }

    private func showPanel() {
        guard let button = statusItem?.button,
              let buttonWindow = button.window
        else { return }

        let statusItemRect = buttonWindow.convertToScreen(
            button.convert(button.bounds, to: nil)
        )

        guard let screen = currentStatusItemScreen() ?? NSScreen.main else { return }

        let panelWidth = CalendarPanel.panelWidth
        let panelHeight = CalendarPanel.panelHeight
        let caretHeight = CalendarPanel.caretHeight
        let gapBelowMenuBar = CalendarPanel.gapBelowMenuBar
        let edgeMargin: CGFloat = 10

        var panelX = round(statusItemRect.midX - panelWidth / 2)
        let panelY = statusItemRect.minY - panelHeight - caretHeight - gapBelowMenuBar

        if panelX + panelWidth + edgeMargin > screen.frame.maxX {
            panelX = screen.frame.maxX - panelWidth - edgeMargin
        }
        if panelX < screen.frame.minX + edgeMargin {
            panelX = screen.frame.minX + edgeMargin
        }

        let caretOffset = max(16, min(statusItemRect.midX - panelX, panelWidth - 16))

        let contentRect = NSRect(
            x: panelX,
            y: panelY,
            width: panelWidth,
            height: panelHeight + caretHeight
        )

        if panel == nil {
            panel = CalendarPanel(contentRect: contentRect, caretOffset: caretOffset)
        } else {
            panel?.caretXOffset = caretOffset
        }

        panel?.setFrame(contentRect, display: true)
        panel?.makeKeyAndOrderFront(nil)
        panel?.collapsePreferencesIfNeeded()
    }
}
