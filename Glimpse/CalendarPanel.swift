import AppKit
import SwiftUI

final class CalendarPanel: NSPanel {
    static let panelWidth: CGFloat = 316
    static let panelHeight: CGFloat = 420
    static let caretHeight: CGFloat = 12
    static let gapBelowMenuBar: CGFloat = 6

    var caretXOffset: CGFloat = 0
    var isPinned = false

    init(contentRect: NSRect, caretOffset: CGFloat) {
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
        collectionBehavior = [.moveToActiveSpace]
        animationBehavior = .utilityWindow

        let popoverView = CalendarPopoverView(panel: self)
        let hostingView = NSHostingView(rootView: popoverView)
        hostingView.frame = contentRect
        contentView = hostingView
    }

    override var canBecomeKey: Bool { true }

    override func resignKey() {
        super.resignKey()
        if !isPinned {
            orderOut(nil)
        }
    }
}
