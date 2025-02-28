import Foundation

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
/// let manager = await AsyncObservable(0)
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
open class AsyncObservable<T: Sendable>: @unchecked Sendable {
  /// An Observable class that wraps the managed value for SwiftUI/UIKit integration.
  /// This class is bound to the MainActor to ensure all UI updates happen on the main thread.
  @Observable
  @MainActor
  public class State {
    /// The current value, only settable internally but observable externally
    public internal(set) var value: T {
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
  public var observable: State!

  @MainActor
  public var valueObservable: T {
    observable.value
  }

  public var valueStream: StreamOf<T> {
    stream()
  }

  /// Storage for active stream continuations, keyed by UUID to allow multiple observers
  private let continuationsQueue = DispatchSerialQueue(label: "AsyncObservableContinuations")
  private var continuations: [UUID: AsyncStream<T>.Continuation] = [:]

  /// The current value managed by this instance.
  /// Updates to this value are automatically propagated to all observers.
  private var _value: T
  public private(set) var value: T {
    get {
      serialQueue.sync { _value }
    }
    set {
      serialQueue.sync { _value = newValue }
    }
  }
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

  open func updateObservableValue(_ value: T) {
    if !shouldUpdateObservable {
      return
    }
    DispatchQueue.main.async {
      self.shouldUpdateFromObservable = false
      self.observable.value = value
      self.shouldUpdateFromObservable = true
    }
  }

  @MainActor
  private func didUpdateFromObservable(_ value: T) {
    if shouldUpdateFromObservable {
      shouldUpdateObservable = false
      // print("calling didUpdateFromObservable \(value) \(self.continuations.count)")
      update(value)
      shouldUpdateObservable = true
    }
  }

  /// Creates a new state manager with the given initial value.
  /// This initializer can be called from any context and will properly set up
  /// the MainActor-bound observable state.
  ///
  /// - Parameter initialValue: The initial value to manage
  public init(
    _ initialValue: T,
    bufferingPolicy: AsyncStream<T>.Continuation.BufferingPolicy = .unbounded,
    serialQueue: DispatchQueue = DispatchSerialQueue(label: "AsyncObservable")
  )
    async
  {
    _value = initialValue
    self.bufferingPolicy = bufferingPolicy
    self.serialQueue = serialQueue
    await MainActor.run {
      observable = .init(value: initialValue, didSetValue: didUpdateFromObservable)
    }
  }

  /// Creates a new state manager with the given initial value when already on the MainActor.
  /// This convenience initializer avoids the need for async/await when initializing from UI code.
  ///
  /// - Parameter initialValue: The initial value to manage
  @MainActor
  public init(
    _ initialValue: T,
    bufferingPolicy: AsyncStream<T>.Continuation.BufferingPolicy = .unbounded,
    serialQueue: DispatchQueue = DispatchSerialQueue(label: "AsyncObservable")
  ) {
    _value = initialValue
    self.bufferingPolicy = bufferingPolicy
    self.serialQueue = serialQueue
    observable = .init(value: initialValue, didSetValue: didUpdateFromObservable)
  }

  private func updated(_ value: T, notifyObservers: Bool = true, updateObservable: Bool = true) {
    if notifyObservers {
      // print("notifying observers \(value) \(self.continuations.count)")
      continuationsQueue.sync {
        for (id, continuation) in self.continuations {
          // print("yielding value", value, "to continuation", id)

          continuation.yield(value)
        }
      }
    }
    if updateObservable {
      updateObservableValue(value)
    }
  }

  /// Updates the managed value and propagates the change to all observers.
  ///
  /// - Parameter value: The new value to set
  public func update(_ value: T, notifyObservers: Bool = true, updateObservable: Bool = true) {
    self.value = value
    // print("calling updated from update \(value) \(self.continuations.count)")
    updated(value, notifyObservers: notifyObservers, updateObservable: updateObservable)
  }

  /// Updates the managed value using a transform function and propagates the change to all observers.
  ///
  /// - Parameter cb: A closure that takes the current value and returns a new value
  public func update(
    _ cb: @escaping (_ value: T) -> (T), notifyObservers: Bool = true, updateObservable: Bool = true
  ) {
    let newValue = cb(value)
    // print("calling update from update \(newValue) \(self.continuations.count)")
    update(newValue, notifyObservers: notifyObservers, updateObservable: updateObservable)
  }

  /// Mutates the managed value in place and propagates the change to all observers.
  ///
  /// - Parameter cb: A closure that can modify the value in place
  public func mutate(
    _ cb: @escaping (_ value: inout T) -> Void, notifyObservers: Bool = true,
    updateObservable: Bool = true
  ) {
    serialQueue.sync {
      cb(&_value)
    }
    // print("calling updated from mutate")
    updated(value, notifyObservers: notifyObservers, updateObservable: updateObservable)
  }

  /// Internal helper to manage stream continuations
  private func setContinuation(id: UUID, continuation: AsyncStream<T>.Continuation?) {
    continuationsQueue.sync {
      if let continuation {
        self.continuations[id] = continuation
      } else {
        self.continuations.removeValue(forKey: id)
      }
    }
  }

  /// Creates an AsyncStream that will receive all value updates.
  /// The stream immediately yields the current value and then yields all subsequent updates.
  ///
  /// - Returns: An AsyncStream of values that can be used with async/await code
  private func stream() -> StreamOf<T> {
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
        continuation.yield(self.value)
      })
    // AsyncStream(bufferingPolicy: bufferingPolicy) { [weak self] continuation in
    // AsyncStream(bufferingPolicy: bufferingPolicy) { [weak self] continuation in
    //   guard let self = self else { return }

    //   let id = UUID()

    //   self.setContinuation(id: id, continuation: continuation)
    //   continuation.yield(self.value)

    //   continuation.onTermination

    //   continuation.onTermination = { @Sendable [weak self] _ in
    //     guard let self else { return }
    //     self.setContinuation(id: id, continuation: nil)
    //   }
    // }
  }
}
