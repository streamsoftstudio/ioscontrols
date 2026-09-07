//
//  Reusable.swift
//  IOSControls
//
//  Created by Andrija Milovanovic on 7.9.2026.
//

import Foundation

/// A view that can be registered and dequeued by a type-safe identifier.
///
/// The identifier defaults to the type's own name, so conforming types
/// usually need no implementation of their own:
///
/// ```swift
/// final class TrackCell: UITableViewCell, Reusable {}
/// ```
public protocol Reusable: AnyObject {
    /// Identifier used when registering and dequeuing. Defaults to the type name.
    static var reuseIdentifier: String { get }
}

public extension Reusable {
    static var reuseIdentifier: String { String(describing: self) }
}
