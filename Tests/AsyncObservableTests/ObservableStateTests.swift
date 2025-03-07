import Foundation
import Testing
@testable import AsyncObservable

@Suite("AsyncObservable State Tests")
struct AsyncObservableStateTests {
  
  @Test("Should update observable state")
  @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
  func testObservableStateUpdates() async {
    let observable = AsyncObservable(100)

    // Update the underlying value
    observable.update(200)

    // The observable state should be updated
    await #expect(observable.observableState.value == 200)
    await #expect(observable.observable == 200)
  }
  
  @Test("Should not update state when updateObservable is false")
  @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
  func testNoStateUpdate() async {
    let observable = AsyncObservable(100)
    _ = await observable.observable // make sure the lazy var has a value to test this

    // Update without updating observable state
    observable.update(200, updateObservable: false)

    // The internal value should be updated
    #expect(observable.raw == 200)
    
    // But the observable state should remain unchanged
    await #expect(observable.observableState.value == 100)
    await #expect(observable.observable == 100)
  }
  
  @Test("Should propagate observable changes to internal value")
  @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
  func testObservableToValueSync() async {
    let observable = AsyncObservable(100)

    // Update the observable value directly (this is done on the MainActor)
    await MainActor.run {
      observable.observableState.value = 300
    }
    
    // Allow time for the synchronization to happen
    try? await Task.sleep(for: .milliseconds(50))

    // The internal value should be updated to match
    #expect(observable.raw == 300)
  }
} 