//
//  DrawerController.swift
//  IOSControls
//
//  Created by Andrija Milovanovic on 29.10.2026.
//

#if canImport(UIKit)
import UIKit

/// A container that keeps a menu beside its content, as a side menu does:
/// the menu slides in from the leading edge, over the content, which dims
/// behind it.
///
/// The menu opens with `open(animated:)`, typically from a button the
/// content shows, or with a swipe in from the leading edge while the
/// content's navigation stack is on its first screen, so that elsewhere the
/// same swipe still goes back. It closes with `close(animated:)`, a tap on
/// the dimmed content, or a swipe back. While it is open, VoiceOver keeps to
/// the menu, and the escape gesture closes it. The content can be replaced,
/// as when the menu picks another section.
///
/// Given a `dockingMinimumWidth`, the menu docks wherever the container is
/// at least that wide, as on an iPad in landscape: it stays in view beside
/// the content, which takes the rest of the width, and there is nothing to
/// open or close. Narrower, it slides over the content again, closed.
///
/// ```swift
/// let drawer = DrawerController(menu: menuController, content: libraryNavigation)
/// drawer.dockingMinimumWidth = 1100
/// drawer.openStateChanged = { isOpen in … }
/// drawer.dockStateChanged = { isDocked in … }
/// ```
open class DrawerController: UIViewController, UIGestureRecognizerDelegate {

    /// The menu, shown at `menuWidth` beside the content.
    public let menu: UIViewController

    /// What the menu opens over.
    public private(set) var content: UIViewController

    /// Whether the menu is out.
    public private(set) var isOpen = false

    /// The menu's width. On a screen too narrow for it, the menu leaves a
    /// strip of the content in view, to tap or swipe closed.
    public var menuWidth: CGFloat = 300 {
        didSet { view.setNeedsLayout() }
    }

    /// Whether a swipe in from the leading edge opens the menu.
    public var opensWithEdgeSwipe = true

    /// Told the new state whenever the menu opens or closes.
    public var openStateChanged: ((Bool) -> Void)?

    /// The width from which the menu docks beside the content rather than
    /// sliding over it. `nil`, the default, never docks.
    public var dockingMinimumWidth: CGFloat? {
        didSet { viewIfLoaded?.setNeedsLayout() }
    }

    /// Whether the menu is docked beside the content, where it stays in
    /// view and neither opens nor closes.
    public private(set) var isDocked = false

    /// Told the new state whenever the menu docks or undocks, as when the
    /// device turns or the window is resized.
    public var dockStateChanged: ((Bool) -> Void)?

    let edgePan = UIScreenEdgePanGestureRecognizer()

    let closePan = UIPanGestureRecognizer()

    let dimming = DimmingView()

    let menuContainer = UIView()

    /// The hairline between a docked menu and the content.
    let separator = UIView()

    private let contentContainer = UIView()

    /// How far the menu is out: 0 closed, 1 open.
    private var progress: CGFloat = 0 {
        didSet { applyProgress() }
    }

    /// The strip of content left beside a menu on a narrow screen.
    private static let contentMargin: CGFloat = 56

