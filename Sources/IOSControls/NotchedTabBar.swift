//
//  NotchedTabBar.swift
//  IOSControls
//
//  Created by Andrija Milovanovic on 4.10.2026.
//

#if canImport(UIKit)
import UIKit

/// A tab bar with a round control raised out of a notch in the middle of its
/// top edge: a play button, a camera button, a now-playing disc.
///
/// The items split around the control, the first half before it and the rest
/// after it, each half spread evenly across its side. Every colour, font and
/// measurement comes from `style`, which can be replaced at any time. Colours
/// may be dynamic, and then follow the trait collection, so an app theme set
/// through traits recolours the bar.
///
/// The bar reaches into the bottom safe area. Only its own shape and the
/// control take touches; the clear space beside the raised control passes
/// them to the view behind.
public final class NotchedTabBar: UIView {

    public struct Item {

        public var title: String

        /// Drawn above the title, in the style's icon colour or, when the item
        /// is selected, its selected colour.
        public var image: UIImage?

        public init(title: String, image: UIImage?) {
            self.title = title
            self.image = image
        }
    }

    public struct Style {

        /// The bar's fill, from its top leading corner down; one colour fills
        /// it flat.
        public var backgroundColors: [UIColor]

        /// A soft light in the bar's lower trailing corner, or nil for none.
        public var glowColor: UIColor?

        /// The selected item's image and title.
        public var selectedColor: UIColor

        public var imageColor: UIColor

        public var titleColor: UIColor

        public var titleFont: UIFont

        /// The bar's height above the bottom safe area, which the views above
        /// it should leave clear.
        public var contentHeight: CGFloat

        public var controlDiameter: CGFloat

        /// How far the control rises above the bar's top edge.
        public var overhang: CGFloat

        /// Between the control and the notch's edge.
        public var notchGap: CGFloat

        /// The curve that rounds the notch into the top edge.
        public var filletRadius: CGFloat

        public var cornerRadius: CGFloat

        public init(
            backgroundColors: [UIColor] = [.secondarySystemBackground],
            glowColor: UIColor? = nil,
            selectedColor: UIColor = .systemBlue,
            imageColor: UIColor = .label,
            titleColor: UIColor = .secondaryLabel,
            titleFont: UIFont = .systemFont(ofSize: 12),
            contentHeight: CGFloat = 68,
            controlDiameter: CGFloat = 72,
            overhang: CGFloat = 12,
            notchGap: CGFloat = 5,
            filletRadius: CGFloat = 10,
            cornerRadius: CGFloat = 22
        ) {
            self.backgroundColors = backgroundColors
            self.glowColor = glowColor
            self.selectedColor = selectedColor
            self.imageColor = imageColor
            self.titleColor = titleColor
            self.titleFont = titleFont
            self.contentHeight = contentHeight
            self.controlDiameter = controlDiameter
            self.overhang = overhang
            self.notchGap = notchGap
            self.filletRadius = filletRadius
            self.cornerRadius = cornerRadius
        }

        /// The bar's height above the bottom safe area, the raised control
        /// included.
        public var heightAboveSafeArea: CGFloat {
            contentHeight + overhang
        }
    }

    public var style: Style {
        didSet {
            applyStyle()
            setNeedsLayout()
            setNeedsDisplay()
        }
    }

    public let items: [Item]

    /// The control raised in the notch.
    public let control: UIView

    public var selectedIndex: Int {
        didSet { updateSelection() }
    }

    /// Called with the index of the item the user tapped, the selected one
    /// included. The bar does not change its selection itself.
    public var onSelect: ((Int) -> Void)?

    private var itemControls: [ItemControl] = []

    private var shape: NotchedTabBarShape?

    private var outline: CGPath?

    /// The bounds `outline` was made for.
    private var outlineBounds = CGRect.null

