import AppKit
import GlimpseCore
import SwiftUI

@MainActor
final class CalendarPanel: NSPanel {
    static let panelWidth: CGFloat = 316
    static let panelHeight: CGFloat = 420
    static let caretHeight: CGFloat = 12
    static let gapBelowMenuBar: CGFloat = 6

    var caretXOffset: CGFloat = 0
    var isPinned = false
    private var previousApp: NSRunningApplication?
    private let calendarStore: StoreOf<CalendarFeature>
    private var hostingView: NSHostingView<CalendarPopoverView>?
    private var sizeObservation: NSKeyValueObservation?  // invalidated on dealloc via ARC
    private var pendingResize: DispatchWorkItem?
    private var hasShownOnce = false

    init(contentRect: NSRect, caretOffset: CGFloat) {
        let store = Store(initialState: CalendarFeature.State()) {
            CalendarFeature()
        }
        self.calendarStore = store
        self.caretXOffset = caretOffset
        super.init(
            contentRect: contentRect,
            styleMask: [.nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        isOpaque = false
        backgroundColor = .clear
        level = .init(rawValue: Int(CGWindowLevelForKey(.mainMenuWindow)))
        hasShadow = true
        isMovableByWindowBackground = false
        becomesKeyOnlyIfNeeded = false
        collectionBehavior = [.moveToActiveSpace]
        animationBehavior = .utilityWindow

        let popoverView = CalendarPopoverView(store: store, panel: self)
        let hosting = NSHostingView(rootView: popoverView)
        hosting.frame = contentRect
        contentView = hosting
        hostingView = hosting

        // Observe intrinsic content size changes to resize panel (debounced)
        sizeObservation = hosting.observe(\.intrinsicContentSize, options: [.new]) { [weak self] _, _ in
            Task { @MainActor in
                self?.scheduleResizeToFitContent()
            }
        }
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }

    /// Debounce rapid intrinsicContentSize changes to avoid animation flicker.
    private func scheduleResizeToFitContent() {
        pendingResize?.cancel()
        let work = DispatchWorkItem { [weak self] in
            self?.resizeToFitContent()
        }
        pendingResize = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05, execute: work)
    }

    /// Resize the panel to fit the hosting view's intrinsic content size,
    /// anchored to the top (menu bar edge). Width is always fixed at panelWidth.
    private func resizeToFitContent() {
        guard let hosting = hostingView else { return }
        let fittingSize = hosting.intrinsicContentSize
        guard fittingSize.height > 0, fittingSize.width > 0 else { return }

        let newHeight = min(fittingSize.height, screen?.visibleFrame.height ?? 800)
        let currentFrame = frame

        // Anchor to top: keep the top edge fixed, adjust origin.y downward
        let newY = currentFrame.maxY - newHeight
        let newFrame = NSRect(
            x: currentFrame.origin.x,
            y: newY,
            width: Self.panelWidth,
            height: newHeight
        )

        // Skip animation on first show to avoid visible resize jump
        let shouldAnimate = hasShownOnce
        hasShownOnce = true
        setFrame(newFrame, display: true, animate: shouldAnimate)
    }

    /// Reset UI state when panel is re-shown
    func collapsePreferencesIfNeeded() {
        if calendarStore.showingPreferences {
            calendarStore.send(.togglePreferences)
        }
        // Reload preferences in case they changed while panel was hidden
        calendarStore.send(.reloadPreferences)
        // Refresh local @State (showAISearch) without triggering another reloadPreferences
        NotificationCenter.default.post(name: .aiSearchSettingDidChange, object: nil)
    }

    /// Activate the app so TextField can receive focus
    func activateForTextInput() {
        previousApp = NSWorkspace.shared.frontmostApplication
        NSApp.activate(ignoringOtherApps: true)
        makeKey()
    }

    /// Restore focus to the previous app
    func deactivateTextInput() {
        previousApp?.activate(options: .activateIgnoringOtherApps)
        previousApp = nil
    }

    override func resignKey() {
        super.resignKey()
        if !isPinned {
            deactivateTextInput()
            orderOut(nil)
        }
    }
}
