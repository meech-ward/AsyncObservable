import AsyncObservable
import Foundation

/// A specialized version of AsyncObservable that persists its value to UserDefaults.
/// The managed value must conform to both Sendable and Codable protocols.
///
/// This class automatically:
/// - Loads the initial value from UserDefaults if available
/// - Persists value changes to UserDefaults
/// - Maintains all the async stream and observable functionality of AsyncObservable
///
/// Example usage:
/// ```swift
/// // Create a persistent manager
/// let manager = AsyncObservableUserDefaults(
///     key: "stored_counter",
///     initialValue: 0
/// )
///
/// // Value will be automatically saved to UserDefaults on updates
/// manager.update(42)
///
/// // Remove the value from UserDefaults
/// manager.remove()
/// ```
@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
public class AsyncObservableUserDefaults<T: Sendable & Codable>: AsyncObservable<T>, @unchecked Sendable {
  /// The UserDefaults instance used for persistence
  public let userDefaults: UserDefaults

  /// The key used to store the value in UserDefaults
  public let key: String

  /// Creates a new AsyncObservableUserDefaults instance.
  ///
  /// - Parameters:
  ///   - key: The key to use for storing the value in UserDefaults
  ///   - initialValue: The initial value to use if no value is found in UserDefaults
  ///   - userDefaults: The UserDefaults instance to use (default: .standard)
  ///   - serialQueue: The dispatch queue used for synchronization (default: new serial queue)
  ///   - saveImmediately: If true, the initial value will be saved to UserDefaults immediately (default: false)
  public init(
    key: String,
    initialValue: T,
    userDefaults: UserDefaults = .standard,
    serialQueue: DispatchQueue = DispatchQueue(label: "AsyncObservable"),
    saveImmediately: Bool = false
  ) {
    var _initialValue = initialValue
    self.userDefaults = userDefaults
    let data = userDefaults.data(forKey: key)
    if let data, let value = try? JSONDecoder().decode(T.self, from: data) {
      _initialValue = value
    }

    self.key = key
    super.init(_initialValue, serialQueue: serialQueue)
    if saveImmediately && data == nil {
      save(initialValue, forKey: key)
    }
  }

  /// Updates the observable value and persists the change to UserDefaults.
  ///
  /// - Parameter value: The new value to set in the observable state and persist
  override open func updateNotifiers(_ value: T) {
    super.updateNotifiers(value)
    save(value, forKey: key)
  }

  /// Removes the stored value from UserDefaults.
  /// This does not affect the current in-memory value.
  public func remove() {
    userDefaults.removeObject(forKey: key)
  }

  /// Saves the given object to UserDefaults using JSON encoding.
  ///
  /// - Parameters:
  ///   - object: The object to save
  ///   - key: The key to store the object under
  private func save(_ object: T, forKey key: String) {
    if let encoded = try? JSONEncoder().encode(object) {
      userDefaults.set(encoded, forKey: key)
    }
  }

  /// Retrieves and decodes an object from UserDefaults.
  ///
  /// - Parameters:
  ///   - type: The type of object to decode
  ///   - key: The key the object was stored under
  /// - Returns: The decoded object, or nil if not found or decoding fails
  private func retrieve(_ type: T.Type, forKey key: String) -> T? {
    guard let data = userDefaults.data(forKey: key) else {
      return nil
    }

    return try? JSONDecoder().decode(type, from: data)
  }
}
