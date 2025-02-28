import Foundation
import Testing
@testable import AsyncObservable

@Suite("AsyncObservable State Tests")
struct AsyncObservableStateTests {
  
  @Test("Should update observable state")
  @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
  func testObservableStateUpdates() async {
    let observable = await AsyncObservable(100)

    // Update the underlying value
    observable.update(200)

    // The observable state should be updated
    await #expect(observable.observable.value == 200)
    await #expect(observable.valueObservable == 200)
  }
  
  @Test("Should not update state when updateObservable is false")
  @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
  func testNoStateUpdate() async {
    let observable = await AsyncObservable(100)

    // Update without updating observable state
    observable.update(200, updateObservable: false)

    // The internal value should be updated
    #expect(observable.value == 200)
    
    // But the observable state should remain unchanged
    await #expect(observable.observable.value == 100)
    await #expect(observable.valueObservable == 100)
  }
  
  @Test("Should propagate observable changes to internal value")
  @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
  func testObservableToValueSync() async {
    let observable = await AsyncObservable(100)

    // Update the observable value directly (this is done on the MainActor)
    await MainActor.run {
      observable.observable.value = 300
    }
    
    // Allow time for the synchronization to happen
    try? await Task.sleep(for: .milliseconds(50))

    // The internal value should be updated to match
    #expect(observable.value == 300)
  }
} 