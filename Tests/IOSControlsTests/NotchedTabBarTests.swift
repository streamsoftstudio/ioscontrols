#if canImport(UIKit)
import UIKit
import XCTest
@testable import IOSControls

final class NotchedTabBarTests: XCTestCase {

    private var control: UIControl!

    private var bar: NotchedTabBar!

    override func setUp() {
        super.setUp()
        control = UIControl()
        bar = NotchedTabBar(
            items: ["One", "Two", "Three", "Four"].map { NotchedTabBar.Item(title: $0, image: nil) },
            control: control
        )
        bar.frame = CGRect(x: 0, y: 0, width: 390, height: 114)
        bar.layoutIfNeeded()
    }

    // MARK: - Layout

    func testTheItemsSplitAroundTheRaisedControl() {
        let centers = (0..<4).map { bar.itemView(at: $0).frame.midX }

        XCTAssertEqual(control.center, CGPoint(x: 195, y: 36))
        XCTAssertLessThan(centers[1], control.frame.minX)
        XCTAssertGreaterThan(centers[2], control.frame.maxX)
        XCTAssertEqual(centers[0] + centers[3], 390, accuracy: 0.5, "the sides mirror each other")
    }

    func testAnOddItemOutGoesBeforeTheControl() {
        let bar = NotchedTabBar(
            items: ["One", "Two", "Three"].map { NotchedTabBar.Item(title: $0, image: nil) },
            control: UIControl()
        )
        bar.frame = CGRect(x: 0, y: 0, width: 390, height: 114)
        bar.layoutIfNeeded()

        XCTAssertLessThan(bar.itemView(at: 1).frame.maxX, 195)
        XCTAssertGreaterThan(bar.itemView(at: 2).frame.minX, 195)
    }

    func testTheItemsSitBelowTheOverhangAtTheContentHeight() {
        let item = bar.itemView(at: 0)

        XCTAssertEqual(item.frame.minY, bar.style.overhang)
        XCTAssertEqual(item.frame.height, bar.style.contentHeight)
    }

    // MARK: - Selection

    func testTappingAnItemReportsItWithoutSelectingIt() {
        var tapped: [Int] = []
        bar.onSelect = { tapped.append($0) }

        bar.itemView(at: 2).tap()

        XCTAssertEqual(tapped, [2])
        XCTAssertEqual(bar.selectedIndex, 0, "the owner decides what is selected")
    }

    func testTheSelectedItemIsMarkedForAccessibility() {
        bar.selectedIndex = 1

        XCTAssertTrue(bar.itemView(at: 1).isSelected)
        XCTAssertTrue(bar.itemView(at: 1).accessibilityTraits.contains(.selected))
        XCTAssertFalse(bar.itemView(at: 0).accessibilityTraits.contains(.selected))
        XCTAssertEqual(bar.accessibilityTraits, .tabBar)
    }

    // MARK: - Touches

    func testTouchesBesideTheRaisedControlPassThrough() {
        XCTAssertTrue(bar.point(inside: CGPoint(x: 195, y: 2), with: nil), "the control itself")
        XCTAssertTrue(bar.point(inside: CGPoint(x: 60, y: 40), with: nil), "the bar")
        XCTAssertFalse(bar.point(inside: CGPoint(x: 60, y: 4), with: nil), "clear space above the bar")
    }

    // MARK: - Style

    func testAReplacedStyleMovesTheControlAndTheItems() {
        var style = bar.style
        style.controlDiameter = 60
        style.overhang = 20
        style.contentHeight = 80

        bar.style = style
        bar.layoutIfNeeded()

        XCTAssertEqual(control.bounds.size, CGSize(width: 60, height: 60))
        XCTAssertEqual(bar.itemView(at: 0).frame.minY, 20)
        XCTAssertEqual(bar.itemView(at: 0).frame.height, 80)
        XCTAssertEqual(style.heightAboveSafeArea, 100)
    }
}
#endif
