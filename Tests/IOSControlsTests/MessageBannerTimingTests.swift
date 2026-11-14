import XCTest
@testable import IOSControls

final class MessageBannerTimingTests: XCTestCase {

    func testAShortMessageStaysTheLeastTime() {
        XCTAssertEqual(MessageBannerTiming.duration(forText: "Copied", voiceOverRunning: false), 4)
    }

    func testALongerMessageStaysLongEnoughToReadEachWord() {
        // Twelve words: a second and a half to notice it, then 0.3 s a word.
        let text = "Skipped “Borealis” and 11 more. Their drive or share isn't connected now."

        XCTAssertEqual(MessageBannerTiming.duration(forText: text, voiceOverRunning: false), 1.5 + 12 * 0.3, accuracy: 0.0001)
    }

    func testAVeryLongMessageStaysNoLongerThanTheMost() {
        let text = Array(repeating: "word", count: 100).joined(separator: " ")

        XCTAssertEqual(MessageBannerTiming.duration(forText: text, voiceOverRunning: false), 10)
    }

    func testWhileVoiceOverRunsAMessageStaysTwiceAsLong() {
        XCTAssertEqual(MessageBannerTiming.duration(forText: "Copied", voiceOverRunning: true), 8)
    }
}
