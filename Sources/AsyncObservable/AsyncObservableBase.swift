import Dispatch
import Foundation

#if canImport(Observation)
  import Observation
#endif

/// A thread-safe state management system that provides both async stream-based observation
/// and SwiftUI/UIKit compatible state observation through the Swift observation framework.
///
/// `AsyncObservable` combines actor isolation for thread safety with MainActor-bound observable
/// state for UI updates. It allows multiple observation patterns:
/// - Async stream subscription for value updates
/// - Direct observable state binding for SwiftUI/UIKit
/// - Value mutation with callbacks
///
/// Example usage:
/// ```swift
/// // Create a manager
/// let manager = AsyncObservable(0)
///
/// // Observe via async stream
/// for await value in await manager.stream() {
///     print("New value:", value)
/// }
///
/// // Bind to SwiftUI
/// struct ContentView: View {
///     var manager: AsyncObservable<Int>
///
///     var body: some View {
///         Text("\(manager.observable.value)")
///     }
/// }
///
/// // Update value directly
/// await manager.update(42)
///
/// // Update with transform
/// await manager.update { currentValue in
///     return currentValue + 1
/// }
///
/// // Mutate in place
/// await manager.mutate { value in
///     value += 1
/// }
/// ```
@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
open class AsyncObservableBase<T: Sendable>: @unchecked Sendable {
  /// An Observable class that wraps the managed value for SwiftUI/UIKit integration.
  /// This class is bound to the MainActor to ensure all UI updates happen on the main thread.
  @Observable
  @MainActor
  public class State {
    /// The current value, only settable internally but observable externally
    public var value: T {
      didSet {
        didSetValue(value)
      }
    }

    private var didSetValue: (T) -> Void

    init(value: T, didSetValue: @escaping (T) -> Void) {
      self.value = value
      self.didSetValue = didSetValue
    }
  }

  /// The observable state object for SwiftUI/UIKit integration.
  /// This property is accessed on the MainActor to ensure thread-safe UI updates.
  @MainActor
  public lazy var observableState: State = {
    let observableState = State(value: raw, didSetValue: didUpdateFromObservable)
    return observableState
  }()

  /// The current value accessible from the MainActor.
  /// This is a convenience property that provides direct access to the observable value.
  @MainActor
  public var observable: T {
    observableState.value
  }

  /// Storage for active stream continuations, keyed by UUID to allow multiple observers
  internal let continuationsQueue = DispatchQueue(label: "AsyncObservableContinuations")

  /// The current value managed by this instance.
  /// Updates to this value are automatically propagated to all observers.
  private var _raw: T
  public private(set) var raw: T {
    get {
      serialQueue.sync { _raw }
    }
    set {
      serialQueue.sync { _raw = newValue }
    }
  }
  public var current: T { raw }
  private var _shouldUpdateFromObservable = true
  private var _shouldUpdateObservable = true
  private var shouldUpdateFromObservable: Bool {
    get {
      serialQueue.sync { _shouldUpdateFromObservable }
    }
    set {
      serialQueue.sync { _shouldUpdateFromObservable = newValue }
    }
  }
  private var shouldUpdateObservable: Bool {
    get {
      serialQueue.sync { _shouldUpdateObservable }
    }
    set {
      serialQueue.sync { _shouldUpdateObservable = newValue }
    }
  }

  let serialQueue: DispatchQueue

  let bufferingPolicy: AsyncStream<T>.Continuation.BufferingPolicy

  /// Updates the observable value on the main thread.
  /// This method is called internally when the underlying value changes.
  ///
  /// - Parameter value: The new value to set in the observable state
  open func updateObservableValue(_ value: T) {
    if !shouldUpdateObservable {
      return
    }
    DispatchQueue.main.async {
      self.shouldUpdateFromObservable = false
      self.observableState.value = value
      self.shouldUpdateFromObservable = true
    }
  }

  @MainActor
  private func didUpdateFromObservable(_ value: T) {
    if shouldUpdateFromObservable {
      shouldUpdateObservable = false
      update(value)
      shouldUpdateObservable = true
    }
  }

  /// Creates a new state manager with the given initial value.
  /// This initializer can be called from any context
  ///
  /// - Parameters:
  ///   - initialValue: The initial value to manage
  ///   - bufferingPolicy: The buffering policy for async streams (default: .unbounded)
  ///   - serialQueue: The dispatch queue used for synchronization (default: new serial queue)
  public init(
    _ initialValue: T,
    bufferingPolicy: AsyncStream<T>.Continuation.BufferingPolicy = .unbounded,
    serialQueue: DispatchQueue = DispatchQueue(label: "AsyncObservable")
  ) {
    _raw = initialValue
    self.bufferingPolicy = bufferingPolicy
    self.serialQueue = serialQueue
  }

  private func updated(_ value: T, notifyObservers: Bool = true, updateObservable: Bool = true) {
    if notifyObservers {
      updateNotifiers(value)
    }
    if updateObservable {
      updateObservableValue(value)
    }
  }

  // to be overridden by subclasses
  open func updateNotifiers(_ value: T) {
    // do nothing by default
  }

  /// Updates the managed value and propagates the change to all observers.
  ///
  /// - Parameters:
  ///   - value: The new value to set
  ///   - notifyObservers: Whether to notify stream observers (default: true)
  ///   - updateObservable: Whether to update the observable state (default: true)
  public func update(_ value: T, notifyObservers: Bool = true, updateObservable: Bool = true) {
    self.raw = value
    updated(value, notifyObservers: notifyObservers, updateObservable: updateObservable)
  }

  /// Updates the managed value using a transform function and propagates the change to all observers.
  ///
  /// - Parameters:
  ///   - cb: A closure that takes the current value and returns a new value
  ///   - notifyObservers: Whether to notify stream observers (default: true)
  ///   - updateObservable: Whether to update the observable state (default: true)
  public func update(
    _ cb: @escaping (_ value: T) -> (T),
    notifyObservers: Bool = true,
    updateObservable: Bool = true
  ) {
    let newValue = cb(raw)
    update(newValue, notifyObservers: notifyObservers, updateObservable: updateObservable)
  }

  /// Mutates the managed value in place and propagates the change to all observers.
  ///
  /// - Parameters:
  ///   - cb: A closure that can modify the value in place
  ///   - notifyObservers: Whether to notify stream observers (default: true)
  ///   - updateObservable: Whether to update the observable state (default: true)
  public func mutate(
    _ cb: @escaping (_ value: inout T) -> Void,
    notifyObservers: Bool = true,
    updateObservable: Bool = true
  ) {
    serialQueue.sync {
      cb(&_raw)
    }
    updated(raw, notifyObservers: notifyObservers, updateObservable: updateObservable)
  }

}
