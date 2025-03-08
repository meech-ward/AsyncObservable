import Foundation
import Dispatch

/// A protocol representing the read-only interface of an `AsyncObservable`.
/// This allows for providing read-only access to an observable state without
/// exposing methods that can modify the state.
@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
public protocol AsyncObservableReadOnly<T>: Sendable {
    /// The type of value being observed.
    associatedtype T: Sendable

    /// The current value accessible from the MainActor.
    /// This is a convenience property that provides direct access to the observable value.
    @MainActor
    var observable: T { get }

    /// An async stream of values that can be used with Swift concurrency.
    /// This property provides a convenient way to access the value stream.
    var stream: StreamOf<T> { get }

    /// The current value managed by this instance.
    var raw: T { get }
} 