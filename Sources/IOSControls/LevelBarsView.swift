//
//  LevelBarsView.swift
//  IOSControls
//
//  Created by Andrija Milovanovic on 5.10.2026.
//

#if canImport(UIKit)
import UIKit

/// A few upright bars that rise and fall with how loud something is: the
/// mark a list puts on the track that is playing.
///
/// Feed it levels from 0 to 1, many times a second, as from an audio meter.
/// A bar jumps up to a louder level at once and falls back to a quieter one
/// over a few updates, as a meter's needle does, and holds still between
/// updates, so the bars of a paused track stay where they stopped. With
/// Reduce Motion on, the bars stand still in a fixed pattern instead.
///
/// Every colour and measurement comes from `style`, which can be replaced at
/// any time. The colour may be dynamic, and then follows the trait
/// collection.
open class LevelBarsView: UIView {

    public struct Style {

        public var color: UIColor

        public var barCount: Int

        public var barWidth: CGFloat

        /// Between two bars.
        public var spacing: CGFloat

        /// How high a bar stands at silence, as a share of the view's height,
        /// so that the bars never vanish.
        public var minimumHeight: CGFloat

        /// How much of the way down to a quieter level a bar goes at each
        /// update: from 0, never, to 1, at once.
        public var fall: CGFloat

        public init(
            color: UIColor = .systemBlue,
            barCount: Int = 3,
            barWidth: CGFloat = 3,
            spacing: CGFloat = 2,
            minimumHeight: CGFloat = 0.2,
            fall: CGFloat = 0.35
        ) {
            self.color = color
            self.barCount = barCount
            self.barWidth = barWidth
            self.spacing = spacing
            self.minimumHeight = minimumHeight
            self.fall = fall
        }
    }

    /// The pattern shown while Reduce Motion is on.
    public static let stillHeights: [CGFloat] = [0.55, 1, 0.75]

    public var style: Style {
        didSet {
            rebuildBars()
            invalidateIntrinsicContentSize()
            setNeedsLayout()
        }
    }

    /// The bars' heights now, from 0 to 1, one per bar, before the minimum
    /// height is applied.
    public private(set) var heights: [CGFloat]

    /// Whether the bars stand still rather than follow the levels. Reduce
    /// Motion, unless a test says otherwise.
    static var reducesMotion: () -> Bool = { UIAccessibility.isReduceMotionEnabled }

    private var bars: [CALayer] = []

    public init(style: Style = Style()) {
        self.style = style
        heights = Array(repeating: 0, count: style.barCount)
        super.init(frame: .zero)

        isUserInteractionEnabled = false
        isAccessibilityElement = false
        rebuildBars()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(reduceMotionChanged),
            name: UIAccessibility.reduceMotionStatusDidChangeNotification,
            object: nil
        )
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    /// Moves the bars towards `levels`, one per bar from 0 to 1. A missing
    /// level counts as silence, and levels outside the range are clamped.
    public func setLevels(_ levels: [Double]) {
        for index in heights.indices {
            let level = index < levels.count ? CGFloat(min(max(levels[index], 0), 1)) : 0
            let current = heights[index]
            heights[index] = level >= current ? level : current - (current - level) * style.fall
        }
        setNeedsLayout()
    }

    /// Drops every bar to silence at once.
    public func reset() {
        heights = Array(repeating: 0, count: style.barCount)
        setNeedsLayout()
    }

    open override var intrinsicContentSize: CGSize {
        let count = CGFloat(style.barCount)
        return CGSize(width: count * style.barWidth + max(count - 1, 0) * style.spacing, height: UIView.noIntrinsicMetric)
    }

    open override func layoutSubviews() {
        super.layoutSubviews()

        let shown = Self.reducesMotion() ? Self.stillHeights : heights
        let width = intrinsicContentSize.width
        var x = (bounds.width - width) / 2

        // Moved at once: at many updates a second, an animation would lag.
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        for (index, bar) in bars.enumerated() {
            let share = index < shown.count ? shown[index] : 0
            let height = bounds.height * max(style.minimumHeight, min(share, 1))
            bar.frame = CGRect(x: x, y: bounds.height - height, width: style.barWidth, height: height)
            bar.cornerRadius = style.barWidth / 2
            bar.backgroundColor = style.color.resolvedColor(with: traitCollection).cgColor
            x += style.barWidth + style.spacing
        }
        CATransaction.commit()
    }

    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        // The colour is held by layers, so it is resolved again.
        setNeedsLayout()
    }

    private func rebuildBars() {
        bars.forEach { $0.removeFromSuperlayer() }
        bars = (0..<max(style.barCount, 0)).map { _ in CALayer() }
        bars.forEach(layer.addSublayer)
        heights = Array(heights.prefix(style.barCount)) + Array(repeating: 0, count: max(style.barCount - heights.count, 0))
    }

    @objc private func reduceMotionChanged() {
        setNeedsLayout()
    }
}
#endif
