import AppKit

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
        borderLayer.cornerRadius = 5
        borderLayer.borderWidth = 1
        borderLayer.borderColor = NSColor.secondaryLabelColor.withAlphaComponent(0.3).cgColor
        layer?.addSublayer(borderLayer)

        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.imageScaling = .scaleProportionallyDown
        addSubview(iconView)

        separatorView.translatesAutoresizingMaskIntoConstraints = false
        separatorView.wantsLayer = true
        separatorView.layer?.backgroundColor = NSColor.secondaryLabelColor.withAlphaComponent(0.3).cgColor
        addSubview(separatorView)

        textLabel.translatesAutoresizingMaskIntoConstraints = false
        textLabel.font = NSFont.systemFont(ofSize: 12, weight: .medium)
        textLabel.textColor = .white
        textLabel.alignment = .center
        addSubview(textLabel)
    }

    func update(icon: NSImage?, text: String, showIcon: Bool) {
        let hasText = !text.isEmpty

        iconView.image = icon
        iconView.isHidden = !showIcon
        separatorView.isHidden = !showIcon || !hasText
        textLabel.stringValue = text
        textLabel.isHidden = !hasText

        // Remove old constraints
        removeConstraints(constraints)
        iconView.removeConstraints(iconView.constraints)

        var viewConstraints: [NSLayoutConstraint] = []
        let padding: CGFloat = 6
        let innerPadding: CGFloat = 4

        if showIcon && hasText {
            // Icon | separator | text
            viewConstraints += [
                iconView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: padding),
                iconView.centerYAnchor.constraint(equalTo: centerYAnchor),
                iconView.widthAnchor.constraint(equalToConstant: 18),
                iconView.heightAnchor.constraint(equalToConstant: 18),

                separatorView.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: innerPadding),
                separatorView.topAnchor.constraint(equalTo: topAnchor, constant: 4),
                separatorView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4),
                separatorView.widthAnchor.constraint(equalToConstant: 1),

                textLabel.leadingAnchor.constraint(equalTo: separatorView.trailingAnchor, constant: innerPadding),
                textLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
                textLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -padding),
            ]
        } else if showIcon {
            // Icon only
            viewConstraints += [
                iconView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: padding),
                iconView.centerYAnchor.constraint(equalTo: centerYAnchor),
                iconView.widthAnchor.constraint(equalToConstant: 18),
                iconView.heightAnchor.constraint(equalToConstant: 18),
                iconView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -padding),
            ]
        } else if hasText {
            // Text only
            viewConstraints += [
                textLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: padding),
                textLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
                textLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -padding),
            ]
        }

        NSLayoutConstraint.activate(viewConstraints)
        needsLayout = true

        // Calculate intrinsic width
        textLabel.sizeToFit()
        var width = padding * 2
        if showIcon { width += 18 }
        if showIcon && hasText { width += innerPadding * 2 + 1 } // separator + padding
        if hasText { width += textLabel.frame.width }
        frame.size.width = ceil(width)
    }

    override func layout() {
        super.layout()
        borderLayer.frame = bounds.insetBy(dx: 1, dy: 1)
    }

    override var intrinsicContentSize: NSSize {
        NSSize(width: frame.width, height: 30)
    }
}
