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

### Notched tab bar

`NotchedTabBarController` shows one view controller per tab above a
`NotchedTabBar`: a bar with a round control raised out of a notch in the
middle of its top edge. The items split around the control, half on each
side. It is a container of its own rather than a styled `UITabBarController`,
so the bar looks the same on every iOS version.

```swift
let tabs = NotchedTabBarController(
    tabs: [
        .init(item: .init(title: "Library", image: UIImage(systemName: "square.stack")), viewController: library),
        .init(item: .init(title: "Explore", image: UIImage(systemName: "magnifyingglass")), viewController: explore),
        .init(item: .init(title: "Sources", image: UIImage(systemName: "folder")), viewController: sources),
        .init(item: .init(title: "Settings", image: UIImage(systemName: "gearshape")), viewController: settings),
    ],
    control: playButton
)
```

Each tab's view controller is kept while another is shown, and leaves room
for the bar through its safe area. Choosing the tab already shown takes a
navigation controller back to its first screen.

### Progress ring button

`ProgressRingButton` is a round button ringed by progress, with an image
cropped to a circle inside the ring, and a placeholder while there is no
image. It suits the tab bar's raised control, for example to show what is
playing and how far it has got:

```swift
let button = ProgressRingButton()
button.placeholderImage = UIImage(systemName: "music.note")
button.image = cover
button.progress = 0.4
```

It is `open`, so an app can subclass it to bind its own state.

### Styling

Every control here takes a `Style` with its colours, fonts and measurements,
which can be replaced at any time:

```swift
var style = NotchedTabBar.Style()
style.backgroundColors = [.black, .darkGray]
style.selectedColor = .systemGreen
tabs.style = style
```

Colours may be dynamic (`UIColor { traits in … }`), and then follow the trait
collection. Drawing resolves them against the view's traits, so an app theme
carried by a custom trait recolours the controls when the trait changes.

## Contributing

UIKit-facing code is wrapped in `#if canImport(UIKit)` so the package still
builds and tests on macOS via SwiftPM. Keep platform-independent types out of
that guard where possible, so they remain unit-testable on macOS.

## License

See [LICENSE](LICENSE) for details.
