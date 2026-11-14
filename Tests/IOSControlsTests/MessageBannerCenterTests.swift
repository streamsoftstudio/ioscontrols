#if canImport(UIKit)
import UIKit
import XCTest
@testable import IOSControls

final class MessageBannerCenterTests: XCTestCase {

    private var window: UIWindow!

    private var center: MessageBannerCenter!

    private var announcements: [String] = []

    private var voiceOverRunning = false

    private let announce = MessageBannerCenter.announce

    private let isVoiceOverRunning = MessageBannerCenter.isVoiceOverRunning

    private let reducesMotion = MessageBannerCenter.reducesMotion

    override func setUp() {
        super.setUp()
        // The app's window. Package tests give it the screen's scene.
        window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        window.rootViewController = UIViewController()
        window.makeKeyAndVisible()
        MessageBannerCenter.announce = { [weak self] text in self?.announcements.append(text) }
        MessageBannerCenter.isVoiceOverRunning = { [weak self] in self?.voiceOverRunning ?? false }
        MessageBannerCenter.reducesMotion = { false }
        center = MessageBannerCenter(window: window)
    }

    override func tearDown() {
        center.dismiss(animated: false)
        center.bannerWindow?.isHidden = true
        MessageBannerCenter.announce = announce
        MessageBannerCenter.isVoiceOverRunning = isVoiceOverRunning
        MessageBannerCenter.reducesMotion = reducesMotion
        window.isHidden = true
        window = nil
        super.tearDown()
    }

    // MARK: - Showing

    func testAMessageShowsInABannerAcrossTheTopOfAWindowOfItsOwn() throws {
        var prepared: [UIWindow] = []
        center.prepareWindow = { prepared.append($0) }

        center.show(MessageBanner.Message(title: "Skipped “Borealis”", body: "Its file is missing."), animated: false)

        let bannerWindow = try XCTUnwrap(center.bannerWindow)
        XCTAssertFalse(bannerWindow.isHidden)
        XCTAssertTrue(bannerWindow.windowScene === window.windowScene)
        XCTAssertEqual(bannerWindow.windowLevel, window.windowLevel + 1, "over the app's window")
        XCTAssertEqual(prepared, [bannerWindow])
        XCTAssertFalse(bannerWindow.isKeyWindow, "the app's window keeps the keyboard")

        let container = try XCTUnwrap(bannerWindow.rootViewController?.view)
        container.layoutIfNeeded()
        let banner = try XCTUnwrap(banners.first)
        XCTAssertEqual(banners.count, 1)
        XCTAssertEqual(banner.message.title, "Skipped “Borealis”")
        XCTAssertEqual(center.message?.body, "Its file is missing.")
        let safeArea = container.bounds.inset(by: container.safeAreaInsets)
        XCTAssertEqual(banner.frame.minY, safeArea.minY + 12)
        XCTAssertEqual(banner.frame.minX, safeArea.minX + 12)
        XCTAssertEqual(banner.frame.width, min(safeArea.width - 24, 520))
    }

    func testOnAWideScreenTheBannerKeepsToItsWidestCentred() throws {
        center.show(MessageBanner.Message(title: "Copied"), animated: false)
        let bannerWindow = try XCTUnwrap(center.bannerWindow)

        bannerWindow.frame = CGRect(x: 0, y: 0, width: 1024, height: 768)
        bannerWindow.layoutIfNeeded()

        let banner = try XCTUnwrap(banners.first)
        XCTAssertEqual(banner.frame.width, 520)
        XCTAssertEqual(banner.frame.midX, 512)
    }

    func testTheBannersWindowIsMadeOnceAndHiddenWhileNothingShows() throws {
        var prepared = 0
        center.prepareWindow = { _ in prepared += 1 }
        center.show(MessageBanner.Message(title: "Copied"), animated: false)
        let bannerWindow = try XCTUnwrap(center.bannerWindow)

        center.dismiss(animated: false)
        XCTAssertTrue(bannerWindow.isHidden)

        center.show(MessageBanner.Message(title: "Copied again"), animated: false)
        XCTAssertTrue(center.bannerWindow === bannerWindow)
        XCTAssertFalse(bannerWindow.isHidden)
        XCTAssertEqual(prepared, 1)
    }

    func testVoiceOverIsToldEachMessageAsItShows() {
        center.show(MessageBanner.Message(title: "Skipped “Borealis”", body: "Its file is missing."), animated: false)
        center.show(MessageBanner.Message(title: "Copied"), animated: false)

        XCTAssertEqual(announcements, ["Skipped “Borealis”. Its file is missing.", "Copied"])
    }

