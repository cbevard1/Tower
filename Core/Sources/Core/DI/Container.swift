import Foundation
import Dispatch

/// Dependency injection container protocol.
///
/// This protocol defines the interface for registering and resolving
/// service instances used throughout the Tower application.
/// Concrete implementations live in TowerApp (Task 1.10).
public protocol DIContainer: Sendable {
    /// Register a factory closure for a given type.
    /// - Parameters:
    ///   - type: The type to register.
    ///   - factory: A closure that creates an instance of the type,
    ///              receiving the container for dependency resolution.
    func register<T>(
        _ type: T.Type,
        factory: @escaping @Sendable (DIContainer) -> T
    )

    /// Resolve a previously-registered instance for the given type.
    /// - Parameter type: The type to resolve.
    /// - Returns: An instance if registered, `nil` otherwise.
    func resolve<T>(_ type: T.Type) -> T?
}

extension DIContainer {
    /// Resolve a previously-registered instance, throwing if not found.
    public func resolveOrFail<T>(_ type: T.Type) throws -> T {
        guard let instance: T = resolve(type) else {
            throw DIError.unregisteredType(String(describing: T.self))
        }
        return instance
    }
}

/// Errors thrown by the DI container.
public enum DIError: Error, Sendable {
    /// A requested type was not registered in the container.
    case unregisteredType(String)
}

/// Default `DIContainer` implementation backed by a dictionary of factories.
///
/// Registration and resolution are keyed by the Swift type name.
/// Thread-safety is provided via a serial `DispatchQueue` lock.
///
/// Note: `@unchecked Sendable` is used because the internal dictionary
/// is protected by `lockQueue`, but the compiler cannot verify this.
/// A future iteration may migrate to an actor-based implementation.
public final class DefaultContainer: DIContainer, @unchecked Sendable {
    private let lockQueue = DispatchQueue(label: "tower.di-container")
    // Keys the type name; values are factory closures cast to Any.
    private var factories: [String: @Sendable (DIContainer) -> Any] = [:]

    public init() {}

    public func register<T>(
        _ type: T.Type,
        factory: @escaping @Sendable (DIContainer) -> T
    ) {
        let key = String(describing: T.self)
        lockQueue.sync {
            factories[key] = { container in
                factory(container)
            }
        }
    }

    public func resolve<T>(_ type: T.Type) -> T? {
        let key = String(describing: T.self)
        return lockQueue.sync {
            guard let factory = factories[key] else {
                return nil as T?
            }
            return factory(self) as? T
        }
    }
}
