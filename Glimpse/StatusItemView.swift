import AppKit

@MainActor
final class StatusItemView: NSView {
    private let iconView = NSImageView()
    private let separatorView = NSView()
    private let textLabel = NSTextField(labelWithString: "")
    private var activeConstraints: [NSLayoutConstraint] = []
    private var currentLayoutMode: LayoutMode?

    private enum LayoutMode: Equatable {
        case iconAndText
        case iconOnly
        case textOnly
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupViews()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    private func setupViews() {
        wantsLayer = true

        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.imageScaling = .scaleProportionallyDown
        addSubview(iconView)

        separatorView.translatesAutoresizingMaskIntoConstraints = false
        separatorView.wantsLayer = true
        addSubview(separatorView)

        textLabel.translatesAutoresizingMaskIntoConstraints = false
        textLabel.font = NSFont.systemFont(
            ofSize: AppDesign.StatusItem.fontSize, weight: .medium
        )
        textLabel.textColor = AppDesign.Colors.menuBarText
        textLabel.alignment = .center
        addSubview(textLabel)

        setAccessibilityLabel("Glimpse Calendar")
        setAccessibilityRole(.button)
    }

    func update(icon: NSImage?, text: String, showIcon: Bool, filled: Bool = false) {
        let hasText = !text.isEmpty
        let padding = AppDesign.StatusItem.padding
        let innerPadding = AppDesign.StatusItem.innerPadding
        let iconSize = AppDesign.Icon.menuBarSize

        let isDark = effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        let contentColor: NSColor = filled
            ? NSColor(white: 0.1, alpha: 1.0)
            : (isDark ? .white : AppDesign.Colors.menuBarText)
        textLabel.textColor = filled
            ? NSColor(white: 0.1, alpha: 1.0)
            : AppDesign.Colors.menuBarText
        iconView.contentTintColor = contentColor
        let separatorColor = filled ? NSColor(white: 0.1, alpha: 1.0) : (isDark ? .white : .black)
        separatorView.layer?.backgroundColor = separatorColor.cgColor

        iconView.image = icon
        iconView.isHidden = !showIcon
        separatorView.isHidden = !showIcon || !hasText
        textLabel.stringValue = text
        textLabel.isHidden = !hasText

        // Determine layout mode and only rebuild constraints when it changes
        let newMode: LayoutMode
        if showIcon && hasText {
            newMode = .iconAndText
        } else if showIcon {
            newMode = .iconOnly
        } else {
            newMode = .textOnly
        }

        if currentLayoutMode != newMode {
            NSLayoutConstraint.deactivate(activeConstraints)
            activeConstraints = buildConstraints(
                mode: newMode, padding: padding, innerPadding: innerPadding, iconSize: iconSize
            )
            NSLayoutConstraint.activate(activeConstraints)
            currentLayoutMode = newMode
        }

        textLabel.sizeToFit()
        var width = padding * 2
        if showIcon { width += iconSize }
        if showIcon && hasText {
            width += innerPadding * 2 + 1
        }
        if hasText { width += textLabel.frame.width }
        frame.size.width = ceil(width)

        needsDisplay = true

        setAccessibilityValue(text.isEmpty ? "Calendar" : text)
    }

    private func buildConstraints(
        mode: LayoutMode, padding: CGFloat, innerPadding: CGFloat, iconSize: CGFloat
    ) -> [NSLayoutConstraint] {
        switch mode {
        case .iconAndText:
            return [
                iconView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: padding),
                iconView.centerYAnchor.constraint(equalTo: centerYAnchor),
                iconView.widthAnchor.constraint(equalToConstant: iconSize),
                iconView.heightAnchor.constraint(equalToConstant: iconSize),

                separatorView.leadingAnchor.constraint(
                    equalTo: iconView.trailingAnchor, constant: innerPadding
                ),
                separatorView.topAnchor.constraint(
                    equalTo: topAnchor, constant: AppDesign.StatusItem.separatorInset
                ),
                separatorView.bottomAnchor.constraint(
                    equalTo: bottomAnchor, constant: -AppDesign.StatusItem.separatorInset
                ),
                separatorView.widthAnchor.constraint(equalToConstant: 1),

                textLabel.leadingAnchor.constraint(
                    equalTo: separatorView.trailingAnchor,
                    constant: innerPadding
                ),
                textLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
                textLabel.trailingAnchor.constraint(
                    equalTo: trailingAnchor, constant: -padding
                ),
            ]
        case .iconOnly:
            return [
                iconView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: padding),
                iconView.centerYAnchor.constraint(equalTo: centerYAnchor),
                iconView.widthAnchor.constraint(equalToConstant: iconSize),
                iconView.heightAnchor.constraint(equalToConstant: iconSize),
                iconView.trailingAnchor.constraint(
                    equalTo: trailingAnchor, constant: -padding
                ),
            ]
        case .textOnly:
            return [
                textLabel.leadingAnchor.constraint(
                    equalTo: leadingAnchor, constant: padding
                ),
                textLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
                textLabel.trailingAnchor.constraint(
                    equalTo: trailingAnchor, constant: -padding
                ),
            ]
        }
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        needsDisplay = true
    }

    override var intrinsicContentSize: NSSize {
        NSSize(width: frame.width, height: AppDesign.StatusItem.height)
    }
}
