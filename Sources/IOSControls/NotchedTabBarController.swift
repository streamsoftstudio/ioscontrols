//
//  NotchedTabBarController.swift
//  IOSControls
//
//  Created by Andrija Milovanovic on 4.10.2026.
//

#if canImport(UIKit)
import UIKit

/// A container that shows one view controller per tab above a
/// `NotchedTabBar`, as `UITabBarController` does above its own bar.
///
/// A container of its own, rather than a styled `UITabBarController`, so the
/// bar looks the same on every iOS version and its control can rise out of
/// it. Each tab's view controller is kept while another is shown, and leaves
/// room for the bar through its safe area. Choosing the tab already shown
/// takes a navigation controller back to its first screen.
open class NotchedTabBarController: UIViewController {

    public struct Tab {

        public var item: NotchedTabBar.Item

        public var viewController: UIViewController

        public init(item: NotchedTabBar.Item, viewController: UIViewController) {
            self.item = item
            self.viewController = viewController
        }
    }

    public let tabBar: NotchedTabBar

    public let viewControllers: [UIViewController]

    public var selectedIndex: Int {
        tabBar.selectedIndex
    }

    public var selectedViewController: UIViewController {
        viewControllers[selectedIndex]
    }

    /// The bar's look. Replacing it restyles the bar and the room the tabs
    /// leave for it.
    public var style: NotchedTabBar.Style {
        get { tabBar.style }
        set {
            tabBar.style = newValue
            updateTabBarHeight()
        }
    }

    private var tabBarHeight: NSLayoutConstraint?

    public init(tabs: [Tab], control: UIView, style: NotchedTabBar.Style = NotchedTabBar.Style()) {
        tabBar = NotchedTabBar(items: tabs.map(\.item), control: control, style: style)
        viewControllers = tabs.map(\.viewController)
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    open override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground
        tabBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tabBar)
        // The bar's top sits its height above the safe area, and its bottom
        // reaches the screen's edge.
        let height = tabBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        NSLayoutConstraint.activate([
            tabBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tabBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tabBar.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            height,
        ])
        tabBarHeight = height
        updateTabBarHeight()

        tabBar.onSelect = { [weak self] index in
            self?.select(index)
        }
        show(selectedIndex)
    }

    /// Shows the tab at `index`. Choosing the tab already shown takes its
    /// navigation controller, if it is one, back to its first screen.
    public func select(_ index: Int) {
        guard viewControllers.indices.contains(index) else { return }
        guard index != selectedIndex else {
            (viewControllers[index] as? UINavigationController)?.popToRootViewController(animated: view.window != nil)
            return
        }
        tabBar.selectedIndex = index
        if isViewLoaded {
            show(index)
        }
    }

    open override var childForStatusBarStyle: UIViewController? {
        selectedViewController
    }

    open override var childForStatusBarHidden: UIViewController? {
        selectedViewController
    }

    open override var childForHomeIndicatorAutoHidden: UIViewController? {
        selectedViewController
    }

    private func show(_ index: Int) {
        let selected = viewControllers[index]
        for child in viewControllers where child !== selected && child.parent === self {
            child.willMove(toParent: nil)
            child.view.removeFromSuperview()
            child.removeFromParent()
        }
        guard selected.parent !== self else { return }

        addChild(selected)
        selected.additionalSafeAreaInsets.bottom = tabBar.style.contentHeight
        selected.view.frame = view.bounds
        selected.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.insertSubview(selected.view, belowSubview: tabBar)
        selected.didMove(toParent: self)
        setNeedsStatusBarAppearanceUpdate()
    }

    private func updateTabBarHeight() {
        tabBarHeight?.constant = -tabBar.style.heightAboveSafeArea
        for child in viewControllers {
            child.additionalSafeAreaInsets.bottom = tabBar.style.contentHeight
        }
    }
}
#endif
