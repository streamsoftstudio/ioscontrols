# iOS controls

[![CI](https://github.com/streamsoftstudio/ioscontrols/actions/workflows/ci.yml/badge.svg)](https://github.com/streamsoftstudio/ioscontrols/actions/workflows/ci.yml)
[![Swift Package Manager compatible](https://img.shields.io/badge/SPM-compatible-4BC51D.svg?style=flat)](https://github.com/apple/swift-package-manager)

Reusable UIKit controls, cells and view helpers we use across our iOS projects.

Anything here is deliberately project-agnostic. It is the counterpart to
[iosextensions](https://github.com/streamsoftstudio/iosextensions), which holds
Foundation and UIKit *extensions*; this package holds UI *implementations*.

## Requirements

- iOS 13.0+
- Swift 5.9+

## Installation

### Swift Package Manager

Add the package to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/streamsoftstudio/ioscontrols.git", from: "0.1.0")
]
```

Or in Xcode: **File ▸ Add Package Dependencies…** and enter the repository URL.

## Usage

```swift
import IOSControls
```

### Reusable cells

Conform a cell to `Reusable` and its reuse identifier becomes its type name,
so the string never has to be written twice:

```swift
final class TrackCell: UITableViewCell, Reusable {}

tableView.register(TrackCell.self)

let cell = tableView.dequeue(TrackCell.self, for: indexPath)
```

Override the identifier when it has to match something existing:

```swift
final class LegacyCell: UITableViewCell, Reusable {
    static var reuseIdentifier: String { "OldCellIdentifier" }
}
```

### Nib-backed cells

Conform to `NibLoadable` when the cell is laid out in a nib named after the
type. The nib is resolved from the bundle the type is compiled into, so it
works from an app target or from another package:

```swift
final class AlbumCell: UICollectionViewCell, NibLoadable {}

collectionView.registerNib(AlbumCell.self)

let cell = collectionView.dequeue(AlbumCell.self, for: indexPath)
```

Both `UITableView` and `UICollectionView` are supported.

## Contributing

UIKit-facing code is wrapped in `#if canImport(UIKit)` so the package still
builds and tests on macOS via SwiftPM. Keep platform-independent types out of
that guard where possible, so they remain unit-testable on macOS.

## License

See [LICENSE](LICENSE) for details.
