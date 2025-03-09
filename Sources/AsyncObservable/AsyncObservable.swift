import Foundation

/// A concrete implementation of `AsyncObservableBase` that provides observable state with
/// async stream support for any `Sendable` type.
///
/// `AsyncObservable` manages a value of type `T` and notifies all observers when the value changes.
/// It supports both traditional Swift observation through the `Observable` macro and
/// async stream-based observation for integration with Swift concurrency.
///
/// Example usage:
/// ```swift
/// // Create an observable with initial value
/// let counter = AsyncObservable(0)
///
/// // Observe via async stream
/// Task {
///     for await value in counter.stream {
///         print("Counter changed to: \(value)")
///     }
/// }
///
/// // Update the value
/// counter.update(42)
/// ```
@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
open class AsyncObservable<T: Sendable>: AsyncObservableBase<T>, AsyncObservableReadOnly, @unchecked
  Sendable
{
  private var continuations: [UUID: AsyncStream<T>.Continuation] = [:]

  /// Updates all registered continuations with the new value.
  /// This method is called internally when the underlying value changes.
  ///
  /// - Parameter value: The new value to send to all observers
  override internal func updateNotifiers(_ value: T) {
    continuationsQueue.sync {
      for (_, continuation) in self.continuations {
        continuation.yield(value)
      }
    }
  }

  /// Internal helper to manage stream continuations
  ///
  /// - Parameters:
  ///   - id: The unique identifier for the continuation
  ///   - continuation: The continuation to store or nil to remove an existing one
  private func setContinuation(id: UUID, continuation: AsyncStream<T>.Continuation?) {
    continuationsQueue.sync {
      if let continuation {
        self.continuations[id] = continuation
      }
      else {
        self.continuations.removeValue(forKey: id)
      }
    }
  }

  /// Creates an AsyncStream that will receive all value updates.
  /// The stream immediately yields the current value and then yields all subsequent updates.
  ///
  /// - Returns: A StreamOf<T> instance that can be used with async/await code
  internal func streamOf() -> StreamOf<T> {
    let id = UUID()
    return StreamOf<T>(
      bufferingPolicy: bufferingPolicy,
      onTermination: { [weak self] in
        guard let self else { return }
        self.setContinuation(id: id, continuation: nil)
      },
      builder: { [weak self] continuation in
        guard let self else { return }
        self.setContinuation(id: id, continuation: continuation)
        continuation.yield(self.raw)
      }
    )
  }
  
  /// An async stream of values that can be used with Swift concurrency.
  /// This property provides a convenient way to access the value stream
  /// for observing all changes to the managed value.
  ///
  /// Example:
  /// ```swift
  /// Task {
  ///     for await value in observable.stream {
  ///         print("Value updated to: \(value)")
  ///     }
  /// }
  /// ```
  open var stream: StreamOf<T> {
    streamOf()
  }
}