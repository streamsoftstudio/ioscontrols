//
//  MessageBannerCenter.swift
//  IOSControls
//
//  Created by Andrija Milovanovic on 14.11.2026.
//

#if canImport(UIKit)
import UIKit

/// Shows short messages in a banner at the top of the screen, over
/// everything else, one at a time: a song that could not be played, a copy
/// that has finished.
///
/// The banner shows in a window of its own, in the same scene as the app's
/// window and above it, so it covers sheets and alerts too. That window
/// takes no touches but the banner's, so the screen beneath stays in use,
/// and it leaves the status bar and the orientation to the app's window.
/// Without a scene, as for a window in a test, the banner shows within the
/// app's window instead.
///
/// A banner slides down into place, stays for its message's duration, and
/// slides back up; a tap or a swipe up sends it away sooner. A message shown
/// while another is up takes its place at once. VoiceOver reads each
/// message as it shows, after whatever it is saying, keeps the banner up
/// twice as long, and sends it away with its escape gesture. With Reduce
/// Motion on, banners fade in and out instead of sliding.
public final class MessageBannerCenter {

    /// For the banners from now on, and the one showing.
    public var style: MessageBanner.Style {
        didSet { banner?.style = style }
    }

    /// Given each window made to show banners in, before it shows, to dress
    /// it as the app's own window is: in its theme's traits, its interface
    /// style, its tint.
    public var prepareWindow: ((UIWindow) -> Void)?

    /// The message showing, or nil.
    public private(set) var message: MessageBanner.Message?

    /// The banner showing, or nil.
    private(set) var banner: MessageBanner?

    /// The window banners show in once the app's window has a scene.
    private(set) var bannerWindow: MessageBannerWindow?

    private weak var window: UIWindow?

    private var dismissal: DispatchWorkItem?

    /// Whether VoiceOver runs, unless a test says otherwise.
    static var isVoiceOverRunning: () -> Bool = { UIAccessibility.isVoiceOverRunning }

    /// Whether banners fade rather than slide, unless a test says otherwise.
    static var reducesMotion: () -> Bool = { UIAccessibility.isReduceMotionEnabled }

    /// Has VoiceOver say `text` after whatever it is saying, unless a test
    /// says otherwise.
    static var announce: (String) -> Void = { text in
        UIAccessibility.post(
            notification: .announcement,
            argument: NSAttributedString(string: text, attributes: [.accessibilitySpeechQueueAnnouncement: true])
        )
    }

    /// - Parameter window: the app's window, over which banners show.
    public init(window: UIWindow, style: MessageBanner.Style = MessageBanner.Style()) {
        self.window = window
        self.style = style
    }

    /// Shows `message` in place of any message showing.
    public func show(_ message: MessageBanner.Message, animated: Bool = true) {
        dismissal?.cancel()
        self.message = message
        if let banner {
            banner.message = message
        } else if let container = container() {
            present(message, in: container, animated: animated)
        }
        Self.announce(message.spokenText)

        let duration = message.duration.map { Self.isVoiceOverRunning() ? $0 * MessageBannerTiming.voiceOverFactor : $0 }
            ?? MessageBannerTiming.duration(forText: message.spokenText, voiceOverRunning: Self.isVoiceOverRunning())
        let dismissal = DispatchWorkItem { [weak self] in self?.dismiss() }
        self.dismissal = dismissal
        DispatchQueue.main.asyncAfter(deadline: .now() + duration, execute: dismissal)
    }

    /// Sends the banner showing away.
    public func dismiss(animated: Bool = true) {
        dismissal?.cancel()
        dismissal = nil
        guard let banner else { return }
        self.banner = nil
        message = nil
        let hadFocus = banner.accessibilityElementIsFocused()
        let finish = { [weak self] in
            banner.removeFromSuperview()
            // Unless another banner has shown meanwhile.
            if self?.banner == nil {
                self?.bannerWindow?.isHidden = true
            }
            if hadFocus {
                UIAccessibility.post(notification: .layoutChanged, argument: nil)
            }
        }
        guard animated else { return finish() }
        UIView.animate(
            withDuration: 0.25,
            delay: 0,
            options: [.curveEaseIn, .beginFromCurrentState],
            animations: { self.hide(banner) },
            completion: { _ in finish() }
        )
    }

    // MARK: Showing

