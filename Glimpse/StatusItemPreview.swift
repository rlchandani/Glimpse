import GlimpseCore
import SwiftUI

/// Wraps the real StatusItemView in SwiftUI so the preferences preview
/// uses the exact same rendering path as the actual menu bar item.
struct StatusItemPreview: NSViewRepresentable {
    let displayOptions: MenuBarDisplayOptions
    let dateString: String

    func makeNSView(context: Context) -> StatusItemView {
        StatusItemView(
            frame: NSRect(x: 0, y: 0, width: 100, height: AppDesign.StatusItem.height)
        )
    }

    func updateNSView(_ view: StatusItemView, context: Context) {
        let filled = displayOptions.showFilledBackground
        let iconTextColor: NSColor = filled
            ? NSColor(white: 0.1, alpha: 1.0)
            : .labelColor
        let icon = DateIconRenderer.render(textColor: iconTextColor)
        let showIcon = displayOptions.showIcon || dateString.isEmpty

        view.update(
            icon: icon,
            text: dateString,
            showIcon: showIcon,
            filled: filled
        )
    }
}
