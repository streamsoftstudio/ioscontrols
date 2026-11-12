//
//  ScrubBar.swift
//  IOSControls
//
//  Created by Andrija Milovanovic on 8.11.2026.
//

#if canImport(UIKit)
import UIKit

/// A bar that shows how far something has played and that the user drags to
/// choose a new place in it: a player's position.
///
/// The whole control takes touches, so a finger can land anywhere along the
/// bar, and keeps them however far the finger strays from the line, so the
/// gestures of the views around it never cut a drag short. While the finger
/// is down, the bar thickens, `scrubValue` follows the finger
/// and `isScrubbing` is true; `value` changes only when the finger lifts, so
/// whoever owns the bar seeks once rather than at every move. VoiceOver
/// adjusts the value by `accessibilityStep`.
///
/// Events, for `addTarget(_:action:for:)` or Rx:
/// - `.editingDidBegin` as a drag starts,
/// - `.editingChanged` as it moves, with `scrubValue` under the finger,
/// - `.valueChanged` when a drag ends, or VoiceOver adjusts, with the new
///   `value`,
/// - `.editingDidEnd` when a drag ends, cancelled or not.
///
/// Every colour and measurement comes from `style`, which can be replaced at
/// any time. Colours may be dynamic, and then follow the trait collection.
open class ScrubBar: UIControl {

    public struct Style {

        /// The part still to play.
        public var trackColor: UIColor

        /// The part played.
        public var progressColor: UIColor

        public var barHeight: CGFloat

        /// The bar's height while a finger drags it.
        public var scrubbingBarHeight: CGFloat

        public init(
            trackColor: UIColor = .systemFill,
            progressColor: UIColor = .systemBlue,
            barHeight: CGFloat = 6,
            scrubbingBarHeight: CGFloat = 10
        ) {
            self.trackColor = trackColor
            self.progressColor = progressColor
            self.barHeight = barHeight
            self.scrubbingBarHeight = scrubbingBarHeight
        }
    }

    public var style: Style {
        didSet {
            applyColors()
            setNeedsLayout()
        }
    }

    /// How far it has played, from 0 to 1. Values outside are clamped. While
    /// a finger drags the bar, the bar shows `scrubValue` instead.
    public var value: Double = 0 {
        didSet {
            value = Self.clamped(value)
            if value != oldValue, !isScrubbing {
                layoutBar(animated: false)
            }
        }
    }

    /// Where the finger is, from 0 to 1, while scrubbing; `value` otherwise.
    public private(set) var scrubValue: Double = 0

    public private(set) var isScrubbing = false

    /// How far one VoiceOver adjustment moves the value, from 0 to 1.
    public var accessibilityStep: Double = 0.05

    /// Describes a value for VoiceOver, as "1:42 of 4:17". Without it,
    /// VoiceOver reads a percentage.
    public var accessibilityValueFormatter: ((Double) -> String)?

    /// Whether the bar changes thickness at once rather than animating.
    /// Reduce Motion, unless a test says otherwise.
    static var reducesMotion: () -> Bool = { UIAccessibility.isReduceMotionEnabled }

    private let trackLayer = CALayer()

    private let progressLayer = CALayer()

    public init(style: Style = Style()) {
        self.style = style
        super.init(frame: .zero)

        backgroundColor = .clear
        for layer in [trackLayer, progressLayer] {
            layer.actions = ["bounds": NSNull(), "position": NSNull(), "frame": NSNull(), "cornerRadius": NSNull()]
            self.layer.addSublayer(layer)
        }

        isAccessibilityElement = true
        accessibilityTraits = .adjustable
        applyColors()
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    open override var intrinsicContentSize: CGSize {
        // Tall enough to land a finger on, whatever the bar's thickness.
        CGSize(width: UIView.noIntrinsicMetric, height: 44)
    }

    open override func layoutSubviews() {
        super.layoutSubviews()
        layoutBar(animated: false)
    }

    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        // Layers hold resolved colours, so a trait change resolves them again.
        applyColors()
    }

    // MARK: Tracking

