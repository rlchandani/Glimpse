import AppKit

enum DateIconRenderer {
    static func render() -> NSImage {
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size, flipped: false) { rect in
            let day = Calendar.current.component(.day, from: Date())
            let dayString = "\(day)"

            let fontSize: CGFloat = day < 10 ? 12 : 10
            let attributes: [NSAttributedString.Key: Any] = [
                .font: NSFont.monospacedSystemFont(ofSize: fontSize, weight: .bold),
                .foregroundColor: NSColor.black
            ]

            let textSize = dayString.size(withAttributes: attributes)

            // Draw calendar outline
            let calendarRect = rect.insetBy(dx: 1, dy: 1)
            let path = NSBezierPath(roundedRect: calendarRect, xRadius: 3, yRadius: 3)
            NSColor.white.withAlphaComponent(0.9).setFill()
            path.fill()

            // Draw top bar (like calendar header)
            let headerRect = NSRect(
                x: calendarRect.origin.x,
                y: calendarRect.origin.y + calendarRect.height - 5,
                width: calendarRect.width,
                height: 5
            )
            let headerPath = NSBezierPath(
                roundedRect: headerRect,
                xRadius: 3,
                yRadius: 3
            )
            NSColor.systemRed.setFill()
            headerPath.fill()
            // Fill the bottom corners of the header
            let headerFillRect = NSRect(
                x: headerRect.origin.x,
                y: headerRect.origin.y,
                width: headerRect.width,
                height: 3
            )
            NSBezierPath(rect: headerFillRect).fill()

            // Draw day number
            let textOrigin = NSPoint(
                x: (rect.width - textSize.width) / 2,
                y: (rect.height - textSize.height) / 2 - 2
            )
            dayString.draw(at: textOrigin, withAttributes: attributes)

            return true
        }

        image.isTemplate = false
        return image
    }
}
