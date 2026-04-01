import AppKit

@MainActor
final class StatusItemView: NSView {
    private let iconView = NSImageView()
    private let separatorView = NSView()
    private let textLabel = NSTextField(labelWithString: "")
    private var isFilled = false

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
        separatorView.layer?.backgroundColor = AppDesign.Colors.menuBarSeparator
            .withAlphaComponent(AppDesign.StatusItem.borderOpacity).cgColor
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

        isFilled = filled

        let isDark = effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        textLabel.textColor = filled
            ? NSColor(white: 0.1, alpha: 1.0)
            : AppDesign.Colors.menuBarText
        iconView.contentTintColor = filled
            ? NSColor(white: 0.1, alpha: 1.0)
            : (isDark ? .white : AppDesign.Colors.menuBarText)

        iconView.image = icon
        iconView.isHidden = !showIcon
        separatorView.isHidden = !showIcon || !hasText || filled
        textLabel.stringValue = text
        textLabel.isHidden = !hasText

        removeConstraints(constraints)
        iconView.removeConstraints(iconView.constraints)

        var viewConstraints: [NSLayoutConstraint] = []

        if showIcon && hasText {
            viewConstraints += [
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
                    equalTo: filled
                        ? iconView.trailingAnchor
                        : separatorView.trailingAnchor,
                    constant: innerPadding
                ),
                textLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
                textLabel.trailingAnchor.constraint(
                    equalTo: trailingAnchor, constant: -padding
                ),
            ]
        } else if showIcon {
            viewConstraints += [
                iconView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: padding),
                iconView.centerYAnchor.constraint(equalTo: centerYAnchor),
                iconView.widthAnchor.constraint(equalToConstant: iconSize),
                iconView.heightAnchor.constraint(equalToConstant: iconSize),
                iconView.trailingAnchor.constraint(
                    equalTo: trailingAnchor, constant: -padding
                ),
            ]
        } else if hasText {
            viewConstraints += [
                textLabel.leadingAnchor.constraint(
                    equalTo: leadingAnchor, constant: padding
                ),
                textLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
                textLabel.trailingAnchor.constraint(
                    equalTo: trailingAnchor, constant: -padding
                ),
            ]
        }

        NSLayoutConstraint.activate(viewConstraints)

        textLabel.sizeToFit()
        var width = padding * 2
        if showIcon { width += iconSize }
        if showIcon && hasText {
            width += filled ? innerPadding : (innerPadding * 2 + 1)
        }
        if hasText { width += textLabel.frame.width }
        frame.size.width = ceil(width)

        needsDisplay = true

        setAccessibilityValue(text.isEmpty ? "Calendar" : text)
    }

    override func draw(_ dirtyRect: NSRect) {
        let rect = bounds.insetBy(dx: 1, dy: 1)
        let path = NSBezierPath(
            roundedRect: rect,
            xRadius: AppDesign.StatusItem.borderCornerRadius,
            yRadius: AppDesign.StatusItem.borderCornerRadius
        )

        if isFilled {
            let isDark = effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            let fillColor = isDark
                ? NSColor(white: 0.85, alpha: 1.0)
                : NSColor(white: 0.92, alpha: 1.0)
            fillColor.setFill()
            path.fill()

            let borderColor = isDark
                ? NSColor(white: 0.65, alpha: 1.0)
                : NSColor(white: 0.78, alpha: 1.0)
            borderColor.setStroke()
            path.lineWidth = AppDesign.StatusItem.borderWidth
            path.stroke()
        } else {
            AppDesign.Colors.menuBarBorder
                .withAlphaComponent(AppDesign.StatusItem.borderOpacity)
                .setStroke()
            path.lineWidth = AppDesign.StatusItem.borderWidth
            path.stroke()
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
