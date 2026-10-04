#if canImport(UIKit)
import UIKit
import XCTest
@testable import IOSControls

final class NotchedTabBarControllerTests: XCTestCase {

    private var stacks: [UINavigationController]!

    private var controller: NotchedTabBarController!

    override func setUp() {
        super.setUp()
        stacks = (0..<4).map { _ in UINavigationController(rootViewController: UIViewController()) }
        controller = NotchedTabBarController(
            tabs: stacks.enumerated().map { index, stack in
                NotchedTabBarController.Tab(item: NotchedTabBar.Item(title: "Tab \(index)", image: nil), viewController: stack)
            },
            control: UIControl()
        )
        controller.loadViewIfNeeded()
    }

    func testTheFirstTabIsShownAtFirst() {
        XCTAssertEqual(controller.selectedIndex, 0)
        XCTAssertTrue(stacks[0].parent === controller)
        XCTAssertNil(stacks[1].parent)
    }

    func testSelectingATabShowsItInPlaceOfTheLast() {
        controller.select(2)

        XCTAssertEqual(controller.selectedIndex, 2)
        XCTAssertTrue(controller.selectedViewController === stacks[2])
        XCTAssertTrue(stacks[2].parent === controller)
        XCTAssertNil(stacks[0].parent)
        XCTAssertTrue(stacks[2].view.superview === controller.view)
    }

    func testTappingABarItemSelectsItsTab() {
        controller.tabBar.itemView(at: 3).tap()

        XCTAssertEqual(controller.selectedIndex, 3)
    }

    func testChoosingTheShownTabReturnsItToItsFirstScreen() {
        stacks[0].pushViewController(UIViewController(), animated: false)

        controller.select(0)

        XCTAssertEqual(stacks[0].viewControllers.count, 1)
    }

    func testTabsLeaveRoomForTheBar() {
        controller.select(1)

        XCTAssertEqual(stacks[0].additionalSafeAreaInsets.bottom, controller.style.contentHeight)
        XCTAssertEqual(stacks[1].additionalSafeAreaInsets.bottom, controller.style.contentHeight)
    }

    func testAReplacedStyleChangesTheRoomTabsLeave() {
        var style = controller.style
        style.contentHeight = 90

        controller.style = style

        XCTAssertEqual(stacks.map(\.additionalSafeAreaInsets.bottom), [90, 90, 90, 90])
    }
}
#endif
