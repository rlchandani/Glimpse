import AppKit
import GlimpseCore

/// Renders the complete menu bar status item — pill border, optional filled
/// background, date icon, separator, and date text — into a single NSImage.
///
/// This image is set as the status button's `image` (`.imageOnly`). We do NOT
/// add a custom NSView subview to the status button: on macOS 26 the scene-managed
/// status-bar button never settles a child view's content frame, driving a
/// perpetual redraw loop (~40% CPU while idle). Compositing everything into the
/// button's own image uses only documented API and keeps the app at 0% idle.
///
/// The preferences preview (`StatusItemPreview`) renders the same image, so the
/// preview and the real menu bar cannot visually drift.
enum MenuBarItemRenderer {

    /// Produce the menu bar item image for the given options and appearance.
    /// - Parameters:
    ///   - options: display options (icon/date fields, filled background).
    ///   - dateString: the already-formatted date text (may be empty).
    ///   - isDark: whether the destination appearance is dark.
    static func render(
        options: MenuBarDisplayOptions,
        dateString: String,
        isDark: Bool
    ) -> NSImage {
        let height = NSStatusBar.system.thickness
        let iconSize = AppDesign.Icon.menuBarSize
        let padding = AppDesign.StatusItem.padding
        let innerPadding = AppDesign.StatusItem.innerPadding
        let separatorInset = AppDesign.StatusItem.separatorInset
        let corner = AppDesign.StatusItem.borderCornerRadius
        let font = NSFont.systemFont(ofSize: AppDesign.StatusItem.fontSize, weight: .medium)

        let filled = options.showFilledBackground
        let hasText = !dateString.isEmpty
        let showIcon = options.showIcon || dateString.isEmpty

        // Resolve colors up front (captured as immutable values by the draw closure).
        let darkContent = NSColor(white: 0.1, alpha: 1.0)
        let contentColor: NSColor = filled ? darkContent : (isDark ? .white : darkContent)
        let borderColor: NSColor = filled
            ? darkContent
            : (isDark ? NSColor(white: 1.0, alpha: 0.3) : NSColor(white: 0.0, alpha: 0.2))
        let backgroundColor: NSColor? = filled
            ? (isDark ? NSColor(white: 0.85, alpha: 1.0) : NSColor(white: 0.92, alpha: 1.0))
            : nil

        let textAttributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: contentColor,
        ]
        let textSize = hasText
            ? (dateString as NSString).size(withAttributes: textAttributes)
            : .zero

        // Compute total width (mirrors the previous StatusItemView layout exactly).
        var width = padding * 2
        if showIcon { width += iconSize }
        if showIcon && hasText { width += innerPadding * 2 + 1 }
        if hasText { width += ceil(textSize.width) }
        width = ceil(width)

        let image = NSImage(
            size: NSSize(width: width, height: height),
            flipped: false
        ) { rect in
            // Pill border + optional fill.
            let pill = rect.insetBy(dx: 0.5, dy: 0.5)
            let path = NSBezierPath(roundedRect: pill, xRadius: corner, yRadius: corner)
            if let backgroundColor {
                backgroundColor.setFill()
                path.fill()
            }
            borderColor.setStroke()
            path.lineWidth = 1
            path.stroke()

            var x = padding

            if showIcon {
                let icon = DateIconRenderer.render(textColor: contentColor)
                let iconY = (height - iconSize) / 2
                icon.draw(in: NSRect(x: x, y: iconY, width: iconSize, height: iconSize))
                x += iconSize
            }

            if showIcon && hasText {
                x += innerPadding
                contentColor.setFill()
                NSRect(x: x, y: separatorInset, width: 1, height: height - separatorInset * 2).fill()
                x += 1 + innerPadding
            }

            if hasText {
                let textY = (height - textSize.height) / 2
                (dateString as NSString).draw(at: NSPoint(x: x, y: textY), withAttributes: textAttributes)
            }

            return true
        }

        // Non-template so the menu bar preserves our explicit colors instead of tinting.
        image.isTemplate = false
        return image
    }
}
