#if canImport(UIKit)
import UIKit
import XCTest
@testable import IOSControls

final class DrawerControllerTests: XCTestCase {

    private var menu: UIViewController!

    private var content: UIViewController!

    private var drawer: DrawerController!

    private var window: UIWindow!

    override func setUp() {
        super.setUp()
        menu = UIViewController()
        content = UIViewController()
        drawer = DrawerController(menu: menu, content: content)
        window = UIWindow(frame: CGRect(x: 0, y: 0, width: 393, height: 852))
        window.rootViewController = drawer
        window.makeKeyAndVisible()
        drawer.view.layoutIfNeeded()
    }

    override func tearDown() {
        window.isHidden = true
        window = nil
        super.tearDown()
    }

    func testItStartsClosedWithBothInPlace() {
        XCTAssertFalse(drawer.isOpen)
        XCTAssertTrue(menu.parent === drawer)
        XCTAssertTrue(content.parent === drawer)
        XCTAssertTrue(drawer.menuContainer.isHidden)
        XCTAssertTrue(drawer.dimming.isHidden)
    }

    func testOpeningAndClosingReportTheState() {
        var reported: [Bool] = []
        drawer.openStateChanged = { reported.append($0) }

        drawer.open(animated: false)
        XCTAssertTrue(drawer.isOpen)
        XCTAssertFalse(drawer.menuContainer.isHidden)
        XCTAssertEqual(drawer.dimming.alpha, 1)

        drawer.open(animated: false)
        drawer.close(animated: false)
        XCTAssertFalse(drawer.isOpen)
        XCTAssertEqual(reported, [true, false], "opening twice reports once")
    }

    func testTheMenuIsAsWideAsAskedWhereThereIsRoom() {
        drawer.menuWidth = 280
        drawer.open(animated: false)
        drawer.view.layoutIfNeeded()

        XCTAssertEqual(drawer.menuContainer.frame.width, 280)
        XCTAssertEqual(drawer.menuContainer.frame.minX, 0)
    }

    func testOnANarrowScreenTheMenuLeavesTheContentInView() {
        drawer.menuWidth = 500
        drawer.view.layoutIfNeeded()

        XCTAssertEqual(drawer.menuContainer.frame.width, 393 - 56)
    }

    func testWhileOpenVoiceOverKeepsToTheMenu() {
        drawer.open(animated: false)

        XCTAssertTrue(drawer.menuContainer.accessibilityViewIsModal)

        drawer.close(animated: false)

        XCTAssertFalse(drawer.menuContainer.accessibilityViewIsModal)
    }

    func testTheEscapeGestureClosesAnOpenMenu() {
        XCTAssertFalse(drawer.accessibilityPerformEscape(), "nothing to close")

        drawer.open(animated: false)

        XCTAssertTrue(drawer.accessibilityPerformEscape())
        XCTAssertFalse(drawer.isOpen)
    }

    func testTappingTheDimmedContentCloses() {
        drawer.open(animated: false)

        _ = drawer.dimming.accessibilityActivate()

        XCTAssertFalse(drawer.isOpen)
    }

    func testReplacingTheContentSwapsTheChild() {
        let next = UIViewController()

        drawer.setContent(next)

        XCTAssertTrue(drawer.content === next)
        XCTAssertTrue(next.parent === drawer)
        XCTAssertNil(content.parent)
    }

    func testTheEdgeSwipeOpensFromAStacksFirstScreenOnly() {
        let first = UIViewController()
        let navigation = UINavigationController(rootViewController: first)
        drawer.setContent(navigation)

        XCTAssertTrue(drawer.gestureRecognizerShouldBegin(drawer.edgePan))

        navigation.pushViewController(UIViewController(), animated: false)

        XCTAssertFalse(drawer.gestureRecognizerShouldBegin(drawer.edgePan), "the swipe goes back instead")

        drawer.opensWithEdgeSwipe = false
        navigation.popViewController(animated: false)

        XCTAssertFalse(drawer.gestureRecognizerShouldBegin(drawer.edgePan))
    }

    // MARK: Docking

    func testWithoutADockingWidthTheMenuNeverDocks() {
        resize(to: CGSize(width: 1366, height: 1024))

        XCTAssertFalse(drawer.isDocked)
        XCTAssertTrue(drawer.menuContainer.isHidden)
        XCTAssertEqual(frame(of: content), CGRect(x: 0, y: 0, width: 1366, height: 1024))
    }

    func testWhereThereIsRoomTheMenuDocksBesideTheContent() {
        drawer.dockingMinimumWidth = 1100

        resize(to: CGSize(width: 1366, height: 1024))

        XCTAssertTrue(drawer.isDocked)
        XCTAssertFalse(drawer.isOpen)
        XCTAssertFalse(drawer.menuContainer.isHidden)
        XCTAssertEqual(drawer.menuContainer.frame, CGRect(x: 0, y: 0, width: 300, height: 1024))
        XCTAssertTrue(drawer.dimming.isHidden)
        XCTAssertFalse(drawer.separator.isHidden)
    }

