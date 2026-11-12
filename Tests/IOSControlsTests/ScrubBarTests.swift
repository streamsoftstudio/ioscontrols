#if canImport(UIKit)
import UIKit
import XCTest
@testable import IOSControls

final class ScrubBarTests: XCTestCase {

    private var bar: ScrubBar!

    override func setUp() {
        super.setUp()
        ScrubBar.reducesMotion = { true }
        bar = ScrubBar()
        bar.frame = CGRect(x: 0, y: 0, width: 300, height: 44)
        bar.layoutIfNeeded()
    }

    override func tearDown() {
        ScrubBar.reducesMotion = { UIAccessibility.isReduceMotionEnabled }
        super.tearDown()
    }

    func testValuesOutsideTheRangeAreClamped() {
        bar.value = 1.4
        XCTAssertEqual(bar.value, 1)

        bar.value = -0.2
        XCTAssertEqual(bar.value, 0)

        bar.value = .nan
        XCTAssertEqual(bar.value, 0)
    }

    func testADragFollowsTheFingerButChangesTheValueOnlyWhenItEnds() {
        bar.value = 0.2

        bar.beginScrubbing(at: 150)
        XCTAssertTrue(bar.isScrubbing)
        XCTAssertEqual(bar.scrubValue, 0.5)
        XCTAssertEqual(bar.value, 0.2)

        bar.moveScrubbing(to: 240)
        XCTAssertEqual(bar.scrubValue, 0.8)
        XCTAssertEqual(bar.displayedValue, 0.8)
        XCTAssertEqual(bar.value, 0.2)

        bar.endScrubbing()
        XCTAssertFalse(bar.isScrubbing)
        XCTAssertEqual(bar.value, 0.8)
        XCTAssertEqual(bar.displayedValue, 0.8)
    }

    func testACancelledDragKeepsTheValue() {
        bar.value = 0.3
        bar.beginScrubbing(at: 270)

        bar.cancelScrubbing()

        XCTAssertFalse(bar.isScrubbing)
        XCTAssertEqual(bar.value, 0.3)
        XCTAssertEqual(bar.displayedValue, 0.3)
    }

    func testTheGesturesAroundTheBarCannotTakeOverItsDrag() {
        // As a sheet's swipe to dismiss, on the view the bar sits in.
        let sheet = UIView(frame: CGRect(x: 0, y: 0, width: 300, height: 600))
        sheet.addSubview(bar)
        let dismiss = UIPanGestureRecognizer()
        sheet.addGestureRecognizer(dismiss)
        let own = UIPanGestureRecognizer()
        bar.addGestureRecognizer(own)

        XCTAssertFalse(bar.gestureRecognizerShouldBegin(dismiss), "a drag that strays off the line goes on scrubbing")
        XCTAssertTrue(bar.gestureRecognizerShouldBegin(own), "the bar's own gestures still begin")
    }

    func testTheValueCanChangeUnderTheFingerWithoutMovingTheBar() {
        bar.beginScrubbing(at: 60)

        // Playback carries on while the finger is down.
        bar.value = 0.9

        XCTAssertEqual(bar.displayedValue, 0.2)
    }

    func testAFingerBeyondTheEndsCountsAsTheEnds() {
        bar.beginScrubbing(at: -40)
        XCTAssertEqual(bar.scrubValue, 0)

        bar.moveScrubbing(to: 420)
        XCTAssertEqual(bar.scrubValue, 1)
    }

    func testTheBarThickensWhileScrubbing() {
        XCTAssertEqual(bar.barFrame.height, 6)

        bar.beginScrubbing(at: 10)
        XCTAssertEqual(bar.barFrame.height, 10)
        XCTAssertEqual(bar.barFrame.midY, 22)

        bar.endScrubbing()
        XCTAssertEqual(bar.barFrame.height, 6)
    }

    func testItIsTallEnoughToLandAFingerOn() {
        XCTAssertEqual(bar.intrinsicContentSize.height, 44)
    }

    func testVoiceOverAdjustsTheValueByTheStep() {
        bar.accessibilityStep = 0.1
        bar.value = 0.5

        bar.accessibilityIncrement()
        XCTAssertEqual(bar.value, 0.6, accuracy: 1e-9)

        bar.accessibilityDecrement()
        bar.accessibilityDecrement()
        XCTAssertEqual(bar.value, 0.4, accuracy: 1e-9)
        XCTAssertTrue(bar.accessibilityTraits.contains(.adjustable))
    }

    func testVoiceOverReadsTheFormattedValue() {
        bar.value = 0.25
        XCTAssertEqual(bar.accessibilityValue, "25 percent")

        bar.accessibilityValueFormatter = { "\(Int($0 * 100)) of 100" }
        XCTAssertEqual(bar.accessibilityValue, "25 of 100")
    }
}
#endif
