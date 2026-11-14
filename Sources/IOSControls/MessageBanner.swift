//
//  MessageBanner.swift
//  IOSControls
//
//  Created by Andrija Milovanovic on 14.11.2026.
//

#if canImport(UIKit)
import UIKit

/// A short message in a card: a title, a line or two under it, and an
/// image beside them. `MessageBannerCenter` shows one over the screen.
///
/// VoiceOver reads the card as one element, the title and then the body,
/// and its escape gesture dismisses it, as a tap or a swipe up does.
///
/// Every colour, font and measurement comes from `style`, which can be
/// replaced at any time. Colours may be dynamic, and then follow the trait
/// collection. The fonts grow and shrink with Dynamic Type.
open class MessageBanner: UIView {

    /// What a banner says.
    public struct Message: Equatable {

        public var title: String

        /// A line or two under the title, or nil for none.
        public var body: String?

        /// Beside the text, tinted with the style's image colour, or nil
        /// for none: usually a symbol.
        public var image: UIImage?

        /// How long the banner stays, in seconds, or nil for as long as its
        /// text takes to read (`MessageBannerTiming`).
        public var duration: TimeInterval?

        public init(title: String, body: String? = nil, image: UIImage? = nil, duration: TimeInterval? = nil) {
            self.title = title
            self.body = body
            self.image = image
            self.duration = duration
        }

        /// The title, then the body, as VoiceOver reads them.
        public var spokenText: String {
            guard let body, !body.isEmpty else { return title }
            let pause = title.last.map { ".!?:".contains($0) } == true ? " " : ". "
            return title + pause + body
        }
    }

    public struct Style {

        public var backgroundColor: UIColor

        /// A hairline around the card, or clear for none.
        public var borderColor: UIColor

        public var titleColor: UIColor

        public var bodyColor: UIColor

        public var imageColor: UIColor

        /// Grows and shrinks with Dynamic Type, as a headline does.
        public var titleFont: UIFont

        /// Grows and shrinks with Dynamic Type, as a subheadline does.
        public var bodyFont: UIFont

        public var cornerRadius: CGFloat

        /// The shadow beneath the card, or nil for none.
        public var shadowColor: UIColor?

        /// How far the shadow spreads, as `CALayer.shadowRadius`.
        public var shadowRadius: CGFloat

        /// Between the card's edges and what it holds.
        public var contentInsets: NSDirectionalEdgeInsets

        /// Between the image and the text.
        public var imageSpacing: CGFloat

        /// Between the title and the body.
        public var textSpacing: CGFloat

        /// Between the banner and the edges of the screen, inside its safe
        /// area, where `MessageBannerCenter` places it.
        public var margin: CGFloat

        /// The widest the banner grows, as on an iPad's screen.
        public var maximumWidth: CGFloat

