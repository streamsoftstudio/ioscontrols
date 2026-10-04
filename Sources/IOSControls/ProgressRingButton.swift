//
//  ProgressRingButton.swift
//  IOSControls
//
//  Created by Andrija Milovanovic on 4.10.2026.
//

#if canImport(UIKit)
import UIKit

/// A round button ringed by progress, with an image inside the ring: the
/// cover of what is playing, ringed by how far it has played.
///
/// When there is no image, the placeholder shows instead. Every colour and
/// measurement comes from `style`, which can be replaced at any time. Colours
/// may be dynamic, and then follow the trait collection.
open class ProgressRingButton: UIControl {

    public struct Style {

        public var fillColor: UIColor

        /// A thin line around the edge, or clear for none.
        public var rimColor: UIColor

        /// The part of the ring done.
        public var ringColor: UIColor

        /// The part of the ring still to go.
        public var ringTrackColor: UIColor

        public var placeholderColor: UIColor

        /// The shadow beneath the button, or nil for none.
        public var shadowColor: UIColor?

        public var ringWidth: CGFloat

        /// Between the button's edge and the ring.
        public var ringInset: CGFloat

        /// Between the button's edge and the image.
        public var imageInset: CGFloat

        public init(
            fillColor: UIColor = .secondarySystemBackground,
            rimColor: UIColor = .clear,
            ringColor: UIColor = .systemBlue,
            ringTrackColor: UIColor = .systemFill,
            placeholderColor: UIColor = .label,
            shadowColor: UIColor? = UIColor.black.withAlphaComponent(0.5),
            ringWidth: CGFloat = 3,
            ringInset: CGFloat = 4,
            imageInset: CGFloat = 11
        ) {
            self.fillColor = fillColor
            self.rimColor = rimColor
            self.ringColor = ringColor
            self.ringTrackColor = ringTrackColor
            self.placeholderColor = placeholderColor
            self.shadowColor = shadowColor
            self.ringWidth = ringWidth
            self.ringInset = ringInset
            self.imageInset = imageInset
        }
    }

    public var style: Style {
        didSet {
            applyStyle()
            setNeedsLayout()
            setNeedsDisplay()
        }
    }

    /// From 0 to 1, drawn clockwise from the top. Values outside are clamped.
    public var progress: Double = 0 {
        didSet {
            if progress != oldValue {
                setNeedsDisplay()
            }
        }
    }

    /// Shown inside the ring, cropped to a circle.
    public var image: UIImage? {
        didSet { updateContent() }
    }

    /// Shown when there is no image.
    public var placeholderImage: UIImage? {
        didSet { placeholderView.image = placeholderImage }
    }

    /// Shows the content at half strength, as when there is nothing to show
    /// yet. The button stays enabled.
    public var isDimmed = false {
        didSet { updateContent() }
    }

    private let imageView = UIImageView()

    private let placeholderView = UIImageView()

    public init(style: Style = Style()) {
        self.style = style
        super.init(frame: .zero)

        isOpaque = false
        backgroundColor = .clear
        contentMode = .redraw

        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        placeholderView.contentMode = .center
        for view in [imageView, placeholderView] {
            view.isUserInteractionEnabled = false
            addSubview(view)
        }

        isAccessibilityElement = true
        accessibilityTraits = .button
        showsLargeContentViewer = true

        applyStyle()
        updateContent()
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    open override var isHighlighted: Bool {
        didSet {
            transform = isHighlighted ? CGAffineTransform(scaleX: 0.94, y: 0.94) : .identity
        }
    }

    open override var accessibilityLabel: String? {
        didSet { largeContentTitle = accessibilityLabel }
    }

    open override func layoutSubviews() {
        super.layoutSubviews()

        layer.shadowPath = UIBezierPath(ovalIn: bounds).cgPath
        layer.shadowColor = style.shadowColor?.resolvedColor(with: traitCollection).cgColor

        imageView.frame = bounds.insetBy(dx: style.imageInset, dy: style.imageInset)
        imageView.layer.cornerRadius = imageView.bounds.width / 2
        placeholderView.frame = bounds
    }

    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        // The shadow is the one colour held by a layer rather than drawn.
        setNeedsLayout()
    }

    open override func draw(_ rect: CGRect) {
        let disc = UIBezierPath(ovalIn: bounds.insetBy(dx: 0.5, dy: 0.5))
        style.fillColor.resolvedColor(with: traitCollection).setFill()
        disc.fill()
        style.rimColor.resolvedColor(with: traitCollection).setStroke()
        disc.lineWidth = 1
        disc.stroke()

        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let radius = bounds.width / 2 - style.ringInset - style.ringWidth / 2
        guard radius > 0 else { return }

        let track = UIBezierPath(arcCenter: center, radius: radius, startAngle: 0, endAngle: 2 * .pi, clockwise: true)
        track.lineWidth = style.ringWidth
        style.ringTrackColor.resolvedColor(with: traitCollection).setStroke()
        track.stroke()

        let done = CGFloat(min(max(progress, 0), 1))
        guard done > 0 else { return }
        let ring = UIBezierPath(
            arcCenter: center,
            radius: radius,
            startAngle: -.pi / 2,
            endAngle: -.pi / 2 + 2 * .pi * done,
            clockwise: true
        )
        ring.lineWidth = style.ringWidth
        ring.lineCapStyle = .round
        style.ringColor.resolvedColor(with: traitCollection).setStroke()
        ring.stroke()
    }

    private func applyStyle() {
        layer.shadowOpacity = style.shadowColor == nil ? 0 : 1
        layer.shadowRadius = 14
        layer.shadowOffset = CGSize(width: 0, height: 8)
        placeholderView.tintColor = style.placeholderColor
    }

    private func updateContent() {
        imageView.image = image
        imageView.isHidden = image == nil
        placeholderView.isHidden = image != nil
        let alpha: CGFloat = isDimmed ? 0.5 : 1
        imageView.alpha = alpha
        placeholderView.alpha = alpha
    }
}
#endif
