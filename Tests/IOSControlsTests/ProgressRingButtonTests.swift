#if canImport(UIKit)
import UIKit
import XCTest
@testable import IOSControls

final class ProgressRingButtonTests: XCTestCase {

    private var button: ProgressRingButton!

    override func setUp() {
        super.setUp()
        button = ProgressRingButton()
        button.frame = CGRect(x: 0, y: 0, width: 72, height: 72)
        button.placeholderImage = UIImage(systemName: "music.note")
        button.layoutIfNeeded()
    }

    func testThePlaceholderShowsUntilThereIsAnImage() {
        XCTAssertFalse(placeholderView.isHidden)
        XCTAssertTrue(imageView.isHidden)

        button.image = UIImage(systemName: "star.fill")

        XCTAssertTrue(placeholderView.isHidden)
        XCTAssertFalse(imageView.isHidden)
    }

    func testTheImageIsCroppedToACircleInsideTheRing() {
        button.layoutIfNeeded()

        XCTAssertEqual(imageView.frame, CGRect(x: 11, y: 11, width: 50, height: 50))
        XCTAssertEqual(imageView.layer.cornerRadius, 25)
    }

    func testDimmingHalvesTheContentButKeepsTheButtonEnabled() {
        button.isDimmed = true

        XCTAssertEqual(placeholderView.alpha, 0.5)
        XCTAssertTrue(button.isEnabled)
    }

    func testTheAccessibilityLabelNamesTheLargeContentToo() {
        button.accessibilityLabel = "Now Playing"

        XCTAssertEqual(button.largeContentTitle, "Now Playing")
        XCTAssertTrue(button.accessibilityTraits.contains(.button))
    }

    func testAReplacedStyleMovesTheImage() {
        button.image = UIImage(systemName: "star.fill")
        var style = button.style
        style.imageInset = 6

        button.style = style
        button.layoutIfNeeded()

        XCTAssertEqual(imageView.frame.width, 60)
    }

    // MARK: - Helpers

    private var imageView: UIImageView {
        button.subviews.compactMap { $0 as? UIImageView }[0]
    }

    private var placeholderView: UIImageView {
        button.subviews.compactMap { $0 as? UIImageView }[1]
    }
}
#endif