    func testANewMessageTakesThePlaceOfTheOneShowing() throws {
        center.show(MessageBanner.Message(title: "Skipped “Borealis”"), animated: false)

        center.show(MessageBanner.Message(title: "Can't play “Dusk”"), animated: false)

        XCTAssertEqual(banners.count, 1)
        XCTAssertEqual(try XCTUnwrap(banners.first).message.title, "Can't play “Dusk”")
        XCTAssertEqual(center.message?.title, "Can't play “Dusk”")
    }

    func testTheStyleReachesTheBanner() throws {
        var style = MessageBanner.Style()
        style.titleColor = .systemRed
        center.style = style

        center.show(MessageBanner.Message(title: "Copied"), animated: false)

        XCTAssertEqual(try XCTUnwrap(banners.first).titleLabel.textColor, .systemRed)
    }

    // MARK: - Going

    func testTheBannerGoesOnceItsTimeIsUp() {
        center.show(MessageBanner.Message(title: "Copied", duration: 0.05), animated: false)

        XCTAssertTrue(waitUntil { self.banners.isEmpty })
        XCTAssertNil(center.message)
    }

    func testWhileVoiceOverRunsTheBannerStaysTwiceAsLong() {
        voiceOverRunning = true

        center.show(MessageBanner.Message(title: "Copied", duration: 0.3), animated: false)

        XCTAssertFalse(waitUntil(timeout: 0.45) { self.banners.isEmpty }, "still up after its own duration")
        XCTAssertTrue(waitUntil { self.banners.isEmpty })
    }

    func testANewMessageStaysItsOwnFullTime() {
        center.show(MessageBanner.Message(title: "Skipped “Borealis”", duration: 0.2), animated: false)
        RunLoop.current.run(until: Date().addingTimeInterval(0.1))

        center.show(MessageBanner.Message(title: "Copied", duration: 0.4), animated: false)

        XCTAssertFalse(waitUntil(timeout: 0.25) { self.banners.isEmpty }, "the first message's time no longer counts")
        XCTAssertTrue(waitUntil { self.banners.isEmpty })
    }

    func testDismissingSendsTheBannerAwayAtOnce() {
        center.show(MessageBanner.Message(title: "Copied"), animated: false)

        center.dismiss(animated: false)

        XCTAssertTrue(banners.isEmpty)
        XCTAssertNil(center.message)
    }

    func testTheListenerSendingTheBannerAwayDismissesIt() throws {
        center.show(MessageBanner.Message(title: "Copied"), animated: false)

        _ = try XCTUnwrap(banners.first).accessibilityPerformEscape()

        XCTAssertTrue(waitUntil { self.banners.isEmpty })
        XCTAssertNil(center.message)
    }

    // MARK: - The banners' window

    func testTheBannersWindowTakesOnlyTheBannersTouches() {
        let bannerWindow = MessageBannerWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        bannerWindow.rootViewController = MessageBannerViewController()
        bannerWindow.isHidden = false
        let banner = MessageBanner(message: MessageBanner.Message(title: "Copied"))
        banner.frame = CGRect(x: 12, y: 60, width: 366, height: 60)
        bannerWindow.rootViewController?.view.addSubview(banner)

        XCTAssertNil(bannerWindow.hitTest(CGPoint(x: 200, y: 400), with: nil), "the screen beneath takes it")
        XCTAssertTrue(bannerWindow.hitTest(CGPoint(x: 200, y: 90), with: nil)?.isDescendant(of: banner) == true)
        bannerWindow.isHidden = true
    }

    func testTheBannersWindowLeavesTheStatusBarAndTheOrientationToTheAppsWindow() {
        let root = StatusBarController()
        window.rootViewController = root
        let controller = MessageBannerViewController()
        controller.window = window

        XCTAssertEqual(controller.preferredStatusBarStyle, .lightContent)
        XCTAssertTrue(controller.prefersStatusBarHidden)
        XCTAssertEqual(controller.supportedInterfaceOrientations, .portrait)
    }

    // MARK: - Helpers

    /// The banners showing: in the banners' own window, or else in the
    /// app's.
    private var banners: [MessageBanner] {
        let container = center.bannerWindow?.rootViewController?.view ?? window
        return (container?.subviews ?? []).compactMap { $0 as? MessageBanner }
    }

    private func waitUntil(timeout: TimeInterval = 2, _ condition: () -> Bool) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while !condition() && Date() < deadline {
            RunLoop.current.run(until: Date().addingTimeInterval(0.01))
        }
        return condition()
    }
}

private final class StatusBarController: UIViewController {

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    override var prefersStatusBarHidden: Bool { true }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .portrait }
}
#endif