    public init(menu: UIViewController, content: UIViewController) {
        self.menu = menu
        self.content = content
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    open override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        contentContainer.frame = view.bounds
        contentContainer.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(contentContainer)
        embed(content, in: contentContainer)

        dimming.onTap = { [weak self] in self?.close() }
        view.addSubview(dimming)

        menuContainer.clipsToBounds = true
        view.addSubview(menuContainer)
        embed(menu, in: menuContainer)

        separator.backgroundColor = .separator
        separator.isHidden = true
        view.addSubview(separator)

        edgePan.addTarget(self, action: #selector(edgePanned(_:)))
        edgePan.delegate = self
        view.addGestureRecognizer(edgePan)
        closePan.addTarget(self, action: #selector(closePanned(_:)))
        closePan.delegate = self
        closePan.isEnabled = false
        view.addGestureRecognizer(closePan)
        applyProgress()
    }

    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateDocking()
        let bounds = view.bounds
        let width = currentMenuWidth
        menuContainer.transform = .identity
        menuContainer.frame = CGRect(
            x: isRightToLeft ? bounds.width - width : 0,
            y: 0,
            width: width,
            height: bounds.height
        )
        if isDocked {
            contentContainer.frame = CGRect(
                x: isRightToLeft ? 0 : width,
                y: 0,
                width: bounds.width - width,
                height: bounds.height
            )
            // Over the menu's edge, so the content keeps its full width.
            let hairline = 1 / max(traitCollection.displayScale, 1)
            separator.frame = CGRect(
                x: isRightToLeft ? bounds.width - width : width - hairline,
                y: 0,
                width: hairline,
                height: bounds.height
            )
        } else {
            contentContainer.frame = bounds
        }
        dimming.frame = bounds
        edgePan.edges = isRightToLeft ? .right : .left
        applyProgress()
    }

    open override var childForStatusBarStyle: UIViewController? {
        content
    }

    open override var childForStatusBarHidden: UIViewController? {
        content
    }

    // MARK: Opening and closing

    /// Slides the menu out over the content. A docked menu is already there.
    public func open(animated: Bool = true) {
        guard !isDocked else { return }
        setOpen(true, animated: animated)
    }

    /// Slides the menu away. A docked menu stays.
    public func close(animated: Bool = true) {
        guard !isDocked else { return }
        setOpen(false, animated: animated)
    }

    public func toggle(animated: Bool = true) {
        guard !isDocked else { return }
        setOpen(!isOpen, animated: animated)
    }

    /// Puts `viewController` in the content's place, as when the menu picks
    /// another section. The menu stays as it is.
    public func setContent(_ viewController: UIViewController) {
        guard viewController !== content else { return }
        let previous = content
        content = viewController
        guard isViewLoaded else { return }
        previous.willMove(toParent: nil)
        previous.view.removeFromSuperview()
        previous.removeFromParent()
        embed(viewController, in: contentContainer)
        setNeedsStatusBarAppearanceUpdate()
    }

    open override func accessibilityPerformEscape() -> Bool {
        guard isOpen else { return false }
        close()
        return true
    }

    private func setOpen(_ open: Bool, animated: Bool, velocity: CGFloat = 0) {
        let changed = open != isOpen
        isOpen = open
        closePan.isEnabled = open
        menuContainer.accessibilityViewIsModal = open
        contentContainer.accessibilityElementsHidden = open
        let settle = { self.progress = open ? 1 : 0 }
        if animated, view.window != nil {
            UIView.animate(
                withDuration: 0.3,
                delay: 0,
                usingSpringWithDamping: 0.9,
                initialSpringVelocity: velocity,
                options: [.allowUserInteraction, .beginFromCurrentState],
                animations: settle
            )
        } else {
            settle()
        }
        guard changed else { return }
        openStateChanged?(open)
        UIAccessibility.post(notification: .screenChanged, argument: open ? menuContainer : contentContainer)
    }

    /// Docks or undocks the menu for the container's width. Either way the
    /// menu ends up closed: docked, it is simply there, and undocked, it
    /// waits to be opened.
    private func updateDocking() {
        let docks = dockingMinimumWidth.map { view.bounds.width >= $0 } ?? false
        guard docks != isDocked else { return }
        if isOpen {
            setOpen(false, animated: false)
        }
        isDocked = docks
        dockStateChanged?(docks)
    }

    private func applyProgress() {
        separator.isHidden = !isDocked
        guard !isDocked else {
            menuContainer.transform = .identity
            menuContainer.isHidden = false
            dimming.alpha = 0
            dimming.isHidden = true
            return
        }
        let offset = (1 - progress) * currentMenuWidth * (isRightToLeft ? 1 : -1)
        menuContainer.transform = CGAffineTransform(translationX: offset, y: 0)
        menuContainer.isHidden = progress == 0
        dimming.alpha = progress
        dimming.isHidden = progress == 0
    }

    // MARK: Swipes

    @objc private func edgePanned(_ gesture: UIScreenEdgePanGestureRecognizer) {
        let distance = gesture.translation(in: view).x * (isRightToLeft ? -1 : 1)
        switch gesture.state {
        case .changed:
            progress = min(max(distance / currentMenuWidth, 0), 1)
        case .ended, .cancelled:
            let speed = gesture.velocity(in: view).x * (isRightToLeft ? -1 : 1)
            setOpen(progress > 0.5 || speed > 500, animated: true, velocity: abs(speed) / currentMenuWidth)
        default:
            break
        }
    }

    @objc private func closePanned(_ gesture: UIPanGestureRecognizer) {
        let distance = gesture.translation(in: view).x * (isRightToLeft ? -1 : 1)
        switch gesture.state {
        case .changed:
            progress = min(max(1 + distance / currentMenuWidth, 0), 1)
        case .ended, .cancelled:
            let speed = gesture.velocity(in: view).x * (isRightToLeft ? -1 : 1)
            setOpen(progress > 0.5 && speed > -500, animated: true, velocity: abs(speed) / currentMenuWidth)
        default:
            break
        }
    }

    open func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer === edgePan {
            // On a pushed screen the same swipe goes back, and a docked menu
            // is already out.
            return opensWithEdgeSwipe && !isOpen && !isDocked
                && (contentNavigationController?.viewControllers.count ?? 1) <= 1
        }
        if gestureRecognizer === closePan {
            // Sideways only, so the menu's list still scrolls.
            let velocity = closePan.velocity(in: view)
            return isOpen && abs(velocity.x) > abs(velocity.y)
        }
        return true
    }

    // MARK: Helpers

    private var currentMenuWidth: CGFloat {
        max(min(menuWidth, view.bounds.width - Self.contentMargin), 1)
    }

    private var isRightToLeft: Bool {
        view.effectiveUserInterfaceLayoutDirection == .rightToLeft
    }

    /// The navigation stack the content shows: the content itself, or the
    /// first one among the controllers it holds.
    private var contentNavigationController: UINavigationController? {
        var pending = [content]
        while !pending.isEmpty {
            let controller = pending.removeFirst()
            if let navigation = controller as? UINavigationController {
                return navigation
            }
            pending += controller.children
        }
        return nil
    }

    private func embed(_ child: UIViewController, in container: UIView) {
        addChild(child)
        child.view.frame = container.bounds
        child.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        container.addSubview(child.view)
        child.didMove(toParent: self)
    }
}

/// The dimmed content beside an open menu, which closes it when tapped.
final class DimmingView: UIView {

    var onTap: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.black.withAlphaComponent(0.35)
        isAccessibilityElement = true
        accessibilityTraits = .button
        accessibilityLabel = NSLocalizedString("Close Menu", comment: "The dimmed content beside an open side menu")
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapped)))
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func accessibilityActivate() -> Bool {
        onTap?()
        return true
    }

    @objc private func tapped() {
        onTap?()
    }
}
#endif