        public init(
            backgroundColor: UIColor = .secondarySystemBackground,
            borderColor: UIColor = .separator,
            titleColor: UIColor = .label,
            bodyColor: UIColor = .secondaryLabel,
            imageColor: UIColor = .systemOrange,
            titleFont: UIFont = .systemFont(ofSize: 15, weight: .semibold),
            bodyFont: UIFont = .systemFont(ofSize: 14),
            cornerRadius: CGFloat = 16,
            shadowColor: UIColor? = UIColor.black.withAlphaComponent(0.25),
            shadowRadius: CGFloat = 12,
            contentInsets: NSDirectionalEdgeInsets = NSDirectionalEdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16),
            imageSpacing: CGFloat = 12,
            textSpacing: CGFloat = 2,
            margin: CGFloat = 12,
            maximumWidth: CGFloat = 520
        ) {
            self.backgroundColor = backgroundColor
            self.borderColor = borderColor
            self.titleColor = titleColor
            self.bodyColor = bodyColor
            self.imageColor = imageColor
            self.titleFont = titleFont
            self.bodyFont = bodyFont
            self.cornerRadius = cornerRadius
            self.shadowColor = shadowColor
            self.shadowRadius = shadowRadius
            self.contentInsets = contentInsets
            self.imageSpacing = imageSpacing
            self.textSpacing = textSpacing
            self.margin = margin
            self.maximumWidth = maximumWidth
        }
    }

    public var style: Style {
        didSet { applyStyle() }
    }

    public var message: Message {
        didSet { updateContent() }
    }

    /// Called when the listener sends the banner away: a tap, a swipe up,
    /// or VoiceOver's escape gesture.
    public var onDismiss: (() -> Void)?

    let titleLabel = UILabel()

    let bodyLabel = UILabel()

    let imageView = UIImageView()

    private let card = UIView()

    private let textStack = UIStackView()

    private let stack = UIStackView()

    private var insetConstraints: [NSLayoutConstraint] = []

    public init(message: Message, style: Style = Style()) {
        self.message = message
        self.style = style
        super.init(frame: .zero)

        card.clipsToBounds = true
        card.layer.cornerCurve = .continuous
        card.translatesAutoresizingMaskIntoConstraints = false
        addSubview(card)

        for label in [titleLabel, bodyLabel] {
            label.numberOfLines = 0
            label.adjustsFontForContentSizeCategory = true
        }
        textStack.axis = .vertical
        textStack.addArrangedSubview(titleLabel)
        textStack.addArrangedSubview(bodyLabel)

        imageView.contentMode = .scaleAspectFit
        imageView.setContentHuggingPriority(.required, for: .horizontal)
        imageView.setContentCompressionResistancePriority(.required, for: .horizontal)
        imageView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(textStyle: .title3)
        imageView.adjustsImageSizeForAccessibilityContentSizeCategory = true

        stack.axis = .horizontal
        stack.alignment = .center
        stack.addArrangedSubview(imageView)
        stack.addArrangedSubview(textStack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(stack)

        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: topAnchor),
            card.leadingAnchor.constraint(equalTo: leadingAnchor),
            card.trailingAnchor.constraint(equalTo: trailingAnchor),
            card.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])

        isAccessibilityElement = true
        accessibilityTraits = .staticText
        accessibilityCustomActions = [
            UIAccessibilityCustomAction(name: "Dismiss") { [weak self] _ in
                self?.onDismiss?()
                return true
            },
        ]

        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dismissByGesture)))
        let swipe = UISwipeGestureRecognizer(target: self, action: #selector(dismissByGesture))
        swipe.direction = .up
        addGestureRecognizer(swipe)

        applyStyle()
        updateContent()
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    open override func layoutSubviews() {
        super.layoutSubviews()
        layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: style.cornerRadius).cgPath
    }

    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        // The colours held by layers rather than drawn.
        resolveLayerColors()
    }

    open override func accessibilityPerformEscape() -> Bool {
        onDismiss?()
        return true
    }

    @objc private func dismissByGesture() {
        onDismiss?()
    }

    private func applyStyle() {
        card.backgroundColor = style.backgroundColor
        card.layer.cornerRadius = style.cornerRadius
        layer.shadowOpacity = style.shadowColor == nil ? 0 : 1
        layer.shadowRadius = style.shadowRadius
        layer.shadowOffset = CGSize(width: 0, height: 4)
        resolveLayerColors()

        titleLabel.font = UIFontMetrics(forTextStyle: .headline).scaledFont(for: style.titleFont)
        titleLabel.textColor = style.titleColor
        bodyLabel.font = UIFontMetrics(forTextStyle: .subheadline).scaledFont(for: style.bodyFont)
        bodyLabel.textColor = style.bodyColor
        imageView.tintColor = style.imageColor
        textStack.spacing = style.textSpacing
        stack.spacing = style.imageSpacing

        NSLayoutConstraint.deactivate(insetConstraints)
        let insets = style.contentInsets
        insetConstraints = [
            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: insets.top),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: insets.leading),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -insets.trailing),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -insets.bottom),
        ]
        NSLayoutConstraint.activate(insetConstraints)
        setNeedsLayout()
    }

    private func resolveLayerColors() {
        layer.shadowColor = style.shadowColor?.resolvedColor(with: traitCollection).cgColor
        card.layer.borderColor = style.borderColor.resolvedColor(with: traitCollection).cgColor
        // A hairline: one pixel.
        card.layer.borderWidth = 1 / max(traitCollection.displayScale, 1)
    }

    private func updateContent() {
        titleLabel.text = message.title
        bodyLabel.text = message.body
        bodyLabel.isHidden = message.body?.isEmpty ?? true
        imageView.image = message.image
        imageView.isHidden = message.image == nil
        accessibilityLabel = message.spokenText
    }
}
#endif
