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
}
#endif