    open override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        beginScrubbing(at: touch.location(in: self).x)
        return true
    }

    open override func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        moveScrubbing(to: touch.location(in: self).x)
        return true
    }

    open override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
        if let touch {
            moveScrubbing(to: touch.location(in: self).x)
        }
        endScrubbing()
    }

    open override func cancelTracking(with event: UIEvent?) {
        cancelScrubbing()
    }

    func beginScrubbing(at x: CGFloat) {
        isScrubbing = true
        scrubValue = fraction(at: x)
        layoutBar(animated: true)
        sendActions(for: .editingDidBegin)
    }

    func moveScrubbing(to x: CGFloat) {
        guard isScrubbing else { return }
        scrubValue = fraction(at: x)
        layoutBar(animated: false)
        sendActions(for: .editingChanged)
    }

    func endScrubbing() {
        guard isScrubbing else { return }
        // Set while still scrubbing, so that only the thickness animates.
        value = scrubValue
        isScrubbing = false
        layoutBar(animated: true)
        sendActions(for: .valueChanged)
        sendActions(for: .editingDidEnd)
    }

    func cancelScrubbing() {
        guard isScrubbing else { return }
        isScrubbing = false
        scrubValue = value
        layoutBar(animated: true)
        sendActions(for: .editingDidEnd)
    }

    /// A touch on the bar scrubs, wherever the finger drifts. The gestures of
    /// the views around it, such as a sheet's swipe to dismiss or a scroll
    /// view's pan, would otherwise take it over as the finger strays off the
    /// line, cancelling the scrub; they begin only from touches elsewhere.
    open override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard gestureRecognizer.view?.isDescendant(of: self) == true else { return false }
        return super.gestureRecognizerShouldBegin(gestureRecognizer)
    }

    // MARK: Accessibility

    open override var accessibilityValue: String? {
        get {
            if let accessibilityValueFormatter {
                return accessibilityValueFormatter(value)
            }
            return "\(Int((value * 100).rounded())) percent"
        }
        set {}
    }

    open override func accessibilityIncrement() {
        adjust(by: accessibilityStep)
    }

    open override func accessibilityDecrement() {
        adjust(by: -accessibilityStep)
    }

    private func adjust(by step: Double) {
        let adjusted = Self.clamped(value + step)
        guard adjusted != value else { return }
        value = adjusted
        scrubValue = adjusted
        sendActions(for: .valueChanged)
    }

    // MARK: Drawing

    /// The bar's frame within the control for its current thickness.
    var barFrame: CGRect {
        let height = isScrubbing ? style.scrubbingBarHeight : style.barHeight
        return CGRect(x: bounds.minX, y: bounds.midY - height / 2, width: bounds.width, height: height)
    }

    /// The share of the bar shown as played.
    var displayedValue: Double {
        isScrubbing ? scrubValue : value
    }

    private func layoutBar(animated: Bool) {
        let bar = barFrame
        let played = CGRect(x: bar.minX, y: bar.minY, width: bar.width * CGFloat(displayedValue), height: bar.height)

        CATransaction.begin()
        if animated, !Self.reducesMotion() {
            CATransaction.setAnimationDuration(0.15)
            animateFrame(of: trackLayer, to: bar)
            animateFrame(of: progressLayer, to: played)
        } else {
            CATransaction.setDisableActions(true)
            trackLayer.frame = bar
            progressLayer.frame = played
        }
        trackLayer.cornerRadius = bar.height / 2
        progressLayer.cornerRadius = bar.height / 2
        CATransaction.commit()
    }

    private func animateFrame(of layer: CALayer, to frame: CGRect) {
        for (key, from, to): (String, Any, Any) in [
            ("bounds", NSValue(cgRect: layer.bounds), NSValue(cgRect: CGRect(origin: .zero, size: frame.size))),
            ("position", NSValue(cgPoint: layer.position), NSValue(cgPoint: CGPoint(x: frame.midX, y: frame.midY))),
            ("cornerRadius", layer.cornerRadius, frame.height / 2),
        ] {
            let animation = CABasicAnimation(keyPath: key)
            animation.fromValue = from
            animation.toValue = to
            layer.add(animation, forKey: key)
        }
        layer.frame = frame
    }

    private func applyColors() {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        trackLayer.backgroundColor = style.trackColor.resolvedColor(with: traitCollection).cgColor
        progressLayer.backgroundColor = style.progressColor.resolvedColor(with: traitCollection).cgColor
        CATransaction.commit()
    }

    private func fraction(at x: CGFloat) -> Double {
        guard bounds.width > 0 else { return 0 }
        return Self.clamped(Double((x - bounds.minX) / bounds.width))
    }

    private static func clamped(_ value: Double) -> Double {
        value.isFinite ? min(max(value, 0), 1) : 0
    }
}
#endif
