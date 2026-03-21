import AppKit

@MainActor
final class StatusItemView: NSView {
    private let iconView = NSImageView()
    private let separatorView = NSView()
    private let textLabel = NSTextField(labelWithString: "")
    private let borderLayer = CALayer()

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupViews()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    private func setupViews() {
        wantsLayer = true

        borderLayer.name = "border"
        borderLayer.cornerRadius = AppDesign.StatusItem.borderCornerRadius
        borderLayer.borderWidth = AppDesign.StatusItem.borderWidth
        borderLayer.borderColor = AppDesign.Colors.menuBarBorder
            .withAlphaComponent(AppDesign.StatusItem.borderOpacity).cgColor
        layer?.addSublayer(borderLayer)

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

    func update(icon: NSImage?, text: String, showIcon: Bool) {
        let hasText = !text.isEmpty
        let padding = AppDesign.StatusItem.padding
        let innerPadding = AppDesign.StatusItem.innerPadding
        let iconSize = AppDesign.Icon.menuBarSize

        iconView.image = icon
        iconView.isHidden = !showIcon
        separatorView.isHidden = !showIcon || !hasText
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
                    equalTo: separatorView.trailingAnchor, constant: innerPadding
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
        needsLayout = true

        textLabel.sizeToFit()
        var width = padding * 2
        if showIcon { width += iconSize }
        if showIcon && hasText { width += innerPadding * 2 + 1 }
        if hasText { width += textLabel.frame.width }
        frame.size.width = ceil(width)

        setAccessibilityValue(text.isEmpty ? "Calendar" : text)
    }

    override func layout() {
        super.layout()
        borderLayer.frame = bounds.insetBy(dx: 1, dy: 1)
    }

    override var intrinsicContentSize: NSSize {
        NSSize(width: frame.width, height: AppDesign.StatusItem.height)
    }
}
