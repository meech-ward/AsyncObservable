import Foundation
import Testing

@testable import AsyncObservableUserDefaults

@Suite("AsyncObservableUserDefaults Tests")
struct AsyncObservableUserDefaultsTests {

  let userDefaults = UserDefaults(suiteName: "testSuite")!

  @Test("Should persist values to UserDefaults when updated")
  @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
  func testPersistence() async {
    let testKey = "test_persistence_key"
    let initialValue = 42

    // Clear any existing value
    userDefaults.removeObject(forKey: testKey)

    // Create and update the observable
    let observable = await AsyncObservableUserDefaults(key: testKey, initialValue: initialValue, userDefaults: userDefaults)
    let newValue = 100
    observable.update(newValue)

    // Verify the value was saved to UserDefaults
    let data = userDefaults.data(forKey: testKey)
    #expect(data != nil, "Data should be saved to UserDefaults")

    if let data = data {
      let decodedValue = try? JSONDecoder().decode(Int.self, from: data)
      #expect(decodedValue == newValue, "The correct value should be persisted")
    }

    // Clean up
    observable.remove()
  }

  @Test("Should load persisted values during initialization")
  @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
  func testInitializationFromPersistedValue() async {
    let testKey = "test_init_key"
    let persistedValue = 99

    // First save a value directly to UserDefaults
    let encoder = JSONEncoder()
    if let encoded = try? encoder.encode(persistedValue) {
      userDefaults.set(encoded, forKey: testKey)
    }

    // Now initialize the observable with a different value
    let observable = await AsyncObservableUserDefaults(key: testKey, initialValue: 0, userDefaults: userDefaults)

    // It should use the persisted value, not the initial value
    #expect(observable.value == persistedValue, "Should load the persisted value")

    // Clean up
    observable.remove()
  }

  @Test("Should not store initial value unless changed")
  @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
  func testRemove() async {
    let testKey = "test_remove_key"

    // Create and set a value
    _ = await AsyncObservableUserDefaults(key: testKey, initialValue: 42, userDefaults: userDefaults)
    userDefaults.synchronize()
    // Verify it exists in UserDefaults
    #expect(userDefaults.data(forKey: testKey) == nil)
  }

  @Test("Should work with custom Codable types")
  @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
  func testCustomCodableTypes() async {
    // Define a custom Codable type
    struct Settings: Codable, Sendable, Equatable {
      var username: String
      var count: Int
      var isEnabled: Bool
    }

    let testKey = "test_custom_type_key"
    let initialSettings = Settings(username: "user", count: 0, isEnabled: false)

    // Create with initial value
    let observable = await AsyncObservableUserDefaults(key: testKey, initialValue: initialSettings, userDefaults: userDefaults)

    // Update with new value
    let newSettings = Settings(username: "newuser", count: 42, isEnabled: true)
    observable.update(newSettings)

    // Verify persistence
    let data = userDefaults.data(forKey: testKey)
    #expect(data != nil)

    if let data = data {
      let decoded = try? JSONDecoder().decode(Settings.self, from: data)
      #expect(decoded == newSettings)
    }

    // Clean up
    observable.remove()
  }
}
