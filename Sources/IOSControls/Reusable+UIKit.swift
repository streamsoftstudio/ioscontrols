//
//  Reusable+UIKit.swift
//  IOSControls
//
//  Created by Andrija Milovanovic on 7.9.2026.
//

#if canImport(UIKit)
import UIKit

/// A `Reusable` view laid out in a nib whose file name matches the type name.
public protocol NibLoadable: Reusable {
    /// The nib the view is loaded from. Defaults to a nib named after the type,
    /// resolved from the bundle the type is compiled into.
    static var nib: UINib { get }
}

public extension NibLoadable {
    static var nib: UINib {
        UINib(nibName: String(describing: self), bundle: Bundle(for: self))
    }
}

// MARK: - UITableView

public extension UITableView {
    /// Registers a cell class under its own `reuseIdentifier`.
    func register<T: UITableViewCell & Reusable>(_ type: T.Type) {
        register(type, forCellReuseIdentifier: type.reuseIdentifier)
    }

    /// Registers a nib-backed cell under its own `reuseIdentifier`.
    func registerNib<T: UITableViewCell & NibLoadable>(_ type: T.Type) {
        register(type.nib, forCellReuseIdentifier: type.reuseIdentifier)
    }

    /// Dequeues a cell of the given type, trapping if it was never registered.
    func dequeue<T: UITableViewCell & Reusable>(_ type: T.Type, for indexPath: IndexPath) -> T {
        guard let cell = dequeueReusableCell(withIdentifier: type.reuseIdentifier, for: indexPath) as? T else {
            fatalError("Dequeued cell for \(type.reuseIdentifier) is not a \(type). Register it first.")
        }
        return cell
    }
}

// MARK: - UICollectionView

public extension UICollectionView {
    /// Registers a cell class under its own `reuseIdentifier`.
    func register<T: UICollectionViewCell & Reusable>(_ type: T.Type) {
        register(type, forCellWithReuseIdentifier: type.reuseIdentifier)
    }

    /// Registers a nib-backed cell under its own `reuseIdentifier`.
    func registerNib<T: UICollectionViewCell & NibLoadable>(_ type: T.Type) {
        register(type.nib, forCellWithReuseIdentifier: type.reuseIdentifier)
    }

    /// Dequeues a cell of the given type, trapping if it was never registered.
    func dequeue<T: UICollectionViewCell & Reusable>(_ type: T.Type, for indexPath: IndexPath) -> T {
        guard let cell = dequeueReusableCell(withReuseIdentifier: type.reuseIdentifier, for: indexPath) as? T else {
            fatalError("Dequeued cell for \(type.reuseIdentifier) is not a \(type). Register it first.")
        }
        return cell
    }
}
#endif
