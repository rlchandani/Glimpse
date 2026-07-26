import AppKit
import GlimpseCore
import Testing

@testable import Glimpse

@MainActor
struct MenuBarItemRendererTests {

    private func opts(
        showIcon: Bool = true,
        showDayOfWeek: Bool = true,
        showFilledBackground: Bool = false
    ) -> MenuBarDisplayOptions {
        MenuBarDisplayOptions(
            showIcon: showIcon,
            showDayOfWeek: showDayOfWeek,
            showMonth: false,
            showDate: false,
            showYear: false,
            showFilledBackground: showFilledBackground
        )
    }

    @Test
    func render_returnsNonEmptyImage() {
        let image = MenuBarItemRenderer.render(
            options: opts(), dateString: "Sun", isDark: false
        )
        #expect(image.size.width > 0)
        #expect(image.size.height > 0)
        #expect(!image.representations.isEmpty)
        // Not a template — we draw explicit colors the menu bar must not tint.
        #expect(image.isTemplate == false)
    }

    @Test
    func render_iconAndTextWiderThanIconOnly() {
        let iconOnly = MenuBarItemRenderer.render(
            options: opts(showDayOfWeek: false), dateString: "", isDark: false
        )
        let iconAndText = MenuBarItemRenderer.render(
            options: opts(), dateString: "Wednesday", isDark: false
        )
        // Adding text (plus the separator) must widen the item.
        #expect(iconAndText.size.width > iconOnly.size.width)
    }

    @Test
    func render_textOnlyOmitsIconWidth() {
        let textOnly = MenuBarItemRenderer.render(
            options: opts(showIcon: false), dateString: "Sun", isDark: false
        )
        let iconAndText = MenuBarItemRenderer.render(
            options: opts(showIcon: true), dateString: "Sun", isDark: false
        )
        // Dropping the icon (and separator) must narrow the item.
        #expect(textOnly.size.width < iconAndText.size.width)
    }

    @Test
    func render_emptyDateStillProducesIcon() {
        // With no text, the icon is always shown (menu bar item can't be empty).
        let image = MenuBarItemRenderer.render(
            options: opts(showIcon: false), dateString: "", isDark: false
        )
        #expect(image.size.width > 0)
    }

    @Test
    func render_filledAndBorderedBothValid() {
        let bordered = MenuBarItemRenderer.render(
            options: opts(showFilledBackground: false), dateString: "Sun", isDark: false
        )
        let filled = MenuBarItemRenderer.render(
            options: opts(showFilledBackground: true), dateString: "Sun", isDark: false
        )
        // Filled vs bordered keep the same width (only styling differs).
        #expect(abs(bordered.size.width - filled.size.width) < 0.5)
    }
}
