import AppKit

enum DateIconRenderer {
    static func render() -> NSImage {
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size, flipped: false) { rect in
            let day = Calendar.current.component(.day, from: Date())
            let dayString = "\(day)"

            // Date number in white
            let fontSize: CGFloat = day < 10 ? 12 : 11
            let attributes: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: fontSize, weight: .bold),
                .foregroundColor: NSColor.white
            ]

            let textSize = dayString.size(withAttributes: attributes)
            let textOrigin = NSPoint(
                x: (rect.width - textSize.width) / 2,
                y: (rect.height - textSize.height) / 2 + 1
            )
            dayString.draw(at: textOrigin, withAttributes: attributes)

            // Red accent line below
            let lineY: CGFloat = 2
            let lineWidth: CGFloat = 12
            let lineX = (rect.width - lineWidth) / 2
            let linePath = NSBezierPath(
                roundedRect: NSRect(x: lineX, y: lineY, width: lineWidth, height: 1.5),
                xRadius: 0.75,
                yRadius: 0.75
            )
            NSColor(red: 0.91, green: 0.25, blue: 0.25, alpha: 1.0).setFill()
            linePath.fill()

            return true
        }

        image.isTemplate = false
        return image
    }
}
