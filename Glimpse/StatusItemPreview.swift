import AppKit
import GlimpseCore
import SwiftUI

/// Renders the preferences preview using the exact same image as the real menu
/// bar item (`MenuBarItemRenderer`), so the preview can never drift from reality.
struct StatusItemPreview: NSViewRepresentable {
    let displayOptions: MenuBarDisplayOptions
    let dateString: String

    func makeNSView(context: Context) -> NSImageView {
        let view = NSImageView()
        view.imageScaling = .scaleNone
        return view
    }

    func updateNSView(_ view: NSImageView, context: Context) {
        // The menu bar item adapts to the system appearance; the preview always
        // shows the light-mode rendering so it reads correctly inside the
        // preferences card regardless of the app's appearance.
        view.image = MenuBarItemRenderer.render(
            options: displayOptions,
            dateString: dateString,
            isDark: false
        )
    }
}