    public init(items: [Item], control: UIView, style: Style = Style()) {
        precondition(!items.isEmpty, "a tab bar needs at least one item")
        self.items = items
        self.control = control
        self.style = style
        selectedIndex = 0
        super.init(frame: .zero)

        isOpaque = false
        backgroundColor = .clear
        contentMode = .redraw
        accessibilityTraits = .tabBar

        for (index, item) in items.enumerated() {
            let itemControl = ItemControl(item: item, index: index)
            itemControl.addTarget(self, action: #selector(itemTapped(_:)), for: .touchUpInside)
            addSubview(itemControl)
            itemControls.append(itemControl)
        }
        addSubview(control)
        addInteraction(UILargeContentViewerInteraction())

        applyStyle()
        updateSelection()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    /// The view standing for the item at `index`, for tests and for anchoring
    /// popovers to a tab.
    public func itemView(at index: Int) -> UIControl {
        itemControls[index]
    }

    // MARK: Layout

    public override func layoutSubviews() {
        super.layoutSubviews()

        let radius = style.controlDiameter / 2
        // The control's top meets the bar view's top; the bar's edge runs the
        // overhang below it.
        let center = CGPoint(x: bounds.midX, y: radius)
        let shape = NotchedTabBarShape(
            top: style.overhang,
            controlCenter: center,
            controlRadius: radius,
            gap: style.notchGap,
            filletRadius: style.filletRadius,
            cornerRadius: style.cornerRadius
        )
        if shape != self.shape || bounds != outlineBounds {
            self.shape = shape
            outline = shape.path(in: bounds)
            outlineBounds = bounds
            setNeedsDisplay()
        }

        control.bounds = CGRect(x: 0, y: 0, width: style.controlDiameter, height: style.controlDiameter)
        control.center = center

        let content = bounds.inset(by: UIEdgeInsets(top: 0, left: safeAreaInsets.left, bottom: 0, right: safeAreaInsets.right))
        let clearance = max(shape.notchHalfWidth, radius)
        let leadingCount = (itemControls.count + 1) / 2
        place(itemControls[..<leadingCount], from: content.minX, to: center.x - clearance)
        place(itemControls[leadingCount...], from: center.x + clearance, to: content.maxX)
    }

    private func place(_ controls: ArraySlice<ItemControl>, from minX: CGFloat, to maxX: CGFloat) {
        guard !controls.isEmpty else { return }
        let width = max(0, maxX - minX) / CGFloat(controls.count)
        for (offset, itemControl) in controls.enumerated() {
            itemControl.frame = CGRect(
                x: minX + CGFloat(offset) * width,
                y: style.overhang,
                width: width,
                height: style.contentHeight
            )
        }
    }

    // MARK: Drawing

    public override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext(), let outline, let shape else { return }

        context.saveGState()
        context.addPath(outline)
        context.clip()

        let colors = style.backgroundColors.map { $0.resolvedColor(with: traitCollection).cgColor }
        if colors.count > 1, let gradient = CGGradient(colorsSpace: nil, colors: colors as CFArray, locations: nil) {
            context.drawLinearGradient(
                gradient,
                start: CGPoint(x: bounds.minX, y: shape.top),
                end: CGPoint(x: bounds.midX, y: bounds.maxY),
                options: [.drawsBeforeStartLocation, .drawsAfterEndLocation]
            )
        } else if let color = colors.first {
            context.setFillColor(color)
            context.fill(bounds)
        }

        if let glow = style.glowColor?.resolvedColor(with: traitCollection),
           let gradient = CGGradient(colorsSpace: nil, colors: [glow.cgColor, glow.withAlphaComponent(0).cgColor] as CFArray, locations: nil) {
            let center = CGPoint(x: bounds.minX + bounds.width * 0.78, y: bounds.maxY)
            context.drawRadialGradient(
                gradient,
                startCenter: center, startRadius: 0,
                endCenter: center, endRadius: bounds.width * 0.55,
                options: []
            )
        }
        context.restoreGState()
    }

    // MARK: Touches

    public override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        if control.frame.contains(point) {
            return true
        }
        return outline?.contains(point) ?? false
    }

    // MARK: Items

    @objc private func itemTapped(_ sender: ItemControl) {
        onSelect?(sender.index)
    }

    private func applyStyle() {
        for itemControl in itemControls {
            itemControl.apply(style)
        }
    }

    private func updateSelection() {
        for itemControl in itemControls {
            itemControl.isSelected = itemControl.index == selectedIndex
        }
    }
}

// MARK: - Item

/// One item: its image above its title, in the selected colour when selected.
private final class ItemControl: UIControl {

    let index: Int

    private let imageView = UIImageView()

    private let titleLabel = UILabel()

    private var style = NotchedTabBar.Style()

    init(item: NotchedTabBar.Item, index: Int) {
        self.index = index
        super.init(frame: .zero)

        imageView.image = item.image
        imageView.contentMode = .center
        titleLabel.text = item.title
        titleLabel.textAlignment = .center
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.75
        for view in [imageView, titleLabel] as [UIView] {
            view.isUserInteractionEnabled = false
            addSubview(view)
        }

        isAccessibilityElement = true
        accessibilityLabel = item.title
        showsLargeContentViewer = true
        largeContentTitle = item.title
        largeContentImage = item.image
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override var isSelected: Bool {
        didSet { updateColors() }
    }

    override var isHighlighted: Bool {
        didSet { alpha = isHighlighted ? 0.6 : 1 }
    }

    func apply(_ style: NotchedTabBar.Style) {
        self.style = style
        titleLabel.font = style.titleFont
        updateColors()
        setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let imageHeight: CGFloat = 28
        let spacing: CGFloat = 2
        let titleHeight = ceil(style.titleFont.lineHeight)
        let top = ((bounds.height - imageHeight - spacing - titleHeight) / 2).rounded()
        imageView.frame = CGRect(x: 0, y: top, width: bounds.width, height: imageHeight)
        titleLabel.frame = CGRect(x: 4, y: top + imageHeight + spacing, width: bounds.width - 8, height: titleHeight)
    }

    private func updateColors() {
        imageView.tintColor = isSelected ? style.selectedColor : style.imageColor
        titleLabel.textColor = isSelected ? style.selectedColor : style.titleColor
        accessibilityTraits = isSelected ? [.button, .selected] : .button
    }
}
#endif
