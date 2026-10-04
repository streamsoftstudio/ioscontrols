import CoreGraphics
import XCTest
@testable import IOSControls

final class NotchedTabBarShapeTests: XCTestCase {

    /// A 390-point bar whose 72-point control rises 12 points above its top
    /// edge, as on an iPhone.
    private let rect = CGRect(x: 0, y: 0, width: 390, height: 114)

    private let shape = NotchedTabBarShape(
        top: 12,
        controlCenter: CGPoint(x: 195, y: 36),
        controlRadius: 36,
        gap: 5,
        filletRadius: 10,
        cornerRadius: 22
    )

    func testTheBarFillsBelowItsTopEdgeOnEitherSide() {
        let path = shape.path(in: rect)

        XCTAssertTrue(path.contains(CGPoint(x: 60, y: 30)))
        XCTAssertTrue(path.contains(CGPoint(x: 330, y: 30)))
        XCTAssertTrue(path.contains(CGPoint(x: 195, y: 110)), "beneath the notch the bar is whole")
    }

    func testNothingIsFilledAboveTheTopEdge() {
        let path = shape.path(in: rect)

        XCTAssertFalse(path.contains(CGPoint(x: 60, y: 11)))
        XCTAssertFalse(path.contains(CGPoint(x: 330, y: 11)))
    }

    func testTheNotchLeavesRoomAroundTheControl() {
        let path = shape.path(in: rect)

        XCTAssertFalse(path.contains(shape.controlCenter))
        // Just outside the control, inside the gap.
        XCTAssertFalse(path.contains(CGPoint(x: 195, y: 36 + 36 + 3)))
        // Beyond the gap, the bar again.
        XCTAssertTrue(path.contains(CGPoint(x: 195, y: 36 + 41 + 2)))
    }

    func testTheTopCornersAreRounded() {
        let path = shape.path(in: rect)

        XCTAssertFalse(path.contains(CGPoint(x: 1, y: 13)))
        XCTAssertFalse(path.contains(CGPoint(x: 389, y: 13)))
        XCTAssertTrue(path.contains(CGPoint(x: 1, y: 40)))
    }

    func testTheNotchOpensWiderThanTheControlByItsRounding() {
        // The fillets meet the top edge beyond the control's radius plus the
        // gap.
        XCTAssertGreaterThan(shape.notchHalfWidth, shape.notchRadius)
        XCTAssertLessThan(shape.notchHalfWidth, shape.notchRadius + shape.filletRadius)
    }

    func testAControlAboveTheBarCutsNoNotch() {
        var floating = shape
        floating.controlCenter.y = floating.top - floating.notchRadius - 1

        let path = floating.path(in: rect)

        XCTAssertEqual(floating.notchHalfWidth, 0)
        XCTAssertTrue(path.contains(CGPoint(x: 195, y: 14)))
    }
}