    /// Where the banner goes: the banners' own window over the app's, in
    /// its scene, or else the app's window itself.
    private func container() -> UIView? {
        guard let window else { return nil }
        guard let scene = window.windowScene else { return window }
        let bannerWindow = bannerWindow ?? makeWindow(in: scene, over: window)
        bannerWindow.isHidden = false
        // Sizes the root's view to the window, for the banner's layout.
        bannerWindow.layoutIfNeeded()
        return bannerWindow.rootViewController?.view
    }

    private func makeWindow(in scene: UIWindowScene, over window: UIWindow) -> MessageBannerWindow {
        let bannerWindow = MessageBannerWindow(windowScene: scene)
        bannerWindow.windowLevel = window.windowLevel + 1
        bannerWindow.backgroundColor = .clear
        let root = MessageBannerViewController()
        root.window = window
        bannerWindow.rootViewController = root
        prepareWindow?(bannerWindow)
        self.bannerWindow = bannerWindow
        return bannerWindow
    }

    private func present(_ message: MessageBanner.Message, in container: UIView, animated: Bool) {
        let banner = MessageBanner(message: message, style: style)
        banner.onDismiss = { [weak self, weak banner] in
            guard let self, let banner, banner === self.banner else { return }
            dismiss()
        }
        banner.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(banner)
        let guide = container.safeAreaLayoutGuide
        let fullWidth = banner.widthAnchor.constraint(equalTo: guide.widthAnchor, constant: -2 * style.margin)
        fullWidth.priority = .defaultHigh
        NSLayoutConstraint.activate([
            banner.topAnchor.constraint(equalTo: guide.topAnchor, constant: style.margin),
            banner.centerXAnchor.constraint(equalTo: guide.centerXAnchor),
            banner.leadingAnchor.constraint(greaterThanOrEqualTo: guide.leadingAnchor, constant: style.margin),
            banner.widthAnchor.constraint(lessThanOrEqualToConstant: style.maximumWidth),
            fullWidth,
        ])
        container.layoutIfNeeded()
        self.banner = banner

        guard animated else { return }
        hide(banner)
        UIView.animate(
            withDuration: 0.45,
            delay: 0,
            usingSpringWithDamping: 0.85,
            initialSpringVelocity: 0,
            options: [.beginFromCurrentState, .allowUserInteraction],
            animations: {
                banner.transform = .identity
                banner.alpha = 1
            }
        )
    }

    /// Puts the banner where it slides in from and back out to: above the
    /// top of the screen, or, with Reduce Motion, in place but unseen.
    private func hide(_ banner: MessageBanner) {
        if Self.reducesMotion() {
            banner.alpha = 0
        } else {
            banner.transform = CGAffineTransform(translationX: 0, y: -(banner.frame.maxY + style.shadowRadius * 2))
        }
    }
}

/// The window banners show in: it takes no touches but the banners', and
/// lets the rest through to the windows beneath.
final class MessageBannerWindow: UIWindow {

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard let view = super.hitTest(point, with: event), view !== self, view !== rootViewController?.view else {
            return nil
        }
        return view
    }
}

/// The banners' window's root: an empty view the banners go in, which
/// leaves the status bar and the orientation to the app's window.
final class MessageBannerViewController: UIViewController {

    /// The app's window, which the banners show over.
    weak var window: UIWindow?

    override func loadView() {
        let view = UIView()
        view.backgroundColor = .clear
        self.view = view
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        statusBarController(\.childForStatusBarStyle)?.preferredStatusBarStyle ?? .default
    }

    override var prefersStatusBarHidden: Bool {
        statusBarController(\.childForStatusBarHidden)?.prefersStatusBarHidden ?? false
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        frontController?.supportedInterfaceOrientations ?? .all
    }

    /// What the app's window shows in front: its root, or what that
    /// presents full screen.
    private var frontController: UIViewController? {
        var controller = window?.rootViewController
        while let presented = controller?.presentedViewController, !presented.isBeingDismissed,
              presented.modalPresentationStyle == .fullScreen || presented.modalPresentationCapturesStatusBarAppearance {
            controller = presented
        }
        return controller
    }

    /// The controller that decides the status bar in the app's window, as
    /// UIKit finds it, through the children each one names.
    private func statusBarController(_ child: KeyPath<UIViewController, UIViewController?>) -> UIViewController? {
        var controller = frontController
        while let next = controller?[keyPath: child] {
            controller = next
        }
        return controller
    }
}
#endif
