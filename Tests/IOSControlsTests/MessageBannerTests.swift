#if canImport(UIKit)
import UIKit
import XCTest
@testable import IOSControls

final class MessageBannerTests: XCTestCase {

    private let message = MessageBanner.Message(
        title: "Skipped “Borealis”",
        body: "Its drive or share isn't connected.",
        image: UIImage(systemName: "externaldrive.badge.xmark")
    )

    // MARK: - Content

    func testTheTitleTheBodyAndTheImageShow() {
        let banner = MessageBanner(message: message)

        XCTAssertEqual(banner.titleLabel.text, "Skipped “Borealis”")
        XCTAssertEqual(banner.bodyLabel.text, "Its drive or share isn't connected.")
        XCTAssertFalse(banner.bodyLabel.isHidden)
        XCTAssertNotNil(banner.imageView.image)
        XCTAssertFalse(banner.imageView.isHidden)
    }

    func testWithoutABodyOrAnImageOnlyTheTitleShows() {
        let banner = MessageBanner(message: MessageBanner.Message(title: "Copied"))

        XCTAssertTrue(banner.bodyLabel.isHidden)
        XCTAssertTrue(banner.imageView.isHidden)
    }

    func testANewMessageReplacesWhatTheBannerSays() {
        let banner = MessageBanner(message: message)

        banner.message = MessageBanner.Message(title: "Can't play “Dusk”", body: "Its file is missing.")

        XCTAssertEqual(banner.titleLabel.text, "Can't play “Dusk”")
        XCTAssertEqual(banner.bodyLabel.text, "Its file is missing.")
        XCTAssertTrue(banner.imageView.isHidden)
    }

    // MARK: - VoiceOver

    func testVoiceOverReadsTheTitleThenTheBodyAsOneElement() {
        let banner = MessageBanner(message: message)

        XCTAssertTrue(banner.isAccessibilityElement)
        XCTAssertEqual(banner.accessibilityLabel, "Skipped “Borealis”. Its drive or share isn't connected.")
    }

    func testATitleThatEndsASentenceIsNotGivenAnotherStop() {
        let message = MessageBanner.Message(title: "Can't play this album.", body: "Its files are missing.")

        XCTAssertEqual(message.spokenText, "Can't play this album. Its files are missing.")
        XCTAssertEqual(MessageBanner.Message(title: "Copied").spokenText, "Copied")
    }

    func testTheEscapeGestureAndTheDismissActionSendTheBannerAway() {
        let banner = MessageBanner(message: message)
        var dismissals = 0
        banner.onDismiss = { dismissals += 1 }

        XCTAssertTrue(banner.accessibilityPerformEscape())
        let dismiss = banner.accessibilityCustomActions?.first { $0.name == "Dismiss" }
        XCTAssertEqual(dismiss.flatMap { $0.actionHandler?($0) }, true)

        XCTAssertEqual(dismissals, 2)
    }

    func testATapOrASwipeUpIsWatchedFor() {
        let banner = MessageBanner(message: message)

        let recognizers = banner.gestureRecognizers ?? []
        XCTAssertTrue(recognizers.contains { $0 is UITapGestureRecognizer })
        XCTAssertTrue(recognizers.contains { ($0 as? UISwipeGestureRecognizer)?.direction == .up })
    }

    // MARK: - Style

    func testTheStyleColoursTheBanner() {
        var style = MessageBanner.Style()
        style.titleColor = .systemRed
        style.bodyColor = .systemGreen
        style.imageColor = .systemPurple
        let banner = MessageBanner(message: message, style: style)

        XCTAssertEqual(banner.titleLabel.textColor, .systemRed)
        XCTAssertEqual(banner.bodyLabel.textColor, .systemGreen)
        XCTAssertEqual(banner.imageView.tintColor, .systemPurple)

        style.titleColor = .systemBlue
        banner.style = style

        XCTAssertEqual(banner.titleLabel.textColor, .systemBlue)
    }

    func testTheFontsFollowDynamicType() {
        let banner = MessageBanner(message: message)

        XCTAssertTrue(banner.titleLabel.adjustsFontForContentSizeCategory)
        XCTAssertTrue(banner.bodyLabel.adjustsFontForContentSizeCategory)
        XCTAssertEqual(banner.titleLabel.numberOfLines, 0)
        XCTAssertEqual(banner.bodyLabel.numberOfLines, 0)
    }

    func testTheContentInsetsSetTheBannersSize() {
        var style = MessageBanner.Style()
        style.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 20, bottom: 30, trailing: 40)
        let banner = MessageBanner(message: MessageBanner.Message(title: "Copied"), style: style)

        let size = banner.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)

        let title = banner.titleLabel.intrinsicContentSize
        XCTAssertEqual(size.width, title.width + 60, accuracy: 1)
        XCTAssertEqual(size.height, title.height + 40, accuracy: 1)
    }
}
#endif