    /// UIKit gives a view the system's minimum margins only on the sides at
    /// the window's edges, so the content runs on under the menu, and keeps
    /// beside it within its safe area.
    func testDockedContentSitsBesideTheMenuWithTheSystemsMargins() {
        drawer.dockingMinimumWidth = 1100

        resize(to: CGSize(width: 1366, height: 1024))
        content.view.layoutIfNeeded()

        XCTAssertEqual(frame(of: content), CGRect(x: 0, y: 0, width: 1366, height: 1024))
        XCTAssertEqual(content.view.safeAreaInsets.left, 300)
        XCTAssertGreaterThan(content.systemMinimumLayoutMargins.leading, 0)
        XCTAssertEqual(content.view.layoutMargins.left, 300 + content.systemMinimumLayoutMargins.leading)
    }

    func testDockedContentKeepsTheSafeAreaItAddsItself() {
        drawer.dockingMinimumWidth = 1100
        content.additionalSafeAreaInsets = UIEdgeInsets(top: 0, left: 7, bottom: 5, right: 0)

        resize(to: CGSize(width: 1366, height: 1024))

        XCTAssertEqual(content.additionalSafeAreaInsets, UIEdgeInsets(top: 0, left: 307, bottom: 5, right: 0))

        resize(to: CGSize(width: 1024, height: 1366))

        XCTAssertEqual(content.additionalSafeAreaInsets, UIEdgeInsets(top: 0, left: 7, bottom: 5, right: 0))
    }

    func testContentPutInPlaceWhileDockedSitsBesideTheMenuToo() {
        drawer.dockingMinimumWidth = 1100
        resize(to: CGSize(width: 1366, height: 1024))
        let next = UIViewController()

        drawer.setContent(next)

        XCTAssertEqual(next.additionalSafeAreaInsets.left, 300)
        XCTAssertEqual(content.additionalSafeAreaInsets.left, 0, "the content it replaced is as it was")
    }

    func testBelowTheDockingWidthTheMenuStillSlidesOver() {
        drawer.dockingMinimumWidth = 1100

        resize(to: CGSize(width: 1024, height: 1366))

        XCTAssertFalse(drawer.isDocked)
        XCTAssertTrue(drawer.menuContainer.isHidden)
        XCTAssertTrue(drawer.separator.isHidden)
        XCTAssertEqual(frame(of: content), CGRect(x: 0, y: 0, width: 1024, height: 1366))
        XCTAssertEqual(content.additionalSafeAreaInsets, .zero)

        drawer.open(animated: false)

        XCTAssertTrue(drawer.isOpen)
    }

    func testCrossingTheDockingWidthReportsItAndLeavesTheMenuClosed() {
        drawer.dockingMinimumWidth = 1100
        var docked: [Bool] = []
        var opened: [Bool] = []
        drawer.dockStateChanged = { docked.append($0) }
        drawer.openStateChanged = { opened.append($0) }
        resize(to: CGSize(width: 1024, height: 1366))
        drawer.open(animated: false)

        resize(to: CGSize(width: 1366, height: 1024))

        XCTAssertTrue(drawer.isDocked)
        XCTAssertFalse(drawer.isOpen, "an open menu closes as it docks")

        resize(to: CGSize(width: 1024, height: 1366))

        XCTAssertFalse(drawer.isDocked)
        XCTAssertFalse(drawer.isOpen)
        XCTAssertTrue(drawer.menuContainer.isHidden)
        XCTAssertEqual(frame(of: content), CGRect(x: 0, y: 0, width: 1024, height: 1366))
        XCTAssertEqual(content.additionalSafeAreaInsets, .zero, "the docked menu's inset goes")
        XCTAssertEqual(docked, [true, false])
        XCTAssertEqual(opened, [true, false])
    }

    func testADockedMenuHasNothingToOpenOrClose() {
        drawer.dockingMinimumWidth = 1100
        resize(to: CGSize(width: 1366, height: 1024))

        drawer.open(animated: false)
        drawer.toggle(animated: false)

        XCTAssertFalse(drawer.isOpen)
        XCTAssertFalse(drawer.menuContainer.accessibilityViewIsModal, "VoiceOver reads the content too")
        XCTAssertFalse(drawer.accessibilityPerformEscape())
        XCTAssertFalse(drawer.gestureRecognizerShouldBegin(drawer.edgePan))
        XCTAssertFalse(drawer.gestureRecognizerShouldBegin(drawer.closePan))
    }

    func testRightToLeftTheDockedMenuIsOnTheRight() {
        drawer.dockingMinimumWidth = 1100
        drawer.view.semanticContentAttribute = .forceRightToLeft

        resize(to: CGSize(width: 1366, height: 1024))

        XCTAssertEqual(drawer.menuContainer.frame, CGRect(x: 1066, y: 0, width: 300, height: 1024))
        XCTAssertEqual(content.additionalSafeAreaInsets, UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 300))
    }

    // MARK: Helpers

    /// Resizes the window, as turning an iPad or resizing its window does.
    private func resize(to size: CGSize) {
        window.frame = CGRect(origin: .zero, size: size)
        window.layoutIfNeeded()
        drawer.view.layoutIfNeeded()
    }

    /// Where `controller`'s view sits in the drawer.
    private func frame(of controller: UIViewController) -> CGRect {
        controller.view.convert(controller.view.bounds, to: drawer.view)
    }
}
#endif
