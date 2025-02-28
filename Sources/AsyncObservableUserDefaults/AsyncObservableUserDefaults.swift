import AsyncObservable
import Foundation
/// A specialized version of AsyncObservable that persists its value to UserDefaults.
/// The managed value must conform to both Sendable and Codable protocols.
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
/// await manager.update(42)
///
/// // Remove the value from UserDefaults
/// manager.remove()
/// ```
@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
public class AsyncObservableUserDefaults<T: Sendable & Codable>: AsyncObservable<T>, @unchecked Sendable {
  public let userDefaults: UserDefaults
  public let key: String

  public init(
    key: String, initialValue: T, userDefaults: UserDefaults = .standard, serialQueue: DispatchQueue = DispatchSerialQueue(label: "AsyncObservable")
  ) {
    var _initialValue = initialValue
    self.userDefaults = userDefaults
    if let data = userDefaults.data(forKey: key), let value = try? JSONDecoder().decode(T.self, from: data) {
      _initialValue = value
    }

    self.key = key
    super.init(_initialValue, serialQueue: serialQueue)
  }

  /// Task that synchronizes the observable state with the current value
  private var updateStateTask: Task<Void, Never>?

  /// Sets up the task that keeps the observable state in sync with the current value
  override open func updateObservableValue(_ value: T) {
    super.updateObservableValue(value)
    save(value, forKey: key)
  }

  /// Removes the stored value from UserDefaults.
  /// This does not affect the current in-memory value.
  func remove() {
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
