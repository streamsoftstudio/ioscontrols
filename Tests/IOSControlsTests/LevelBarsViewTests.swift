#if canImport(UIKit)
import UIKit
import XCTest
@testable import IOSControls

final class LevelBarsViewTests: XCTestCase {

    private var bars: LevelBarsView!

    override func setUp() {
        super.setUp()
        LevelBarsView.reducesMotion = { false }
        bars = LevelBarsView()
        bars.frame = CGRect(x: 0, y: 0, width: 21, height: 20)
        bars.layoutIfNeeded()
    }

    override func tearDown() {
        LevelBarsView.reducesMotion = { UIAccessibility.isReduceMotionEnabled }
        super.tearDown()
    }

    // MARK: - Levels

    func testALouderLevelShowsAtOnce() {
        bars.setLevels([0.5, 1, 0.25])

        XCTAssertEqual(bars.heights, [0.5, 1, 0.25])
    }

    func testAQuieterLevelFallsPartOfTheWay() {
        bars.setLevels([1, 1, 1])

        bars.setLevels([0, 0.5, 1])

        XCTAssertEqual(bars.heights[0], 0.65, accuracy: 0.0001)
        XCTAssertEqual(bars.heights[1], 0.825, accuracy: 0.0001)
        XCTAssertEqual(bars.heights[2], 1)
    }

    func testMissingAndOutOfRangeLevelsAreSilenceAndFullScale() {
        bars.setLevels([2])

        XCTAssertEqual(bars.heights, [1, 0, 0])
    }

    func testResetDropsEveryBarAtOnce() {
        bars.setLevels([1, 1, 1])

        bars.reset()

        XCTAssertEqual(bars.heights, [0, 0, 0])
    }

    // MARK: - Layout

    func testTheBarsStandOnTheBottomEdgeSideBySide() {
        bars.setLevels([0.5, 1, 0.25])
        bars.layoutIfNeeded()

        XCTAssertEqual(barFrames, [
            CGRect(x: 4, y: 10, width: 3, height: 10),
            CGRect(x: 9, y: 0, width: 3, height: 20),
            CGRect(x: 14, y: 15, width: 3, height: 5),
        ])
    }

    func testSilentBarsKeepTheirMinimumHeight() {
        bars.layoutIfNeeded()

        XCTAssertEqual(barFrames.map(\.height), [4, 4, 4])
    }

    func testTheWidthFollowsTheStyle() {
        XCTAssertEqual(bars.intrinsicContentSize.width, 13)

        bars.style.barCount = 5
        bars.style.barWidth = 2

        XCTAssertEqual(bars.intrinsicContentSize.width, 18)
        XCTAssertEqual(bars.layer.sublayers?.count, 5)
        XCTAssertEqual(bars.heights.count, 5)
    }

    func testTheColourComesFromTheStyle() {
        bars.style.color = .systemGreen
        bars.layoutIfNeeded()

        XCTAssertEqual(bars.layer.sublayers?.first?.backgroundColor, UIColor.systemGreen.resolvedColor(with: bars.traitCollection).cgColor)
    }

    func testReduceMotionShowsAStillPattern() {
        LevelBarsView.reducesMotion = { true }

        bars.setLevels([0, 0, 0])
        bars.layoutIfNeeded()

        XCTAssertEqual(barFrames.map(\.height), LevelBarsView.stillHeights.map { $0 * 20 })
    }

    // MARK: - Helpers

    private var barFrames: [CGRect] {
        bars.layer.sublayers?.map(\.frame) ?? []
    }
}
#endif
