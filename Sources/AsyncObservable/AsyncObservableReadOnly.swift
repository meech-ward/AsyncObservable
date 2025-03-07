import Foundation
import Dispatch

/// A protocol representing the read-only interface of an `AsyncObservable`.
/// This allows for providing read-only access to an observable state without
/// exposing methods that can modify the state.
@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
public protocol AsyncObservableReadOnly<T>: Sendable {
    /// The type of value being observed.
    associatedtype T: Sendable

    /// The observable state object for SwiftUI/UIKit integration.
    /// This property is accessed on the MainActor to ensure thread-safe UI updates.
    @MainActor
    var observable: AsyncObservable<T>.State { get }

    /// The current value accessible from the MainActor.
    /// This is a convenience property that provides direct access to the observable value.
    @MainActor
    var valueObservable: T { get }

    /// An async stream of values that can be used with Swift concurrency.
    /// This property provides a convenient way to access the value stream.
    var valueStream: StreamOf<T> { get }

    /// The current value managed by this instance.
    var value: T { get }
} 