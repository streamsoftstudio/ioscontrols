import XCTest
@testable import IOSControls

private final class PlainCell: Reusable {}

private final class OverridingCell: Reusable {
    static var reuseIdentifier: String { "custom-identifier" }
}

final class ReusableTests: XCTestCase {

    func testDefaultReuseIdentifierIsTypeName() {
        XCTAssertEqual(PlainCell.reuseIdentifier, "PlainCell")
    }

    func testReuseIdentifierCanBeOverridden() {
        XCTAssertEqual(OverridingCell.reuseIdentifier, "custom-identifier")
    }
}
