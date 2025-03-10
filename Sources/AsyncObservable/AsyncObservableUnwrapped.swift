import Foundation

/// A specialized version of the `AsyncObservable` class that manages an optional value
/// but provides a stream of non-optional values.
///
/// `AsyncObservableUnwrapped` is designed for scenarios where you need to work
/// with an optional state but only want to observe non-nil values through the stream .
/// The stream will only emit values when the underlying optional contains a value.
///
/// Example usage:
/// ```swift
/// // Create an observable with initial value
/// let nameObservable = AsyncObservableUnwrapped<String>(nil)
///
/// // Only non-nil values will be emitted to this stream
/// Task {
///     for await name in nameObservable.stream {
///         // This will only execute when name is non-nil
///         print("Name updated to: \(name)")
///     }
/// }
///
/// // Update with a value
/// nameObservable.update("John")  // Stream will emit "John"
///
/// // Update with nil
/// nameObservable.update(nil)     // Stream will not emit, but the current and observable will be updated
/// ```
@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
open class AsyncObservableUnwrapped<T: Sendable>: AsyncObservableBase<T?>, AsyncObservableUnwrappedStreamReadOnly, @unchecked Sendable {

  private var unwrappedContinuations: [UUID: AsyncStream<T>.Continuation] = [:]

  /// Updates all registered continuations with the new value, but only if the value is non-nil.
  /// This method is called internally when the underlying value changes.
  ///
  /// - Parameter value: The new optional value. Continuations are only updated if non-nil.
  override open func updateNotifiers(_ value: T?) {
    if let value {
      continuationsQueue.sync {
        var terminations: [UUID] = []

        for (id, continuation) in self.unwrappedContinuations {
          let result = continuation.yield(value)
          if case .terminated = result {
            terminations.append(id)
          }
        }
        for id in terminations {
          self.unwrappedContinuations.removeValue(forKey: id)
        }
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
        self.unwrappedContinuations[id] = continuation
      }
      else {
        self.unwrappedContinuations.removeValue(forKey: id)
      }
    }
  }

  /// Creates an AsyncStream that will receive all non-nil value updates.
  /// The stream immediately yields the current value if non-nil and then yields all
  /// subsequent non-nil updates.
  ///
  /// - Returns: A StreamOf<T> instance that can be used with async/await code
  public func streamOf() -> StreamOf<T> {
    let id = UUID()
    let bufferingPolicy: AsyncStream<T>.Continuation.BufferingPolicy =
      switch self.bufferingPolicy {
      case .unbounded: .unbounded
      case .bufferingNewest(let count): .bufferingNewest(count)
      case .bufferingOldest(let count): .bufferingOldest(count)
      default: .unbounded
      }
    return StreamOf<T>(
      bufferingPolicy: bufferingPolicy,
      onTermination: { [weak self] in
        guard let self else { return }
        self.setContinuation(id: id, continuation: nil)
      },
      builder: { [weak self] continuation in
        guard let self else { return }
        self.setContinuation(id: id, continuation: continuation)
        if let raw = self.raw {
          continuation.yield(raw)
        }
      }
    )
  }

  /// An async stream of non-nil values that can be used with Swift concurrency.
  /// This property provides a convenient way to observe only the non-nil values
  /// of the underlying optional state.
  ///
  /// Example:
  /// ```swift
  /// Task {
  ///     for await value in unwrappedObservable.stream {
  ///         // This will only execute for non-nil values
  ///         print("Received non-nil value: \(value)")
  ///     }
  /// }
  /// ```
  open var stream: StreamOf<T> {
    streamOf()
  }
}
