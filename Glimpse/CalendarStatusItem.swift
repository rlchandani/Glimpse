import AppKit

final class CalendarStatusItem {
    private var statusItem: NSStatusItem?
    private var statusItemView: StatusItemView?
    private var panel: CalendarPanel?
    private var midnightTimer: Timer?

    func setup() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        let view = StatusItemView(frame: NSRect(x: 0, y: 0, width: 30, height: 30))
        statusItemView = view
        statusItem?.button?.addSubview(view)
        statusItem?.button?.target = self
        statusItem?.button?.action = #selector(statusItemClicked)

        CalendarPreferences.shared.onMenuBarDisplayChanged = { [weak self] in
            self?.updateMenuBarDisplay()
        }

        updateMenuBarDisplay()
        scheduleMidnightRefresh()
    }

    func updateMenuBarDisplay() {
        guard let button = statusItem?.button,
              let view = statusItemView
        else { return }

        let prefs = CalendarPreferences.shared
        let icon = DateIconRenderer.render()
        let dateString = prefs.menuBarDateString()
        let showIcon = prefs.showIcon || dateString.isEmpty

        view.update(icon: icon, text: dateString, showIcon: showIcon)

        // Resize the status item to fit the custom view
        button.frame.size = view.frame.size
        statusItem?.length = view.frame.width
        view.frame = button.bounds
    }

    private func scheduleMidnightRefresh() {
        // Refresh the display at midnight so the date/icon update
        let cal = Calendar.current
        guard let tomorrow = cal.date(byAdding: .day, value: 1, to: Date()),
              let midnight = cal.date(bySettingHour: 0, minute: 0, second: 1, of: tomorrow)
        else { return }

        let interval = midnight.timeIntervalSinceNow
        midnightTimer = Timer.scheduledTimer(
            withTimeInterval: interval,
            repeats: false
        ) { [weak self] _ in
            self?.updateMenuBarDisplay()
            self?.scheduleMidnightRefresh()
        }
    }

    @objc private func statusItemClicked() {
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

        var panelX = round(statusItemRect.midX - panelWidth / 2)
        let panelY = statusItemRect.minY - panelHeight - caretHeight - gapBelowMenuBar

        let screenMaxX = screen.frame.maxX
        let screenMinX = screen.frame.minX
        if panelX + panelWidth + 10 > screenMaxX {
            panelX = screenMaxX - panelWidth - 10
        }
        if panelX < screenMinX + 10 {
            panelX = screenMinX + 10
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
    }
}
